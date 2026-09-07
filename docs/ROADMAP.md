# Roadmap

## Phase 0：Feasibility POC

### P0.1 HarmonyOS 通知订阅

- [ ] 创建 API 22 Stage 工程
- [ ] 配置 `NotificationSubscriberExtensionAbility`
- [ ] 配置 `SUBSCRIBE_NOTIFICATION`
- [ ] 完成自动签名/ACL
- [ ] 拉起订阅授权页
- [ ] 打印普通通知结构
- [ ] 打印“信息”通知结构
- [ ] 验证验证码正文

Exit Criteria：验证码正文可获取。

### P0.2 RFCOMM

- [ ] Mac 发布 SDP service
- [ ] Mac 监听 RFCOMM channel open
- [ ] 手机 SPP connect
- [ ] 手机发送 Hello
- [ ] 100 条稳定性测试
- [ ] 断开重连测试

Exit Criteria：100 条完整接收且可恢复断链。

### P0.3 E2E

- [ ] NotificationNormalizer
- [ ] 简单 OTP Detector
- [ ] JSON Lines
- [ ] Mac JSON Decoder
- [ ] Clipboard
- [ ] User Notification

Exit Criteria：真实短信到 Mac 自动复制。

## Phase 1：MVP

- [ ] HarmonyOS 状态首页
- [ ] 目标设备绑定
- [ ] 来源 App 白名单
- [ ] OTP 高置信度识别
- [ ] 去重
- [ ] 发送队列
- [ ] Mac Menu Bar App
- [ ] 自动复制开关
- [ ] 最近 10 条内存历史
- [ ] 脱敏日志

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
- [ ] Mac 登录启动
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
