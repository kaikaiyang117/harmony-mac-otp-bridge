# Harmony Mac OTP Bridge

将 HarmonyOS 6 手机收到的验证码通知，安全、低延迟地转发到 macOS，并自动提供复制/粘贴体验。

> 当前状态：**设计与 POC 阶段**。仓库首先验证 HarmonyOS 6 API 22+ 的通知订阅扩展能力能否稳定取得“信息”应用通知正文，再验证 Bluetooth Classic SPP/RFCOMM 到 macOS 的链路。只有这两个 P0 条件通过后，才进入完整产品实现。

## 目标体验

```text
HarmonyOS 6 手机收到验证码短信
        ↓
系统「信息」发布通知
        ↓
NotificationSubscriberExtensionAbility
        ↓
本地提取 OTP（不上传云端）
        ↓
Bluetooth Classic SPP / RFCOMM
        ↓
macOS 菜单栏 App
        ↓
系统通知 + 自动复制验证码
        ↓
⌘V
```

## 为什么不直接读取短信

本项目不把“读取短信数据库”作为主路线。HarmonyOS 6 对短信等敏感数据访问限制较强，而 API 22+ 提供了官方的通知订阅扩展能力：第三方配套应用可以在获得用户授权后接收本机通知，并通过 BLE 或传统蓝牙同步到另一设备。

因此主路线是：**读取系统通知，而不是读取短信数据库。**

## 技术栈

- HarmonyOS 端：ArkTS、Stage 模型、Notification Kit、Connectivity Kit / Bluetooth SPP
- macOS 端：Swift、AppKit / SwiftUI、IOBluetooth、UserNotifications、NSPasteboard
- 传输：Bluetooth Classic RFCOMM / SPP
- 协议：UTF-8 JSON Lines，后续可升级为长度前缀协议

## 核心前置条件

1. 手机系统能力达到 HarmonyOS 6.0.2 / API 22 或更高。
2. DevEco Studio 使用 6.0.2 Release 或更高版本。
3. HarmonyOS 应用能获得 `ohos.permission.SUBSCRIBE_NOTIFICATION`。
4. 用户在系统弹窗中授权“允许获取本机通知”。
5. 「信息」应用通知回调中能看到验证码正文，而不是被隐私策略完全脱敏。
6. Mac 与手机已完成蓝牙配对，并能建立 RFCOMM/SPP 链路。

## P0 验证顺序

不要先做完整 App。按以下顺序执行：

### P0-1：通知正文验证

HarmonyOS 端仅实现：

```ts
onReceiveMessage(info) {
  console.info(JSON.stringify(info));
}
```

给手机发送一条测试验证码短信，确认日志中出现验证码内容。

通过标准：能从 `NotificationInfo` 中稳定提取验证码正文。

### P0-2：蓝牙链路验证

macOS 建立 RFCOMM 服务端，HarmonyOS 建立 SPP 客户端，只发送：

```text
hello-from-harmony\n
```

通过标准：Mac 连续接收 100 次消息无断链、乱序或截断。

### P0-3：端到端验证

```text
短信通知 → OTP 提取 → SPP → Mac → 剪贴板
```

通过标准：手机收到验证码后，Mac 在 2 秒内出现通知并完成复制。

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
- 蓝牙包中优先只发送提取后的 OTP 与最少元数据。
- Mac 端验证码默认仅短期保留。
- 日志默认脱敏，不记录完整 OTP。
- 自动复制可关闭。
- 后续版本应增加设备绑定、消息签名和重放保护。

## 开发文档

建议阅读顺序：

1. `docs/ARCHITECTURE.md`
2. `docs/PERMISSIONS_AND_SIGNING.md`
3. `docs/HARMONYOS_IMPLEMENTATION.md`
4. `docs/MACOS_IMPLEMENTATION.md`
5. `docs/PROTOCOL.md`
6. `docs/TEST_PLAN.md`
7. `docs/ROADMAP.md`

## 当前结论

这条路线的传输部分有明确系统 API 支撑。当前最大的技术风险不是 Bluetooth，而是 HarmonyOS 的通知订阅 ACL、使用场景约束以及“信息”通知正文是否完整暴露给订阅扩展。因此本仓库把通知正文 POC 放在所有功能开发之前。

## Phase 0.1 当前实现

本阶段提供一个 API 22 / Stage 模型的最小 HarmonyOS 工程，包含：

- `ohos.permission.SUBSCRIBE_NOTIFICATION` 权限声明
- 通知订阅授权页跳转和授权状态检查
- `NotificationSubscriberExtensionAbility` 扩展注册
- `onReceiveMessage()` 中的完整 `NotificationInfo` 日志输出

运行前提：DevEco Studio 6.0.2 Release 或更高版本、HarmonyOS 6.0.2(22) SDK，以及 Phone 或 Tablet 真机/模拟器。

Phase 0.1 已在 HUAWEI Mate 60 Pro 真机验证：签名安装成功、应用启动成功、通知订阅授权成功，Hilog 输出 `Notification subscription granted: true`，扩展注册和 `SUBSCRIBE_NOTIFICATION` 权限均可在设备包信息中确认。

API 22 的 `notificationExtensionSubscription.subscribe()` 需要真实蓝牙设备地址，因此本阶段不伪造地址、不加入蓝牙权限和 Mac 通信。真实 `NotificationInfo` 回调验证将在下一阶段接入蓝牙订阅后进行。
