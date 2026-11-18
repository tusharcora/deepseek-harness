---
description: "记录持久化类型更改及其兼容性确认。"
kind: persistence-change
---

# 2026-11-06-crew-improve-message-source

[English](2026-11-06-crew-improve-message-source.md) | 中文

## 概述

为持久化的消息来源联合类型新增 crew-improve 变体。crew-improve 用它标注其反思请求的输入。Session 格式版本保持不变。

## 目录

- [声明](#declaration)
- [兼容性](#compatibility)
- [验证](#verification)
- [开发备注](#dev-note)

<a id="declaration"></a>
## 声明

```yaml persistence-change
schemaVersion: 1
id: 2026-11-06-crew-improve-message-source
baseline: false
changes:
  - root: "event:agent/inbox/spliced"
    previous: "2026-10-27-retry-control-input"
    after: "a5e39f8b73792635623995f027c9a212cd206aae6c421e081b68876e7a9022e8"
    decision: same-version
  - root: "event:developer/message"
    previous: "2026-10-27-retry-control-input"
    after: "d33f5e50fb31bb8196d77d30b2b6d2fb4e864b6cb3bfb7c30c5b5b3fc758cf9a"
    decision: same-version
  - root: "event:session/title-llm-request"
    previous: "2026-10-27-retry-control-input"
    after: "47afce5c771e1f35fe39d681bd00db7a091fb5da7734d5400a194926cffe676d"
    decision: same-version
  - root: "event:user/message"
    previous: "2026-10-27-retry-control-input"
    after: "a5417b556dbfe59735a09ffbb9e97eb6581250c11a115fd168f1180f43a40978"
    decision: same-version
```

<a id="compatibility"></a>
## 兼容性

此更改只扩展联合类型，不修改任何已有变体。已有的 user、developer、agent inbox 和标题请求记录保留其当前的来源类型，因此本次更改之前写入的每个 Session 读取方式不变。只有实验性插件 crew-improve 发送反思请求时，消息才会带有 crew-improve 来源类型。没有 crew-improve 的读取方会在这些记录上看到一个未知的来源类型，并按处理其他由插件声明的类型的方式处理；消息内容和角色不变。没有更改任何头部、事件信封或已有的值类型，也不需要相邻迁移。

<a id="verification"></a>
## 验证

pnpm exec vitest run packages/experimental/crew-improve scripts/persistence-changes.spec.ts scripts/persistence-schema.spec.ts 在 3 个文件中通过了 178 个测试。持久化预览只把四个消息来源根上新增的 crew-improve 变体分类为变更，且不需要提升版本。

<a id="dev-note"></a>
## 开发备注

无。
