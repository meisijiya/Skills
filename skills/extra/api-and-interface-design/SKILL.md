---
name: api-and-interface-design
description: "Contract-first API and module boundary design. Use when designing REST/GraphQL/RPC endpoints, defining type contracts between modules, establishing boundaries between frontend and backend, or publishing an SDK."
allowed-tools: "Read Edit Bash Glob Grep WebFetch"
---

# api-and-interface-design

## Overview

接口是合同 —— 设计错误的接口改起来贵 10x(Hyrum's Law:用户开始依赖你所有行为,即使是 bug)。先设计 contract,再实现,再集成。

omo 没有专门的接口设计 skill —— `frontend-ui-engineering` 偏 UI,`api-and-interface-design` 偏 backend 契约。这个 skill 填补。

## When to Use

**Use when:**
- 设计 REST / GraphQL / gRPC / RPC endpoint
- 定义 module / package / library 的 public surface
- 跨语言 / 跨团队的 type contract
- 发布 SDK / 公共 API
- 重构现有接口(breaking change)

**NOT for:**(场景描述 —— 具体用哪个 skill 由 description 匹配决定,不硬指)
- 内部 helper(私有函数,不需要 contract)
- 一次性脚本(用完就丢)
- UI-only 接口(组件 props)
- Database schema 本身

## Process

### 1. Identify the contract surface

List what's exposed:
- Endpoints / functions / types
- Input / output shapes
- Error responses
- Auth requirements
- Rate limits
- Versioning policy

### 2. Apply Hyrum's Law

**Once your API has users, every observable behavior — including bugs — becomes a contract.** Therefore:
- Name things generically, not by current implementation
- Don't expose internal types in public surface
- Document even "obvious" behavior — what's obvious to you isn't to the caller

### 3. Apply the One-Version Rule

**Avoid supporting multiple major versions simultaneously.** It's expensive, it's confusing, it fragments the ecosystem.

Instead:
- Use additive non-breaking changes within a major version
- Ship clear migration guides for breaking changes
- Sunset old versions aggressively (within 6-12 months)

### 4. Define error semantics

Every endpoint must specify:
- What errors can be returned (typed, not just status code)
- What each error means (semantic, not HTTP status)
- Retry-ability (idempotent? safe to retry?)
- Example responses (success + each error)

```typescript
// GOOD: typed, semantic
type CreateUserError =
  | { kind: 'invalid_email'; field: string }
  | { kind: 'email_taken'; existing_id: string }
  | { kind: 'rate_limited'; retry_after_seconds: number }

// BAD: opaque
throw new Error('Bad request')  // 400
```

### 5. Specify validation at trust boundary

Input validation belongs at the boundary, not in business logic:
- Reject malformed input at the edge
- Business logic trusts its inputs (parse, don't validate)
- Don't re-validate deep in the stack

### 6. Write contract first (test-first API)

Write the contract as:
- Type definitions (.d.ts /.pyi / etc.)
- OpenAPI / GraphQL schema / protobuf
- Example request/response pairs

Review the contract **before** implementing the handler.

### 7. Version from day 1

Every endpoint carries version info — in URL, header, or content type:

```
/api/v1/users          # URL
Accept: application/vnd.myapi.v2+json   # content type
```

Don't wait to add versioning. Retrofitting is painful.

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "我们以后再考虑版本" | 以后 = 上线后 = 永远不会有。Version from day 1。 |
| "HTTP status code 够了" | Status code 不带语义。Typed errors 让客户端写得起 exhaustive switch。 |
| "用户不会乱调我们的内部 API" | Hyrum's Law:他们会。即使文档说不要。 |
| "validation 在每个 handler 里写更安全" | validation 散落 = 一致性无保证。在边界一处,业务逻辑信任输入。 |
| "REST 太老,直接 GraphQL" | 选型看场景。REST 简单且缓存友好;GraphQL 灵活但工具链复杂。不要为新而新。 |
| "向后兼容太麻烦" | 不兼容一次 = 用户迁一次。不兼容 N 次 = 用户跑路。 |

## Red Flags

- 内部类型泄漏到 public API
- 没有 typed errors(只用 HTTP status code)
- 没有版本号(endpoint 设计时就漏)
- validation 散落在 handler 里
- 接口文档跟实现脱节(代码改了,文档没改)
- 不写 contract test 就实现 handler
- 同时支持 2 个 major version(违反 One-Version Rule)

## Verification

Before declaring the API designed, confirm:
- [ ] Contract spec exists (OpenAPI / GraphQL SDL / protobuf /.d.ts)
- [ ] Every endpoint has typed errors with semantic names
- [ ] Versioning strategy specified (URL, header, or content type)
- [ ] Input validation specified at the trust boundary
- [ ] Idempotency / retry-ability specified for mutating endpoints
- [ ] Auth requirements specified per endpoint
- [ ] Example request + response pairs documented
- [ ] Contract reviewed by at least one peer before implementation

## omo Integration

Capture the contract in the Prometheus plan, use task tools for producer/consumer slices, and let `review-work` verify the boundary.
