# 测试与验收计划

## 1. 总体策略

本项目最大风险在系统能力边界，因此测试采用 Gate 模式。

```text
Gate 1: Notification Content
        ↓ pass
Gate 2: RFCOMM Transport
        ↓ pass
Gate 3: End-to-End
        ↓ pass
MVP Feature Development
```

## 2. Gate 1：通知正文

### Case N01 普通通知

操作：让任意第三方 App 发布通知。

预期：`onReceiveMessage` 被调用。

### Case N02 短信验证码通知

发送：

```text
【Test】验证码 836291，5 分钟内有效。
```

预期：NotificationInfo 中可找到 `836291`。

### Case N03 锁屏

锁屏后发送验证码。

预期：记录回调是否存在以及正文是否脱敏。

### Case N04 隐藏通知内容

开启系统隐私显示策略。

预期：明确系统行为，不强行绕过。

### Gate 通过条件

必须满足 N02。

如果 N02 永远只能看到“收到一条新消息”，主路线判定失败。

## 3. Gate 2：RFCOMM

### B01 配对

Mac 与 Huawei 手机完成蓝牙配对。

### B02 首次连接

手机连接 Mac RFCOMM service。

### B03 连续消息

发送 100 条：

```text
hello-0001
...
hello-0100
```

预期：无丢失、无重复、顺序正确。

### B04 半包/粘包

发送不同长度 JSON，验证 Mac FrameDecoder。

### B05 断链恢复

关闭手机蓝牙 10 秒后再打开。

预期：系统可以恢复到可再次发送状态，无需杀进程。

### B06 Mac 睡眠

Mac 睡眠再唤醒。

预期：服务能重新对外可用。

## 4. Gate 3：端到端

### E01 正常 OTP

发送验证码短信。

预期：

- Mac 显示系统通知。
- Clipboard 等于 OTP。
- 延迟 < 2 秒为目标。

### E02 多数字文本

```text
订单 123456789，验证码 483921，5 分钟有效。
```

预期：提取 `483921`。

### E03 无验证码

```text
您的快递单号 123456789 已发货。
```

预期：不自动复制。

### E04 重复通知

同一 Notification 更新两次。

预期：Mac 只处理一次。

### E05 过期队列

断开蓝牙超过 2 分钟再恢复。

预期：旧验证码不自动复制。

## 5. OTP Detector 单元测试样本

应覆盖中文与英文：

```text
您的验证码为 123456。
验证码：9382，请勿泄露。
动态码 839201，10分钟内有效。
Your verification code is 483921.
OTP: 774411
```

反例：

```text
订单号 123456 已完成。
余额 1234.56 元。
2026-09-07 12:30 登录提醒。
手机尾号 1234。
```

## 6. 性能指标

记录：

- notification callback → send start
- connect time
- RFCOMM send completion
- Mac receive time
- clipboard write time

目标：

```text
P50 < 500 ms
P95 < 2 s
```

在“已有连接”场景统计，首次蓝牙建连单独统计。

## 7. 稳定性

日常使用测试：

- 24 小时后台
- 50 次验证码
- 10 次蓝牙开关
- 5 次 Mac 睡眠/唤醒
- 5 次手机重启
- 5 次 Mac App 重启

验收：

- 不需要重新安装 App。
- 不出现持续高 CPU。
- 不把验证码明文写入日志文件。

## 8. Phase 0.3：Bark 推送 Gate

Phase 0.3 不再把 RFCOMM 作为 MVP 传输通道。蓝牙只负责激活 HarmonyOS 通知订阅；OTP 通过 HTTP 推送到自建 `bark-server`，再由 BarkMac 使用 `macos_sse` 接收。

### Gate A：Bark Server

```bash
curl http://127.0.0.1:8080/ping
```

预期 HTTP 200 和 `pong`。

### Gate B：BarkMac 注册

配置自建 Server URL，完成 macOS 通知权限、设备注册和 SSE 连接。Device Key 只保存在本机和手机配置中，不写入 Git。

### Gate C：Server → BarkMac

使用测试 payload 调用 `POST /push`，预期 BarkMac 记录页出现测试消息。

### Gate D：HarmonyOS → Bark Server

在手机配置 Server URL 和 Device Key，点击“发送 Bark 测试通知”。预期 Hilog 出现 `[BARK_PUSH_SUCCESS]`，BarkMac 出现 `Harmony OTP Test`。

### Gate E：NotificationExtractor

用真实通知确认字段路径：

```text
NotificationInfo.content.title
NotificationInfo.content.text
NotificationInfo.bundleName
```

实现中不得长期打印完整 `NotificationInfo`。

### Gate F：OtpParser

独立测试必须覆盖：

- 中文关键词和 4–8 位验证码
- `OTP`、`verification code` 等英文关键词
- 关键词附近数字优先
- 多数字正文拒绝误判
- 订单号、金额、时间、手机号等反例
- 来源标题和 `【来源】` 回退

### Gate G：真实短信端到端

1. BarkMac 保持运行并连接 SSE。
2. 手机保持通知订阅状态。
3. App 可在前台、后台和锁屏状态分别测试。
4. 发送真实验证码短信。
5. 只检查脱敏 Hilog 和 BarkMac 通知，不把真实验证码写入文档或日志。

只有手机收到短信、正文可见、Parser 提取成功、HTTP 返回 2xx 且 BarkMac 自动显示四项同时满足时，Phase 0.3 才能标记 PASS。
