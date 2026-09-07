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
