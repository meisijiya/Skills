---
name: source-driven-development
description: "Forces the agent to verify framework / library API behavior against official documentation before writing code. Under omo, uses context7 MCP (primary, replaces WebFetch) and grep_app MCP (real-world examples). Use when working with any framework or library where correctness matters, when crossing major version upgrades, or when debugging 'why does this API behave like that?'."
allowed-tools: "Read Edit Bash Glob Grep WebFetch Bash"
---

# source-driven-development

## Overview

框架 / 库的 API 必须先查官方文档,凭记忆写代码容易错(尤其大版本升级)。训练数据有截止日期,但 npm/pypi/cargo 不会等你。

"我用过 X 框架" ≠ "我知道 X 框架现在的 API"。React 18 → 19、Next.js 13 → 14 → 15、Vue 2 → 3、Tailwind 3 → 4 —— 每个大版本都改 breaking changes。

## When to Use

**Use when:**
- 用任何框架 / 库的 API(组件、钩子、配置项)
- 跨大版本升级
- 不熟悉的 API
- 调试"为什么这个 API 表现不对"
- 写 spec 时需要确认可行性
- 选型时需要对比多个方案

**NOT for:**
- 标准库用法(语言自带,基本不变)
- 纯业务逻辑(无外部依赖)
- 已知 trivial API(`Array.map`、`dict.get`)
- 已经在 `findings.md` 查过且 < 1 周内的

## Process

### 1. Identify what to verify

State explicitly:
- **Library/Framework:** <name + version>
- **API surface:** <function / class / hook / config key>
- **Version range:** <current pinned version → target version if upgrading>
- **Question:** <what specifically do I need to verify>

### 2. Query authoritative source

Priority of sources (omo-optimized):

1. **Context7 MCP** (omo primary, replaces manual WebFetch): `mcp__context7__get-library-docs`
   - Structured, version-pinned, AI-optimized
2. **grep_app MCP** (omo, real-world examples): `mcp__grep_app__searchGitHub`
   - "How does <lib> handle <pattern>" → see actual production code
3. **WebFetch fallback** (when omo MCPs unavailable): official docs URL
4. **Source code:** GitHub repo at the exact tagged version (for internals)
5. **CHANGELOG / migration guide** (for upgrades)
6. **Type definitions:** `.d.ts` files in the installed package

Avoid:
- Random blog posts (often outdated)
- Stack Overflow answers (no version context usually)
- AI-generated tutorials (may hallucinate)

### 3. Extract the relevant excerpt

Read enough to confirm:
- Exact signature (parameter types, return type)
- Default behavior (what does it do with no args)
- Error behavior (what does it throw / return on invalid input)
- Version when introduced / deprecated

### 4. Write to `findings.md`

```markdown
## <Date> — <library> <version> — <API>

**Source:** <URL> (accessed <date>)
**Pinned version:** <version in package.json / pyproject.toml / etc.>

**Key excerpt:**
> <2-5 line quote from docs>

**My interpretation:**
<what this means for the code I'm about to write>

**API signature confirmed:**
```typescript
function createUser(input: UserInput): Promise<User>
```
```

This is **not** for the agent's future self only — it's for the human reviewer and for re-verification after upgrades.

### 5. Cite in code

If the API usage is non-obvious, add a comment with the source:

```typescript
// https://react.dev/reference/react/useEffect#parameters
// Effect callbacks must be idempotent — React may re-run them in StrictMode.
useEffect(() => {
  const subscription = subscribe(userId);
  return () => subscription.unsubscribe();
}, [userId]);
```

This makes the "why" traceable to "where in the docs this came from".

### 6. Verify version match

Confirm the docs version matches your installed version:

```bash
npm ls <package>     # shows installed version
grep "<package>" package.json  # confirms pinned range
```

A doc snippet from version 5 may not apply to your installed version 3.

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "我用过 X 框架,知道 API" | 你的训练数据有截止日期。React 18 vs 19 的 useEffect 行为变了。 |
| "文档太啰嗦" | 文档啰嗦比写错 API 强 100x。错 API 的 bug 调试时间 >> 读文档时间。 |
| "这个 API 简单,不用查" | 简单的 API 也升级过 breaking change。`Array.prototype.flat` 在 ES2019 才进标准。 |
| "上下文太长了,先写再说" | 上下文里没有的,你就要去查。findings.md 是查的产物。 |
| "官方文档过时了,看 GitHub issue 更准" | 偶尔对。但默认走官方文档,issue 作为补充。 |
| "Context7 没有这个库" | 用 WebFetch 直接抓官方 docs URL。找不到 = 文档没公开,看源码。 |

## Red Flags

- 凭记忆写 API 调用
- 不引用源 URL
- 不查版本(用错版本的 API)
- 调试时凭感觉改 API 参数
- 把 findings 留在 context 里不写 `findings.md`
- 引用 2 年前的博客文章当权威
- `findings.md` 没记录访问日期(无法判断是否过期)

## Verification

Before writing the API call, confirm:
- [ ] Source URL recorded in `findings.md`
- [ ] Access date recorded
- [ ] Installed version matches doc version
- [ ] Exact signature quoted from source
- [ ] Behavior for the specific edge case I'm handling is documented

After writing the API call, confirm:
- [ ] Code comment cites source (for non-obvious APIs)
- [ ] Test covers the documented behavior (boundary test)
- [ ] If upgrading: migration guide cited, deprecation warnings handled

## pwf Integration

Maps to `task_plan.md` **Phase 2: Research** (sub-phase). Findings go in `findings.md`, NOT in `task_plan.md` — research notes are untrusted content (web pages, API responses), and putting them in the plan file would break attestation guarantees.

| pwf hook | Effect |
|---|---|
| `UserPromptSubmit` | Inject task_plan.md (attested); findings.md is read on-demand only |
| `PreCompact` | Flush recent findings summary so post-compaction agent has context |

See [pwf-integration.md](../../pwf-integration.md).