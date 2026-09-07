# Harmony Mac OTP Bridge

Phase 0.1 是一个只验证 HarmonyOS 通知订阅链路的最小工程：

- API 22 / Stage 模型
- 申请 `ohos.permission.SUBSCRIBE_NOTIFICATION`
- 从首页打开通知订阅授权页面
- 在 `NotificationSubscriberExtensionAbility.onReceiveMessage()` 中输出完整 `NotificationInfo`

## 运行前提

- DevEco Studio 6.0.2 Release 或更高版本
- 已安装 HarmonyOS 6.0.2(22) SDK
- Phone 或 Tablet 设备/模拟器

打开工程后，让 DevEco Studio 处理自动签名，然后运行 `entry` 模块。

## Phase 0.1 验收

1. 启动应用。
2. 点击“打开通知订阅授权”，在系统半模态页面打开“允许获取本机通知”和需要观察的应用开关。
3. 返回应用，点击“检查授权状态”，页面显示授权状态为“已授权”。
4. 本阶段的代码 Gate 是构建日志中的 `CompileArkTS` 和 `assembleApp` 成功，并确认扩展已注册。`onReceiveMessage` 的真实通知回调需要下一阶段用真实蓝牙地址调用 `subscribe()` 后才能触发。

## 有意不包含的内容

API 22 的 `notificationExtensionSubscription.subscribe()` 需要真实蓝牙设备地址；因此本阶段不伪造地址、不加入蓝牙权限和 Mac 通信。拿到授权与回调输出后，再进入下一阶段接入蓝牙订阅。
