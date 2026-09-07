# HarmonyOS 端实现说明

## 1. 版本要求

建议开发环境：

- HarmonyOS 6.0.2 / API 22+
- DevEco Studio 6.0.2 Release+
- Stage 模型
- ArkTS

项目必须针对 API 22 能力编译；实际 `compatibleSdkVersion`、`targetSdkVersion` 以设备与 DevEco Studio 项目配置为准。

## 2. P0：先验证 NotificationInfo

第一阶段不要写 OTP 提取和蓝牙。

创建：

```text
entry/src/main/ets/extensionability/
└── NotificationSubscriberExtAbility.ets
```

核心逻辑：

```ts
import {
  notificationExtensionSubscription,
  NotificationSubscriberExtensionAbility
} from '@kit.NotificationKit';

const TAG = 'NotificationSubscriberExtAbility';

export default class NotificationSubscriberExtAbility
  extends NotificationSubscriberExtensionAbility {

  onReceiveMessage(
    notificationInfo: notificationExtensionSubscription.NotificationInfo
  ): void {
    console.info(`${TAG} onReceiveMessage: ${JSON.stringify(notificationInfo)}`);
  }

  onCancelMessages(hashCodes: Array<string>): void {
    console.info(`${TAG} onCancelMessages count=${hashCodes.length}`);
  }

  onDestroy(): void {
    console.info(`${TAG} onDestroy`);
  }
}
```

> 上述代码用于 POC 日志观察。真实验证码不要长期写入日志。验证成功后必须改为脱敏日志。

## 3. module.json5

需要配置 notification subscriber extension：

```json5
{
  "extensionAbilities": [
    {
      "name": "NotificationSubscriberExtAbility",
      "srcEntry": "./ets/extensionability/NotificationSubscriberExtAbility.ets",
      "type": "notificationSubscriber",
      "description": "$string:NotificationSubscriberExtAbility_desc",
      "icon": "$media:layered_image",
      "label": "$string:NotificationSubscriberExtAbility_label",
      "exported": true
    }
  ]
}
```

并在 `requestPermissions` 中声明：

```json5
{
  "name": "ohos.permission.SUBSCRIBE_NOTIFICATION"
}
```

具体生成后的模块结构以当前 DevEco Studio 模板为准。

## 4. 用户授权

不能只在 manifest 声明权限。还要显式拉起系统提供的通知订阅设置页面，引导用户授权。

推荐在首页提供按钮：

```text
[授权读取通知]
```

调用：

```ts
notificationExtensionSubscription.openSubscriptionSettingsWithResult(context)
```

并在 UI 中显示：

- 是否允许获取本机通知
- 已授权哪些应用通知
- 当前蓝牙目标设备
- 最近一次接收通知时间

不要通过后台偷偷尝试绕开用户授权。

## 5. NotificationInfo 适配层

不要在业务代码里直接到处读取 `NotificationInfo` 字段。

定义内部 DTO：

```ts
interface NormalizedNotification {
  sourceBundle?: string;
  title?: string;
  text?: string;
  extraTexts?: string[];
  hashCode?: string;
  timestampMs: number;
}
```

实现：

```text
NotificationInfo
     ↓
NotificationNormalizer
     ↓
NormalizedNotification
```

原因：系统结构字段可能复杂、不同通知模板表达不同，验证码提取算法不应该耦合系统对象。

P0 真机观察后，再确定哪些字段参与 `title/text/extraTexts`。

## 6. OTP Detector

不要直接使用：

```regex
\b\d{4,8}\b
```

这会误识别订单号、尾号、时间、金额等。

推荐两阶段：

### 6.1 文本预筛选

关键词：

```text
验证码
校验码
动态码
安全码
一次性密码
OTP
verification code
security code
one-time code
```

### 6.2 候选数字评分

候选：4-8 位连续数字。

提高分数：

- 距“验证码”关键词 < 10 个字符
- 前面出现“为”“是”“：”
- 文本包含“分钟内有效”

降低分数：

- 11 位手机号片段
- 18 位订单/证件上下文
- 金额上下文
- 日期/时间上下文

接口示例：

```ts
interface OtpResult {
  code: string;
  confidence: number;
}

function detectOtp(text: string): OtpResult | null;
```

阈值建议：

- `confidence >= 0.85`：自动发送 + Mac 自动复制
- `0.60 <= confidence < 0.85`：发送但 Mac 只通知，不自动复制
- `< 0.60`：丢弃

## 7. 蓝牙 SPP

MVP 使用传统蓝牙 RFCOMM/SPP。

官方示例使用的关键模式为：

```ts
{
  uuid: SERVICE_UUID,
  secure: false,
  type: socket.SppType.SPP_RFCOMM
}
```

随后：

```text
sppConnect(peer, options)
→ clientNumber
→ socket.on('sppRead', clientNumber, ...)
→ sppWrite(clientNumber, ArrayBuffer)
```

具体 API import、类型名称和错误码应以当前 API 22 SDK 自动补全为准，不要从旧版博客复制。

## 8. TransportManager

不要每来一条通知就新建蓝牙连接。

建议：

```ts
class TransportManager {
  private state: ConnectionState;
  private clientNumber?: number;
  private queue: Array<Uint8Array>;

  async ensureConnected(): Promise<boolean>;
  async send(payload: Uint8Array): Promise<void>;
  disconnect(): void;
}
```

重连策略：

```text
0.5s → 1s → 2s → 4s → 8s
```

最大连续重试 5 次。验证码是短生命周期数据，超过 60 秒后默认放弃重传。

## 9. 数据发送

MVP 数据：

```json
{"version":1,"type":"otp","id":"...","timestampMs":1788751234000,"code":"836291","sender":"Tencent"}
```

编码：UTF-8。

帧：

```text
JSON + "\n"
```

不要发送完整短信正文，除非 debug 模式下用户显式打开。

## 10. 后台与生命周期

通知订阅 Extension 会被系统管理生命周期。代码必须：

- 不依赖常驻内存缓存作为唯一状态。
- 不在 callback 中进行长时间阻塞。
- 所有发送都有限时。
- 蓝牙异常时允许当前消息失败，而不是卡死 Extension。

## 11. 首版页面

最小 UI：

```text
Harmony OTP Bridge

通知权限      已授权 / 未授权
蓝牙          已开启 / 未开启
目标 Mac      MacBook Air / 未绑定
连接状态      已连接 / 已断开

[授权通知]
[选择/绑定 Mac]
[发送测试消息]

最近状态
12:30:01 收到通知
12:30:01 识别 OTP ******
12:30:02 已发送
```

日志中 OTP 始终脱敏：`******`。

## 12. P0 验收

### Notification Gate

- 系统能展示授权页面。
- 用户能完成授权。
- `onReceiveMessage` 对普通 App 通知有回调。
- 对“信息”通知有回调。
- 验证码正文可从回调结构中恢复。

若最后一项失败，立即停止主路线，转入替代方案评估，不继续做完整 UI。
