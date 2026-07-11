---
name: security-and-hardening
description: "Hardens code against vulnerabilities at trust boundaries. Under omo, escalates to security-research mode (3 vulnerability hunters + 2 PoC engineers) for production-critical code and uses grep_app MCP for known CVE pattern search. Use when handling user input, authentication, data storage, or external integrations."
allowed-tools: "Read Edit Bash Glob Grep WebFetch"
---

# security-and-hardening

## Overview

安全是设计问题,不是修补问题。修补在前 = 漏洞一直存在;设计在前 = 攻击面从一开始就被削减。

omo 没有专门的安全 skill。`security-and-hardening` 是这个 fork 填补的缺口,聚焦在三个信任边界:**输入边界**、**认证边界**、**集成边界**。

## When to Use

**Use when:**
- 处理 user input(表单、URL 参数、headers)
- 认证 / 授权 / session 管理
- 存储敏感数据(密码、token、PII)
- 调用第三方 API / 集成外部服务
- 处理文件上传 / 下载
- 写新 endpoint / 新 public function

**NOT for:**
- 内部 helper(无 user input)
- 纯展示 UI(无数据流)
- 已经审过的代码(重复审计浪费时间)

## Process

### 1. Identify trust boundaries

Where does untrusted data enter your system?
- HTTP request (body, query, headers, cookies)
- File system (uploads, imports)
- Database (reads from other services' writes)
- Third-party API responses
- User-controlled config

**Every boundary needs explicit validation. No implicit trust.**

### 2. Apply validation at boundaries

```typescript
// GOOD: explicit parse at boundary
function handleCreateUser(req: Request) {
  const input = CreateUserSchema.parse(req.body)  // throws on invalid
  return userService.create(input)  // trusts input
}

// BAD: validation scattered
function handleCreateUser(req: Request) {
  const { name, email } = req.body  // trusts shape
  if (!email.includes('@')) ...  // business logic now knows about HTTP shape
  return userService.create({ name, email })
}
```

**Rule: parse at the boundary, trust within.**

### 3. OWASP Top 10 — minimum bar

| Risk | Minimum defense |
|---|---|
| **Injection** | Parameterized queries. Never string-concat SQL/HTML/commands. |
| **Broken auth** | Use established libraries (passport, NextAuth). Don't roll your own crypto. |
| **Sensitive data exposure** | TLS in transit. Encrypt at rest. Don't log secrets. |
| **XXE** | Disable external entity processing in XML parsers. |
| **Broken access control** | Default deny. Check permissions on every request, not just at entry. |
| **Misconfiguration** | No default credentials. Disable debug mode in prod. Minimal dependencies. |
| **XSS** | Output encoding. CSP headers. Don't trust user content in HTML. |
| **Insecure deserialization** | Use typed parsers (JSON Schema, Zod). Never `eval` user input. |
| **Vulnerable deps** | Automated scanning (`npm audit`, `pip-audit`, `cargo audit`). Pin versions. |
| **Insufficient logging** | Log auth events, access events, validation failures. Don't log secrets. |

### 4. Secrets management

- **Never** hardcode secrets (API keys, DB passwords, JWT secrets)
- Read from environment variables or secret managers (AWS Secrets Manager, Vault)
- Add `.env` / `.env.*.local` to `.gitignore`
- Rotate secrets on suspected compromise
- Different secrets per environment (dev ≠ staging ≠ prod)

### 5. Dependency hygiene

```bash
npm audit            # Node
pip-audit            # Python
cargo audit          # Rust
```

Run in CI on every PR. **Block merge on high-severity vulnerabilities** (don't just warn).

Pin major versions in lockfiles; allow patch updates only.

### 6. Auth checks at every request

Authorization is per-request, not per-session:

```typescript
// GOOD: per-request check
app.delete('/users/:id', authenticate, authorize('user:delete'), deleteUser)

// BAD: per-session check
app.use(authenticate)  // assumes all routes need auth
app.delete('/users/:id', deleteUser)  // anyone authenticated can delete anyone
```

**Default deny.** Allow what you mean to allow.

### 6.5 omo: security-research mode + grep_app MCP (opt-in, production-critical only)

For production-critical code (auth, payment, PII handling), escalate to omo's parallel security audit:

```bash
# Ask Sisyphus to invoke /security-research mode
# This spawns 3 vulnerability hunters + 2 PoC engineers in parallel
# Each has its own context, all run concurrently
```

Output: per-attacker audit report with severity-classified findings + working PoC exploits for each issue. Use for code going to production with real user impact. Skip for prototypes or internal tools.

For dependency audits, use omo's `grep_app` MCP to search GitHub for known CVE patterns:

```
mcp__grep_app__searchGitHub <CVE-id> + <library> in:file
mcp__grep_app__searchGitHub <library> <vulnerability-pattern> language:python
```

This catches CVE fixes that are present in the wild but not yet in your local `npm audit` / `pip-audit` databases.

**Important**: these are enhancements, not replacements for Steps 1-7. Always run the standard pre-deployment gate first; omo's parallel audit is for finding issues the standard checklist misses.

### 7. Pre-deployment gate

Before merging anything that touches a trust boundary:
- [ ] Input validated with typed parser at boundary
- [ ] No string concatenation into SQL / HTML / shell
- [ ] Secrets read from env, not hardcoded
- [ ] Auth check present on every protected route
- [ ] Dependency audit clean
- [ ] Logs don't contain secrets
- [ ] Error responses don't leak stack traces / internal paths
- [ ] For production-critical code, omo security-research audit (Step 6.5) completed

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "这是内部工具,不用太严" | 内部 ≠ 安全。用户仍是不可信的(被钓鱼、被盗号)。 |
| "validation 太繁琐,跑通就行" | 边界 validation 一处。业务逻辑里散落 validation = 一致性无保证。 |
| "我们用 ORM,SQL injection 不可能" | ORM 防 parameter 化,但不防 raw SQL fragments / queryRaw。 |
| "JWT secret 写代码里方便" | git 一旦 push,secret 就泄露。env / secret manager only。 |
| "前端 validation 够了" | 前端 validation 是 UX,不是安全。用户可以绕过。Backend 必须重新 validation。 |
| "我们小公司,没人会黑我们" | 自动化扫描不挑公司。任何暴露的 endpoint 都是潜在目标。 |

## Red Flags

- 用户输入没经过 typed parser
- SQL / HTML / shell 用字符串拼接
- 密钥写进代码 / config / commit
- 用 `eval` / `Function` 跑用户输入
- 错误响应包含 stack trace / 文件路径
- 日志里出现密码 / token / PII
- Auth 只在 session 开始检查一次(不是 per-request)
- 依赖里有 known high-severity CVE
- `/admin` 路由没额外的 auth 检查

## Verification

Before declaring secure, confirm:
- [ ] Every trust boundary has typed input validation
- [ ] No string concatenation into SQL / HTML / shell
- [ ] Secrets from env, not committed
- [ ] Per-request auth on protected routes
- [ ] Dependency audit clean (no high/critical)
- [ ] CSP / security headers set
- [ ] Logs scrubbed of secrets
- [ ] Error responses don't leak internals
- [ ] Penetration test or threat model for new attack surface

## pwf Integration

Maps to `task_plan.md` **Phase 5.5: Security Review** (sub-phase). Security checklist goes in `.planning/<plan-id>/security-review.md` — separate file so it doesn't pollute attestation but survives plan changes.

See [pwf-integration.md](../../pwf-integration.md).