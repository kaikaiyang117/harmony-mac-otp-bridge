# 架构设计

## 1. 目标

本项目解决一个明确问题：HarmonyOS 6 手机收到验证码短信后，让 macOS 能快速看到并复制验证码。

设计目标：

- 本地优先，不依赖公网。
- 低延迟，目标端到端 P95 < 2 秒。
- 最小权限。
- 尽量使用公开、正式系统 API。
- 能明确区分“系统能力不允许”与“业务代码 Bug”。

## 2. 核心架构

```text
┌─────────────────────────────────────────────┐
│ HarmonyOS Phone                             │
│                                             │
│  Huawei Messages / other app               │
│            │ publish notification          │
│            ▼                               │
│  Notification Service                      │
│            │                               │
│            ▼                               │
│  NotificationSubscriberExtensionAbility    │
│            │                               │
│            ├─ SourceFilter                  │
│            ├─ OtpDetector                   │
│            ├─ Deduplicator                  │
│            ▼                               │
│  TransportManager                          │
│            │                               │
│       SPP / RFCOMM                          │
└────────────┼────────────────────────────────┘
             │ Bluetooth Classic
             ▼
┌─────────────────────────────────────────────┐
│ macOS                                       │
│                                             │
│  RFCOMMService                              │
│        │                                    │
│        ▼                                    │
│  FrameDecoder → MessageValidator            │
│        │                                    │
│        ├─ NotificationPresenter             │
│        ├─ ClipboardService                  │
│        └─ RecentOtpStore (memory only)      │
│                                             │
│  Menu Bar UI                                │
└─────────────────────────────────────────────┘
```

## 3. 为什么选择 Notification Subscriber

### 3.1 不直接读取短信

直接读取短信会引入更高权限、隐私及平台兼容风险。验证码实际需要的是“用户能在通知上看到的文本”，因此通知层是更窄且更符合最小权限原则的入口。

### 3.2 HarmonyOS API 22+ 的能力

官方 `NotificationSubscriberExtensionAbility` 从 API 22 开始提供，在系统发布通知时通过 `onReceiveMessage` 回调通知订阅扩展。官方场景是三方穿戴类应用把本机通知同步到配对设备，并明确支持 BLE 与传统蓝牙。

这说明“系统通知 → 三方扩展 → 蓝牙”是一条官方存在的能力链路。

### 3.3 风险边界

官方文档的目标场景是“穿戴设备”。Mac 并不是文档中明确列出的典型目标，因此工程上必须把“Mac 是否能作为实际配对/订阅目标”列为真机验证项，而不能仅凭 API 名称假设一定通过所有系统检查。

## 4. 为什么 MVP 使用 SPP/RFCOMM

选择 Bluetooth Classic SPP/RFCOMM 的原因：

- 华为官方通知同步示例采用 `SPP_RFCOMM`。
- macOS `IOBluetooth` 提供 RFCOMM channel 和 SDP service record。
- 数据量极小，不需要 BLE 的功耗优势来换取更复杂的 GATT 服务设计。
- RFCOMM 天然接近字节流，协议实现成本低。

后续若经典蓝牙在 macOS 新版本上有兼容性问题，再评估 BLE GATT 作为替代 Transport。

## 5. 模块边界

### HarmonyOS

#### NotificationIngress

职责：

- 接收 `NotificationInfo`。
- 只做轻量解析。
- 不执行长耗时工作。

#### SourceFilter

职责：

- 根据 bundle/source/文本特征判断是否需要处理。
- 初期允许“所有通知仅打印结构”的 POC 模式。
- MVP 应默认只处理“信息”或用户白名单 App。

#### OtpDetector

输入：标准化的通知文本。

输出：

```ts
interface OtpCandidate {
  code: string;
  confidence: number;
  matchedKeyword?: string;
}
```

#### Deduplicator

避免同一验证码因通知更新、重复推送等多次发送。

推荐 key：

```text
hash(sourceBundle + normalizedText + code)
```

短期 TTL：60 秒。

#### TransportManager

状态机：

```text
DISCONNECTED
  ↓ connect
CONNECTING
  ↓ success
CONNECTED
  ↓ error/timeout
DISCONNECTED
```

具备：

- 单连接复用
- 发送队列
- 指数退避
- 超时
- 错误统计

### macOS

#### RFCOMMService

职责：

- 发布 SDP service。
- 接受 incoming RFCOMM channel。
- 管理 channel delegate。
- 将原始 bytes 交给 FrameDecoder。

#### FrameDecoder

MVP 使用 JSON Lines，因此按 `\n` 分帧。

必须正确处理：

- 半包
- 粘包
- 非 UTF-8
- 单帧过大

#### MessageValidator

校验：

- version
- type
- UUID
- timestamp
- code 格式
- 过期时间

#### ClipboardService

收到高置信度 OTP 时：

```swift
NSPasteboard.general.clearContents()
NSPasteboard.general.setString(code, forType: .string)
```

自动复制必须有开关。

#### NotificationPresenter

使用 UserNotifications 展示：

```text
Huawei OTP
836291
已复制到剪贴板
```

## 6. Extension 生命周期

官方说明：如果一定时间内没有新通知，`NotificationSubscriberExtensionAbility` 可能由系统自动销毁。

因此不能把蓝牙连接的存在与 Extension 永久绑定为一个不可恢复的假设。

实现策略：

1. 每次收到消息检查连接状态。
2. 连接可复用则直接发送。
3. 连接失效则重连。
4. 不高频重复建立连接。
5. 发送失败进入有限重试队列。

## 7. 消息流

```text
SMS arrives
  ↓
Messages notification
  ↓
onReceiveMessage(NotificationInfo)
  ↓
Normalize notification content
  ↓
SourceFilter
  ↓
OtpDetector
  ↓ no candidate → drop
  ↓ candidate
Deduplicator
  ↓ duplicate → drop
  ↓ new
Build OtpMessage
  ↓
TransportManager.send()
  ↓
RFCOMM
  ↓
FrameDecoder
  ↓
MessageValidator
  ↓
Clipboard + Notification
```

## 8. 错误策略

系统能力错误与业务错误必须分开统计：

- AUTH_DENIED
- SUBSCRIPTION_UNAVAILABLE
- CONTENT_REDACTED
- BLUETOOTH_OFF
- PEER_NOT_PAIRED
- RFCOMM_CONNECT_FAILED
- RFCOMM_WRITE_FAILED
- PROTOCOL_INVALID
- OTP_NOT_FOUND

## 9. 非目标

MVP 不做：

- 云端账号体系
- 跨公网同步
- 多用户
- Android/iOS 客户端
- 全量短信同步
- 长期验证码历史
- 自动填写浏览器输入框

这些都不是验证主链路所必须。
