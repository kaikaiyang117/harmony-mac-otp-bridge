# BarkMac / bark-server Setup

Phase 0.3 使用自建 `htnanako/bark-server` 和 `htnanako/bark-macOS`，不使用 Bark 官方公共服务器。

## 1. 启动 bark-server

在 Mac 上安装并启动 Docker Desktop，然后执行：

```bash
mkdir -p /Users/<user>/bark-server/bark-data
docker run -d \
  --platform linux/amd64 \
  --name bark-macos-server \
  --restart unless-stopped \
  -p 8080:8080 \
  -v /Users/<user>/bark-server/bark-data:/data \
  ghcr.io/htnanako/bark-server
```

Apple Silicon 主机如果镜像没有 `linux/arm64` manifest，需要增加 `--platform linux/amd64`。

检查服务端：

```bash
curl http://127.0.0.1:8080/ping
```

预期 HTTP 200，并返回 `pong`。

## 2. 安装并配置 BarkMac

从 [BarkMac Releases](https://github.com/htnanako/bark-macOS/releases) 下载对应 CPU 架构的 `.dmg`，将 `BarkMac.app` 放入 `/Applications` 并启动。

在服务端配置页填写：

```text
http://127.0.0.1:8080
```

依次执行：

1. 测试服务器
2. 请求 macOS 通知权限
3. 注册当前设备
4. 连接事件流

注册生成的 Device Key 是接收凭证，只保存在本机和手机 Preferences 中，不得写入 Git、README、测试结果或日志。

## 3. 纯 Mac 推送测试

使用注册得到的 Device Key 在本机执行，不要把真实值提交到仓库：

```bash
curl -X POST http://127.0.0.1:8080/push \
  -H 'Content-Type: application/json; charset=utf-8' \
  -d '{
    "device_key": "YOUR_DEVICE_KEY",
    "title": "Harmony OTP Test",
    "body": "Bark connection works",
    "group": "OTP"
  }'
```

预期 `HTTP 200`，并在 BarkMac 记录页看到测试消息。

## 4. HarmonyOS 配置

手机和 Mac 位于同一局域网时，手机端 Server URL 填写 Mac 的局域网地址，例如：

```text
http://192.168.1.20:8080
```

不要填 `127.0.0.1` 或 `localhost`，因为它们指向手机自身。手机端 Device Key 通过 BarkMac 注册页生成后手动填写并保存。

点击“发送 Bark 测试通知”，预期 Hilog 出现：

```text
[BARK_PUSH_SUCCESS]
```

## 5. 常见问题

- `/ping` 失败：检查 Docker 容器、端口 8080 和 `docker logs bark-macos-server`。
- Mac 本机成功、手机失败：检查 Mac 防火墙、Wi-Fi 客户端隔离、手机与 Mac 是否同一子网。
- BarkMac 无通知：确认通知权限、Device Key、SSE 连接和服务端地址。
- HTTP 只适合可信局域网；不可信公共 Wi-Fi 不应长期传输验证码明文。

## 6. 隐私边界

手机端只发送 `source` 和提取后的验证码，不发送完整短信正文。Preferences 只保存 Server URL、Device Key 和转发开关，不保存验证码历史。日志不得打印完整通知、短信、验证码或 Device Key。
