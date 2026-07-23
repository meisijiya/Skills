---
name: source-driven-development
description: "Forces the agent to verify framework / library API behavior against official documentation before writing code. Under omo, uses context7 MCP (primary, replaces WebFetch) and grep_app MCP (real-world examples). Apply ONLY when API is unfamiliar, version-sensitive (major upgrade), or behavior is unexpectedly wrong. Don't trigger for stdlib or well-known APIs."
allowed-tools: "Read Edit Bash Glob Grep WebFetch"
---

# source-driven-development

## Overview

框架 / 库的 API **不熟时**先查官方文档,凭记忆写代码容易错(尤其大版本升级)。训练数据有截止日期,但 npm/pypi/cargo 不会等你。

> **收紧触发条件**:本 skill 不再适用"任何框架 / 库的 API"。仅在下列场景必查:
> 1. API **首次接触**(陌生库)
> 2. API **跨大版本升级**(React 18→19, Next.js 13→14→15, Vue 2→3, Tailwind 3→4)
> 3. API **行为不符合预期**(debugging 诡异行为)
> 标准库与知名 API (Array.map / Promise.all / fetch / etc.)**不需要**走本 skill。

"我用过 X 框架" ≠ "我知道 X 框架现在的 API"。React 18 → 19、Next.js 13 → 14 → 15,每个大版本都改 breaking changes。

## When to Use

**Use when — narrowed:**
- **陌生 API**:第一次接触的库 / 框架 / 配置项
- **跨大版本升级**:从 v_n 升 v_(n+1) 或 v_(n+2),涉及 breaking change
- **行为诡异**:现有 API 输出与文档不符(debugging 时的诊断步骤)
- **选型对比**:评估 2+ 候选库的关键 API 差异
- **写 spec 时**:spec 中包含未经验证的 API 用法,需要 feasibility 校验

**NOT for — expanded NOTs:**
- 标准库用法(Array / Promise / fetch / dict / iter,语言自带基本不变)
- 已经熟透的 v0 库(已在 `.omo/notepads/<plan>/learnings.md` 查过,且 < 1 周内)
- 纯业务逻辑(无外部依赖)
- 已知 trivial API(`arr.map` / `dict.get` / `try/except` 之类)

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

### 4. Write to `.omo/notepads/<plan>/learnings.md`

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
| "这个 API 简单,不用查" | 简单熟透的 API 不属于本 skill 触发范围。如果还在查,说明它不熟。 |
| "上下文太长了,先写再说" | 上下文里没有的,你就要去查。.omo/notepads/<plan>/learnings.md 是查的产物。 |
| "官方文档过时了,看 GitHub issue 更准" | 偶尔对。但默认走官方文档,issue 作为补充。 |
| "Context7 没有这个库" | 用 WebFetch 直接抓官方 docs URL。找不到 = 文档没公开,看源码。 |
| "我要写 5 个 API 调用,每次都查烦死了" | 只有不熟的才查。.omo/notepads/<plan>/learnings.md 缓存结果,同 API 7 天内不再查。 |

## Red Flags

- 凭记忆写 API 调用
- 不引用源 URL
- 不查版本(用错版本的 API)
- 调试时凭感觉改 API 参数
- 把 findings 留在 context 里不写 `.omo/notepads/<plan>/learnings.md`
- 引用 2 年前的博客文章当权威
- `.omo/notepads/<plan>/learnings.md` 没记录访问日期(无法判断是否过期)
- 对熟透的 stdlib / 常见 API 也走本 skill,产生大量 findings 噪音

## Verification

Before writing the API call, confirm:
- [ ] Source URL recorded in `.omo/notepads/<plan>/learnings.md`
- [ ] Access date recorded
- [ ] Installed version matches doc version
- [ ] Exact signature quoted from source
- [ ] Behavior for the specific edge case I'm handling is documented

After writing the API call, confirm:
- [ ] Code comment cites source (for non-obvious APIs)
- [ ] Test covers the documented behavior (boundary test)
- [ ] If upgrading: migration guide cited, deprecation warnings handled

## omo Integration

Use librarian/context7 research as the .omo/notepads/<plan>/ handoff, then attach the evidence to the Prometheus plan before `start-work` changes code.
