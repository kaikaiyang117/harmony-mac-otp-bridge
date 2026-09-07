# Phase 0.3 实验结果

## 结论

**Phase 0.3：PASS**

HarmonyOS 真机可从真实短信通知中提取验证码，通过自建 Bark Server 推送至 BarkMac。前台、后台和锁屏三种状态均完成端到端验证。

```text
短信通知
  → NotificationSubscriberExtensionAbility
  → NotificationExtractor
  → OtpParser
  → HTTP POST /push
  → bark-server
  → BarkMac
```

## 测试环境

| 项目 | 实际环境 |
| --- | --- |
| 手机 | HUAWEI Mate 60 Pro |
| HarmonyOS | `ALN-AL00 6.1.0.135(SP8C00E120R8P11)` |
| API | HarmonyOS API 22 |
| Mac 局域网地址 | `192.168.31.210`（测试时） |
| BarkMac | `v1.0.0`，`macos_sse` |
| Bark Server | `ghcr.io/htnanako/bark-server`，Docker，端口 `8080` |

Device Key 已生成并写入手机本地配置，但没有写入本文档或 Git。

## Gate 结果

| Gate | 验证内容 | 结果 | 证据 |
| --- | --- | --- | --- |
| A | Bark Server `/ping` | PASS | HTTP 200，响应 `pong` |
| B | BarkMac 注册与 SSE | PASS | 当前 Mac 注册成功，事件流显示已连接 |
| C | Server → BarkMac | PASS | `curl /push` 返回 HTTP 200，BarkMac 出现测试记录 |
| D | HarmonyOS → Server | PASS | 手机测试按钮触发 `[BARK_PUSH_SUCCESS]` |
| E | 真实通知字段 | PASS | 回调中确认 title、text、bundleName 字段路径 |
| F | OTP Parser | PASS | 11/11 独立用例通过 |
| G | 真实短信端到端 | PASS | 真机短信完成解析、推送并在 BarkMac 显示 |

## 真实通知字段

API 22 真机回调确认使用以下字段：

```text
NotificationInfo.content.title
NotificationInfo.content.text
NotificationInfo.bundleName
NotificationInfo.appName
```

实现中已移除完整 `NotificationInfo` 输出，只保留事件类型、来源和验证码长度等脱敏信息。

## OTP Parser

独立测试共 11 项，覆盖：

- 中文验证码、校验码、动态码关键词
- `OTP`、`verification code` 等英文关键词
- 4–8 位数字提取
- 关键词附近数字优先
- 标题与 `【来源】` 来源识别
- 多数字正文拒绝误判
- 订单号、快递号、时间等反例
- 60 秒内存去重

测试结果：**11/11 PASS**。

## 真实短信状态矩阵

| 手机状态 | 收到通知回调 | OTP 提取 | HTTP 2xx | BarkMac 记录 |
| --- | --- | --- | --- | --- |
| App 前台 | PASS | PASS | PASS | PASS |
| App 后台 | PASS | PASS | PASS | PASS |
| 手机锁屏 | PASS | PASS | PASS | PASS |

前台样本中，从通知回调到 HTTP 成功约 83 ms，BarkMac 在同一秒出现记录。后台样本同样完成完整链路。

首次锁屏尝试没有观察到应用回调，因此未直接判定通过。设备重新唤醒、解锁并再次锁屏后进行受控复测，观察到以下脱敏事件序列：

```text
[NOTIFICATION_RECEIVED]
[OTP_DETECTED] length=6
[BARK_PUSH_START]
[BARK_PUSH_SUCCESS]
```

BarkMac 在同一分钟新增对应 OTP 记录，锁屏场景最终判定为 PASS。本文档不记录任何真实验证码。

## 安全与数据边界

- 手机本地只提取并转发来源和 OTP，不转发完整短信正文。
- Preferences 只保存 Server URL、Device Key 和启用状态。
- 日志不记录完整通知、短信正文、OTP 或 Device Key。
- OTP 去重状态仅保存在内存中，窗口为 60 秒。
- 当前 HTTP 方案仅适合可信局域网。

## 界面收敛

Phase 0.3 验证完成后，手机端首页收敛为状态优先的日常界面：

- 首页直接显示总状态和验证码转发开关。
- 通知权限、设备订阅和 BarkMac 配置自动检查。
- 设备列表仅在尚未订阅时显示。
- Bark 配置完成后自动折叠，Device Key 始终掩码显示。
- “保存配置”和“发送测试通知”合并为“保存并测试”。
- 移除重复检查按钮、取消订阅、蓝牙地址、Device Key 明文切换、Phase 调试文案和 Hilog 操作提示。

这些调整不改变通知订阅、OTP 解析或推送链路，只减少日常使用时的操作和信息噪音。

优化后的 ArkTS 工程已通过 `assembleApp --type-check`，并在 DevEco Previewer 中完成首次配置状态的布局检查。
