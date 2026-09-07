# macOS 端实现说明

## 1. 技术选择

推荐：

- Swift
- AppKit + SwiftUI（菜单栏 UI 可用 SwiftUI，底层 Bluetooth 使用 AppKit/Foundation 环境）
- IOBluetooth
- UserNotifications
- NSPasteboard

目标形态：菜单栏常驻应用，不占 Dock 或只在设置窗口出现。

## 2. RFCOMM 服务端

Apple 的 `IOBluetoothRFCOMMChannel` 支持通过 channel-open notification 接受新 RFCOMM channel；`IOBluetoothSDPServiceRecord` 可以将服务记录发布到本地 SDP server。

核心对象：

```text
BluetoothServicePublisher
  ├─ IOBluetoothSDPServiceRecord
  └─ IOBluetoothUserNotification

RFCOMMConnection
  └─ IOBluetoothRFCOMMChannel
```

## 3. SDP Service

需要发布一个自定义 RFCOMM 服务，使手机可以发现/连接指定 UUID 的服务。

建议 Service UUID 固定在项目配置中，例如：

```text
7A8F9C42-59E4-4A79-8DC9-4B97C3B13001
```

注意：不要复用华为文档示例中的测试 UUID 作为正式产品 UUID。

服务记录需要包含：

- Service Name: `Harmony OTP Bridge`
- Service Class UUID
- Protocol Descriptor List
- RFCOMM channel

实际 SDP dictionary 的字段和值应参考当前 IOBluetooth API 和 Apple 示例进行实现，并在真机上通过系统蓝牙浏览确认服务可被发现。

## 4. 接受 RFCOMM Channel

注册：

```swift
IOBluetoothRFCOMMChannel.register(
    forChannelOpenNotifications: receiver,
    selector: #selector(receiver.channelOpened(_:channel:))
)
```

或者使用带 channel ID / direction 的变体限制接收范围。

Channel 打开后：

1. 保存强引用。
2. 设置 delegate。
3. 接收 data callback。
4. 断开时清理状态。

`IOBluetoothRFCOMMChannel` 的 delegate 是数据与连接事件的入口。

## 5. 数据接收

RFCOMM 是字节流，不能假设一次 callback 就是一条消息。

维护缓存：

```swift
final class LineFrameDecoder {
    private var buffer = Data()

    func append(_ data: Data) -> [Data] {
        buffer.append(data)
        // 按 0x0A 拆分完整帧，保留尾部半帧
    }
}
```

约束：

- 单帧最大 8 KB。
- 超过上限直接丢弃并重置 buffer。
- UTF-8 解码失败丢弃。

## 6. 协议模型

```swift
struct OTPMessage: Codable {
    let version: Int
    let type: String
    let id: UUID
    let timestampMs: Int64
    let code: String
    let sender: String?
    let sourceBundle: String?
    let expiresInSec: Int?
}
```

校验：

```text
version == 1
type == "otp"
code matches ^[0-9]{4,8}$
abs(now - timestamp) < allowedWindow
id 未处理过
```

## 7. 去重

Mac 端也做一次幂等保护。

维护 LRU / TTL set：

```text
messageId → receivedAt
```

TTL 10 分钟，最多 100 条。

## 8. Clipboard

```swift
func copyOTP(_ code: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(code, forType: .string)
}
```

设置项：

```text
☑ 收到高置信度验证码时自动复制
☑ 收到验证码时显示系统通知
☐ 保留最近验证码历史
```

## 9. macOS 通知

使用 `UNUserNotificationCenter` 请求通知权限。

通知内容：

```text
Harmony OTP
836291
已复制，可直接粘贴
```

不要在通知 subtitle 中重复发送者和完整短信正文，避免锁屏泄露更多信息。

## 10. 菜单栏 UI

建议：

```text
[OTP icon]

Harmony OTP Bridge
● Huawei Phone 已连接

最近验证码
836291   8 秒前   [复制]
391204   4 分钟前 [复制]

──────────────
自动复制      ✓
启动时运行    ✓
打开设置...
退出
```

隐私模式可显示：

```text
836•••
```

点击时才显示/复制。

## 11. App 生命周期

需要考虑：

- Mac 睡眠/唤醒
- 蓝牙关闭/重新开启
- 手机离开范围再回来
- RFCOMM channel 意外断开
- App 重启后重新发布 SDP service

建议在：

```text
applicationDidFinishLaunching
```

时启动 RFCOMM 服务。

## 12. 日志

允许记录：

```text
received otp message id=... length=6
clipboard write success
rfcomm disconnected status=...
```

禁止默认记录：

```text
received code=836291
full sms=...
```

## 13. P0 验收

先不做菜单栏。

只做 CLI-like 调试窗口/console：

```text
RFCOMM listening...
client connected
received: hello-from-harmony
```

连续 100 次发送均正确后，再接入 JSON parser 与 UI。
