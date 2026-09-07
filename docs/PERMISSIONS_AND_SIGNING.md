# HarmonyOS 权限、签名与平台约束

## 1. 关键权限

通知订阅扩展需要：

```text
ohos.permission.SUBSCRIBE_NOTIFICATION
```

该权限属于 `system_basic` 级别，不应把它理解为普通 runtime permission。

## 2. 开发调试签名

华为当前自动签名文档中，`ohos.permission.SUBSCRIBE_NOTIFICATION` 已列入 DevEco Studio 自动签名支持的 ACL 权限；该项从 DevEco Studio 6.0.2 Beta1 起加入支持列表。

因此“自己的 App + 自己的测试手机”具备建立调试 POC 的现实路径，但仍要遵循 DevEco Studio / AGC 当前要求完成签名和 ACL 配置。

## 3. 用户侧授权

即使签名拥有权限，用户仍需在通知订阅设置 UI 中明确授权。

应用应调用：

```text
openSubscriptionSettingsWithResult(context)
```

让系统展示半模态授权页。

应用 UI 中应明确展示实际授权状态，而不是根据“调用没有报错”推断授权成功。

## 4. 平台场景约束

官方文档把该能力定位为“三方穿戴类应用”同步系统通知到配对穿戴设备。

这带来一个工程风险：

> API 技术上提供通知回调和蓝牙示例，不等于任何任意设备类别都一定能通过所有系统/上架审核约束。

本项目是个人设备工具，因此第一目标是**调试签名 + 自有真机的可运行性**，不是一开始就假设可上架 AppGallery。

## 5. API 版本

官方文档说明：

- `NotificationSubscriberExtensionAbility` 首批接口从 API 22 开始。
- Stage 模型。
- 官方场景文档要求 API 22+。
- 示例要求 DevEco Studio 6.0.2 Release+。

因此必须在设备上确认系统 API 版本，不要只看“系统名称写着 HarmonyOS 6”。

## 6. 隐私相关系统设置

即使回调工作，通知正文仍可能受以下因素影响：

- 锁屏隐藏通知内容
- 应用锁/隐私保护
- “信息”应用的通知显示策略
- 验证码安全保护
- 企业/MDM 策略

POC 要分别测试：

```text
屏幕解锁
屏幕锁定
锁屏显示完整内容
锁屏隐藏内容
```

不要只测试一个状态。

## 7. 发布策略

建议阶段：

### Stage A：个人 Debug Build

目标：证明能力链路。

### Stage B：个人 Release/内部签名

目标：验证长期日常使用稳定性。

### Stage C：公开发布评估

才开始确认：

- ACL 正式申请要求
- 应用类目
- 穿戴类场景审核要求
- 隐私政策
- 数据收集声明

不要在 POC 阶段承担 Stage C 成本。
