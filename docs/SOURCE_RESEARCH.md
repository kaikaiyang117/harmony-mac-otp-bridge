# 官方资料与调研记录

更新时间：2026-09-07

本文件记录决定技术路线所依据的主要官方文档。实现时应再次以当前 SDK / 官方文档为准。

## Huawei HarmonyOS

### NotificationSubscriberExtensionAbility API

官方文档：

https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/api/js-apis-notificationsubscriberextensionability

确认内容：

- 从 API version 22 开始。
- Stage 模型。
- `onReceiveMessage(NotificationInfo)` 接收通知。
- 官方描述场景是三方穿戴类应用接收本机通知并通过蓝牙转发。

### 通知订阅扩展能力概述

https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/notification-subscriber-extension-ability

确认内容：

- 三方应用可以接收系统通知。
- 支持 BLE 与传统蓝牙两种同步方式。
- 示例要求 API 22+。
- 示例要求 DevEco Studio 6.0.2 Release+。
- 需要 `ohos.permission.SUBSCRIBE_NOTIFICATION`。
- 权限等级为 `system_basic`。
- 用户需通过 `openSubscriptionSettingsWithResult` 对通知访问进行授权。
- Extension 可能在一段时间无通知后被系统销毁。

### 通知订阅扩展能力开发步骤

https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/notification-subscriber-extension-ability-development-steps

确认内容：

- module.json5 中配置 `type: notificationSubscriber`。
- 官方示例展示使用蓝牙 SPP/RFCOMM 发送通知。
- 示例强调不要频繁建立连接。

### DevEco Studio 自动签名

https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/ide-signing-auto

确认内容：

- 自动签名支持 ACL 权限。
- `ohos.permission.SUBSCRIBE_NOTIFICATION` 从 DevEco Studio 6.0.2 Beta1 起进入支持列表。

### HarmonyOS 6.0.2(22) 版本概览

https://developer.huawei.com/consumer/en/doc/harmonyos-releases/overview-602

确认内容：

- HarmonyOS 6.0.2 对应 API 22 Release。
- API 22 Release 于 2026-01-21 发布。

## Apple macOS

### IOBluetoothRFCOMMChannel

https://developer.apple.com/documentation/iobluetooth/iobluetoothrfcommchannel

确认内容：

- 表示 RFCOMM channel。
- 可通过打开远端 channel 获得，也可注册 channel-created/open notification 来提供服务。
- 提供 delegate 与同步/异步写入相关 API。

### IOBluetoothSDPServiceRecord

https://developer.apple.com/documentation/iobluetooth/iobluetoothsdpservicerecord

确认内容：

- 表示 SDP service record。
- `publishedServiceRecord(with:)` 可向本地 SDP server 发布服务。
- 能查询 RFCOMM channel ID。

## 已确认 vs 待真机确认

### 已确认

- HarmonyOS API 22 有 Notification Subscriber Extension。
- 该能力能接收系统通知回调。
- 官方场景支持传统蓝牙与 BLE。
- 官方开发步骤有 SPP/RFCOMM 示例。
- macOS 有 RFCOMM + SDP public framework API。

### 待真机确认

- 用户具体 HarmonyOS 6 设备是否运行 API 22+。
- `SUBSCRIBE_NOTIFICATION` 调试签名是否能在用户账号/设备环境成功配置。
- “信息”应用的验证码通知正文是否完整出现在 `NotificationInfo`。
- 系统是否对非穿戴类 Mac 目标施加额外设备类别限制。
- 当前 macOS 版本上自定义 RFCOMM service 的发现/连接体验。

这些待确认项都已被放入 Phase 0 Gate，不能在验证前标记为已解决。
