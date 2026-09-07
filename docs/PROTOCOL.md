# 蓝牙应用层协议

## 1. 设计目标

MVP 协议只需要传少量 OTP 数据，但必须处理 RFCOMM 的流式语义。

目标：

- 简单
- 可调试
- 有版本号
- 能去重
- 能检查过期
- 后续可加入认证

## 2. MVP 帧格式

使用 JSON Lines：

```text
<UTF-8 JSON>\n
```

例：

```json
{"version":1,"type":"otp","id":"699b1131-f6aa-43cc-b567-06f083c0d83b","timestampMs":1788751234000,"code":"836291","sender":"Tencent","expiresInSec":300}
```

## 3. 字段

| 字段 | 必填 | 类型 | 说明 |
|---|---|---|---|
| version | 是 | int | 协议版本，MVP=1 |
| type | 是 | string | `otp` |
| id | 是 | UUID string | 消息唯一标识 |
| timestampMs | 是 | int64 | 手机生成消息的 Unix 毫秒时间 |
| code | 是 | string | 4-8 位 OTP |
| sender | 否 | string | 发送方的脱敏/短名称 |
| sourceBundle | 否 | string | 来源 bundle |
| expiresInSec | 否 | int | 有效期 |

## 4. 为什么必须有换行分帧

RFCOMM 是 stream：

发送端：

```text
message A
message B
```

接收端可能得到：

```text
callback 1: half(A)
callback 2: rest(A) + half(B)
callback 3: rest(B)
```

因此不能直接 `JSONDecoder.decode(callbackData)`。

## 5. 长度限制

- 最大帧：8 KiB
- OTP code：4-8 ASCII digits
- sender：最多 64 UTF-8 characters
- sourceBundle：最多 256 characters

超限丢弃。

## 6. 幂等

Mac 端对 `id` 去重。

同一个 `id` 在 TTL 内重复到达时只处理第一次。

## 7. 过期

默认策略：

```text
now - timestampMs > 120s
```

不自动复制。

如果 `expiresInSec` 存在：

```text
now > timestampMs + expiresInSec
```

直接标记过期。

## 8. V2 安全协议

MVP 可在已人工配对设备上先验证链路，但正式长期使用建议增加消息认证。

V2 增加：

```json
{
  "deviceId": "...",
  "nonce": "...",
  "signature": "..."
}
```

可选设计：

```text
pairing 时生成共享 secret
↓
HMAC-SHA256(
  canonical_json_without_signature,
  secret
)
```

防御：

- 非授权设备注入验证码
- 重放旧消息
- 协议内容被篡改

## 9. ACK

MVP 可以不要求 ACK，因为验证码通知允许少量失败，且 SPP 有底层可靠传输。

如果需要应用层确认，V2 增加：

```json
{"version":2,"type":"ack","id":"...","status":"ok"}
```

手机只对 60 秒内未过期消息进行有限重传。
