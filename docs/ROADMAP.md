# Roadmap

当前已知问题、能力边界和未验证项统一记录在 [`CURRENT_LIMITATIONS.md`](./CURRENT_LIMITATIONS.md)。

## Phase 0：Feasibility POC

### P0.1 HarmonyOS 通知订阅

- [x] 创建 API 22 Stage 工程
- [x] 配置 `NotificationSubscriberExtensionAbility`
- [x] 配置 `SUBSCRIBE_NOTIFICATION`
- [x] 完成自动签名/ACL
- [x] 拉起订阅授权页
- [x] 打印并确认真实通知结构
- [x] 验证普通通知正文

Exit Criteria：通知订阅扩展可稳定收到真实通知。

### P0.2 蓝牙-backed notification subscription

- [x] ACCESS_BLUETOOTH runtime permission
- [x] Enumerate paired devices
- [x] Subscribe the paired MacBook address
- [x] Verify ordinary NotificationInfo callback
- [x] Verify SMS notification body

Exit Criteria：真实短信通知正文可读取。

### P0.3 OTP → Bark → BarkMac

- [x] NotificationExtractor
- [x] OTP Parser and independent test cases
- [x] Preferences configuration
- [x] Bark HTTP push service
- [x] Self-hosted bark-server
- [x] BarkMac registration and SSE
- [x] HarmonyOS Bark test push
- [x] Real SMS end-to-end test (foreground)
- [x] Background and lock-screen matrix

Exit Criteria：真实短信到 Mac 自动显示验证码。

## Phase 1：Daily-use stabilization

- [x] HarmonyOS 状态首页
- [ ] 目标设备绑定
- [ ] 来源 App 白名单
- [ ] OTP 高置信度识别
- [x] 去重
- [ ] 发送队列
- [ ] BarkMac 常驻与登录启动验证
- [ ] 自动复制能力评估
- [ ] 最近 10 条内存历史
- [ ] 完整脱敏日志（当前仍可能记录通知标题和蓝牙元数据）

## Future：Native receiver / Bluetooth transport

- [ ] Native macOS receiver
- [ ] Bluetooth RFCOMM transport
- [ ] Clipboard integration

## Phase 2：稳定性

- [ ] Mac sleep/wake 恢复
- [ ] Phone Bluetooth toggle 恢复
- [ ] 自动重连
- [ ] 指数退避
- [ ] 统计延迟与错误码
- [ ] 24h soak test

## Phase 3：安全

- [ ] Device ID
- [ ] Pairing secret
- [ ] HMAC message authentication
- [ ] Nonce
- [ ] Replay protection
- [ ] Clipboard 自动清理（可选）

## Phase 4：体验优化

- [ ] BLE transport 评估
- [ ] 来源图标
- [ ] 快捷键显示最近 OTP
- [ ] Universal link / browser helper 评估

## 不做优先级

短期不做：

- 云同步
- 用户账户
- Web 控制台
- 消息全文同步
- 多平台客户端
