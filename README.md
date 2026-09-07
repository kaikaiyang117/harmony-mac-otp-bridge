# Harmony Mac OTP Bridge

将 HarmonyOS 6 手机收到的验证码通知，在手机本地提取验证码后通过自建 Bark Server 转发到 macOS BarkMac。

> 当前状态：**Phase 0.3 / PASS**。前台、后台和锁屏真实短信均已完成 OTP 提取并推送到 BarkMac。

## 目标体验

```text
HarmonyOS 6 手机收到验证码通知
        ↓
NotificationSubscriberExtensionAbility
        ↓
NotificationExtractor
        ↓
OtpParser
        ↓
HTTP POST /push
        ↓
Bark Server（自建）
        ↓
BarkMac
        ↓
macOS 系统通知
```

## 为什么不直接读取短信

本项目不把“读取短信数据库”作为主路线。HarmonyOS 6 对短信等敏感数据访问限制较强，而 API 22+ 提供了通知订阅扩展能力：应用在获得授权后读取本机通知，再在手机本地提取验证码。

因此主路线是：**读取系统通知，而不是读取短信数据库；通过 HTTP 推送，而不是用蓝牙传输 OTP。**

## 技术栈

- HarmonyOS 端：ArkTS、Stage 模型、Notification Kit、Connectivity Kit、NetworkKit、Preferences
- macOS 端：现成的 `htnanako/bark-macOS` BarkMac
- 服务端：自建 `htnanako/bark-server`
- 传输：HTTP JSON `POST /push`；BarkMac 使用 `macos_sse`

## 核心前置条件

1. 手机系统能力达到 HarmonyOS 6.0.2 / API 22 或更高。
2. DevEco Studio 使用 6.0.2 Release 或更高版本。
3. HarmonyOS 应用能获得 `ohos.permission.SUBSCRIBE_NOTIFICATION`。
4. 用户在系统弹窗中授权“允许获取本机通知”。
5. 「信息」应用通知回调中能看到验证码正文，而不是被隐私策略完全脱敏。
6. 手机与 Bark Server 位于可互通的局域网。
7. Mac 上 BarkMac 已注册并连接自建 Bark Server。

## Phase 0.3 Gate 顺序

1. Bark Server `/ping`
2. BarkMac 注册与 SSE 连接
3. `curl /push` → BarkMac
4. HarmonyOS “发送 Bark 测试通知” → BarkMac
5. 真实通知回调字段验证
6. OTP Parser 单元测试
7. 真实短信 → OTP → Bark → BarkMac

只有最后一项完成，Phase 0.3 才能标记 PASS。

## 仓库结构

```text
.
├── README.md
├── AGENTS.md
├── docs/
│   ├── ARCHITECTURE.md
│   ├── HARMONYOS_IMPLEMENTATION.md
│   ├── MACOS_IMPLEMENTATION.md
│   ├── PROTOCOL.md
│   ├── PERMISSIONS_AND_SIGNING.md
│   ├── TEST_PLAN.md
│   ├── ROADMAP.md
│   ├── BARK_SETUP.md
│   ├── PHASE_0_3_RESULT.md
│   ├── CURRENT_LIMITATIONS.md
│   └── SOURCE_RESEARCH.md
├── harmony-app/
│   └── README.md
├── macos-app/
│   └── README.md
└── shared/
    └── otp-message.schema.json
```

## 安全原则

- 默认只在本地处理验证码。
- 不把完整短信内容发送到云端。
- 只向自建 Bark Server 发送来源和提取后的 OTP，不发送完整短信正文。
- Preferences 只保存 Server URL、Device Key 和启用开关，不保存 OTP。
- 已移除完整 `NotificationInfo`、短信正文和 Device Key 日志；通知标题与蓝牙元数据仍需进一步脱敏，详见 `docs/CURRENT_LIMITATIONS.md`。
- HTTP 明文只适合可信局域网；不应在不可信公共 Wi-Fi 长期使用。
- 后续版本应增加设备绑定、消息签名和重放保护。

## 开发文档

建议阅读顺序：

1. `docs/ARCHITECTURE.md`
2. `docs/PERMISSIONS_AND_SIGNING.md`
3. `docs/HARMONYOS_IMPLEMENTATION.md`
4. `docs/BARK_SETUP.md`
5. `docs/TEST_PLAN.md`
6. `docs/PHASE_0_3_RESULT.md`
7. `docs/CURRENT_LIMITATIONS.md`
8. `docs/ROADMAP.md`

## 当前结论

Phase 0.2 已在 HUAWEI Mate 60 Pro 真机完成通知授权、蓝牙设备枚举、Mac 订阅和普通通知回调验证。Phase 0.3 已完成 Bark Server、BarkMac、HarmonyOS 测试推送，以及前台、后台和锁屏真实短信到 Mac 的端到端验证。

## Phase 0.3 当前实现

当前 HarmonyOS 工程包含：

- `ohos.permission.SUBSCRIBE_NOTIFICATION` 权限声明
- `ohos.permission.ACCESS_BLUETOOTH` 和 `ohos.permission.INTERNET`
- 通知订阅授权、蓝牙设备枚举和目标设备订阅
- `NotificationSubscriberExtensionAbility` 扩展注册
- 基于真实 API 22 字段的 `NotificationExtractor`
- 关键词优先、4–8 位数字的 `OtpParser`
- Preferences 配置和 `BarkPushService`
- 状态优先的首页、验证码转发开关和按需展开的 Bark 配置
- 合并后的“保存并测试”配置动作

蓝牙在本阶段只用于激活 HarmonyOS 通知订阅能力，不作为 OTP 数据通道。

## Native macOS receiver

`macos-app/` 保留为未来可选方案，当前状态为 **Deferred**。MVP 使用 `htnanako/bark-macOS`，只有在需要剪贴板集成、离线本地传输或 RFCOMM 时再评估自研 macOS receiver。
