# AGENTS.md

本文档用于 Codex、Claude Code、CodeGenie 等代码 Agent。

## 项目目标

构建一个仅供用户自有 HarmonyOS 手机和 macOS 设备使用的验证码桥接工具。

主链路：

```text
HarmonyOS NotificationSubscriberExtensionAbility
→ OTP Parser
→ Bluetooth SPP/RFCOMM
→ macOS Receiver
→ Clipboard + Notification
```

## 第一原则

不要跳过 P0 验证直接实现完整产品。

必须按以下 Gate 顺序开发：

1. `GATE_NOTIFICATION_CONTENT`
2. `GATE_RFCOMM_TRANSPORT`
3. `GATE_END_TO_END`
4. `MVP`

任何 Gate 未通过时，不得假设后续能力可用。

## 禁止事项

- 不实现读取系统短信数据库的方案，除非后续明确证明官方 API 可合法使用且用户要求切换路线。
- 不使用 Accessibility/无障碍自动抓取 UI 作为默认方案。
- 不依赖云服务器完成 MVP。
- 不把验证码写入普通日志。
- 不硬编码真实蓝牙 MAC 地址、证书、账号、签名材料。
- 不把 POC 代码描述为 production-ready。

## HarmonyOS 端要求

- Stage 模型。
- API 22+。
- 使用 `NotificationSubscriberExtensionAbility`。
- 使用系统授权页面获取通知订阅授权。
- 蓝牙优先采用官方示例同类的 SPP/RFCOMM 路径。
- Extension 生命周期短暂，连接管理不能假设 Ability 永久在线。
- 必须有连接重用、失败重连、发送队列和超时。

## macOS 端要求

- Swift。
- 菜单栏常驻应用优先。
- 使用 `IOBluetooth` RFCOMM 接收。
- 将传输层、协议解析层、OTP 展示层分离。
- Clipboard 行为必须可配置。
- 本地历史默认最多保留 10 条，且默认不持久化完整 OTP。

## 协议要求

MVP 使用 JSON Lines：每条 JSON 后追加 `\n`。

必须包含：

- `version`
- `type`
- `id`
- `timestampMs`
- `code`

可选：

- `sender`
- `sourceBundle`
- `expiresInSec`

后续增加：

- `deviceId`
- `nonce`
- `signature`

## OTP 提取规则

第一版采用“关键词 + 数字候选”策略，不要只用一个粗暴正则。

优先级：

1. 文本含 `验证码` / `校验码` / `动态码` / `OTP` / `verification code` 等关键词。
2. 在关键词附近寻找 4-8 位数字。
3. 排除手机号、订单号、时间、金额等常见误判。
4. 无足够置信度时不自动复制，只显示原始通知摘要供用户确认。

## 测试要求

任何改动至少覆盖：

- OTP 正常提取
- 多个数字时选取正确候选
- 无验证码时不发送
- 重复通知去重
- 蓝牙断开重连
- JSON 半包/粘包
- 非法 JSON
- 过期验证码
- Mac 剪贴板权限/失败场景

## 文档同步

如技术路线、系统 API 或协议字段变化，同一提交必须同步更新 `docs/` 下对应文档。
