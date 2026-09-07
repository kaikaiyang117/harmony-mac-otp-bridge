# macos-app

macOS 端工程目录。

推荐使用 Xcode 创建 Swift macOS App。

第一提交只完成 RFCOMM POC：

1. 引入 IOBluetooth framework
2. 发布自定义 SDP RFCOMM service
3. 接受 incoming channel
4. 打印收到的 UTF-8 字节流

先验证 `hello-from-harmony`，再实现 Menu Bar、JSON、Clipboard。

详细步骤见 `../docs/MACOS_IMPLEMENTATION.md`。
