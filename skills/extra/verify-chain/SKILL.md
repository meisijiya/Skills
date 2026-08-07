---
name: verify-chain
description: "Fact-checks a written IT article against authoritative web sources via Critic→Verifier→Repairer pipeline (Verifier subagents run in parallel). Use when user finishes an IT article, mentions '/verify-chain' / '/verify' / '验证链', or asks 'is this article accurate' before publishing."
allowed-tools: "Read Write Edit Bash Glob Grep WebFetch WebSearch"
---

# verify-chain

## Overview

写完一篇技术文章后，让 AI 帮你核查事实。一篇文章里 10-20 个关键断言，每个断言由独立的联网核查员验证，发现问题自动修复。

**三角色流水线**：**Critic**（提取断言）→ **Verifier × N**（并行联网核查，每个独立 context）→ **Repairer**（最小化修复）。

**为什么需要 web 联网核查**：模型的训练数据有截止时间，且对版本号、命令参数、API 行为等"硬事实"容易给出看起来合理但实际错误的答案。Verifier 必须基于**联网搜索到的权威来源**做核查，不能仅凭模型内置知识。

**核心约束**：三个角色的 context 严格隔离 —— Critic 不评判答案、Verifier 不看 Critic 的偏见、Repairer 不质疑核查结论。这条约束是流水线可信度的基础，**任何破坏 context 隔离的"优化"都会让整个流水线失效**。

## When to Use

**Use when:** (软触发 — 以下是典型场景，AI 按 description 匹配自决)
- 写完一篇 IT 技术文章（K8s、Docker、Linux、编程语言、架构、DevOps 等）
- 用户说"验证这篇文章"/"核查一下"/"帮我审稿"/"check 文章"/"verify article"
- 用户提 `/verify` 或 `/verify-chain` 或 `验证链`
- 写完文章后用户主动问"要不要验证一下"
- 收到一篇文章 + 用户给具体关注点（如"重点检查命令参数"）

**4 种执行模式**：

| 模式 | 触发 | 行为 |
|---|---|---|
| 全自动 | `/verify-chain` 或说"核查这篇文章" | Critic → Verifier × N → Repairer → 报告，一气呵成 |
| 先审再改 | "先审再改，验证文章" | Verifier 阶段完成后暂停，展示核查结果让用户审核，再决定是否进入 Repairer |
| 只查不改 | "只查不改，验证文章" | 跳过 Repairer，只输出核查报告 |
| 重点检查 | "重点检查命令参数，验证文章" | 把用户指定的关注点传入 Critic，影响断言优先级排序 |

**NOT for:** (场景描述 —— 具体用哪个 skill 由 description 匹配决定,不硬指)
- 纯理论 / 学术论文（需同行评审，AI 无法替代）
- 非技术类内容（散文、小说、新闻评论）
- 纯个人经验分享（"我在项目中遇到的一个坑" —— 个人经历无法核查）
- 代码 bug 调试（去 debugging-and-error-recovery）
- 写新文章（去 brainstorming）
- 校对语法 / 拼写（本 skill 聚焦事实核查，不做语言校对）

## Process

### Phase 1: Critic — 断言提取

调用 [`prompts/critic.md`](~/.agents/skills/verify-chain/prompts/critic.md) 作为 Critic 的 system prompt，传入完整文章 markdown。

**串行执行**（不是 subagent）。Critic 在主上下文里跑，输出 10-20 个断言。

每个断言的结构：
```
## 断言 #N
- 原文摘录: > <从文章直接引用的原句>
- 类别: Fact | Version | CommandConfig | BestPractice | Claim | Gap
- 核查问题: <一句精确的、可直接验证的问题>
- 建议核查路径: <官方文档 URL 片段 / GitHub 仓库 / 搜索关键词 / API reference 入口>
```

**断言数量下限**：少于 5 个 → 重新执行一次 Critic，明确要求更仔细审查（"宁可输出 8 个高质量问题，不要 20 个凑数的问题"）。少于 5 个意味着 Critic 没充分提取。

### Phase 2: Verifier × N — 并行联网核查

对**每个断言**启动一个**独立的 Verifier subagent**（OMO `sisyphus-junior` 或 `librarian`，不要用不存在的 `general` agent）：

- 每个 subagent 的 system prompt = [`prompts/verifier.md`](~/.agents/skills/verify-chain/prompts/verifier.md)
- 每个 subagent **只携带它负责的那一个断言**（编号 + 原文摘录 + 类别 + 核查问题 + 建议核查路径）
- **禁止**把 Critic 的输出、原文全文、其他断言传递给 Verifier（context 隔离硬约束）
- 每个 Verifier 必须**独立**执行 WebSearch + WebFetch 联网核查
- **不能**仅凭模型内置知识给结论（除非前 4 级来源都搜不到，标注 ❓）

**默认并行启动全部 Verifier**。断言 > 15 时分批（每批 10 个），避免 token rate limit。

**权威来源优先级**（来源 Verifier 必须遵守）：
1. 项目官方文档 / 官方网站（kubernetes.io、docs.docker.com、nodejs.org/docs 等）
2. GitHub 官方仓库源码（Release Notes、CHANGELOG、官方 Issue 中维护者回复）
3. 权威技术站点（Wikipedia、ArchWiki、MDN Web Docs、IETF RFC）
4. 高质量社区讨论（Stack Overflow >50 票、GitHub Issue 社区共识）—— **仅作交叉参考**
5. 模型内置知识 —— **仅在前 4 项都搜不到时使用，并显式标注**

**绝对禁止引用的来源**（Verifier 命中即跳过）：
- CSDN、掘金、博客园、51CTO、摩天轮
- 任何 `.cn` 域名技术博客 / 论坛（官方 `.cn` 域名如 cncf.cn 除外）
- 任何个人博客（Medium 个人、dev.to、自建博客） —— 除非是项目维护者官方博客

**核查输出**（每个 Verifier 必填）：
```
## 核查结果 #N
- 断言: [原文摘录]
- 准确性: ✅ 准确 | ⚠️ 不完整 | ❌ 错误 | ❓ 无法确定
- 时效性: ✅ 当前有效 | ⚠️ 已过时 | ➖ 无关时效
- 完整性: ✅ 完整 | ⚠️ 遗漏关键信息
- 综合结论: ✅ | ⚠️ | ❌ | ❓
- 问题说明: [一句话说明问题所在;若 ✅ 则写"经核查与官方文档一致"]
- 修正建议: [若有问题则给精确表述;若 ✅ 则写"无需修改"]
- 来源: [URL 或来源描述,如 "kubernetes.io/docs/... (v1.35)"]
```

### Phase 3: Repairer — 自动修复

调用 [`prompts/repairer.md`](~/.agents/skills/verify-chain/prompts/repairer.md) 作为 Repairer 的 system prompt，传入：
- 原始文章全文
- 所有 Verifier 的核查结果

**输入筛选（硬约束）**：**只传 ⚠️ / ❌ / ❓ 的核查结果**，**绝对禁止把 ✅ 一并传入**。把 ✅ 传进去会导致 Repairer 误以为"全部都要审"，反而可能改坏已正确的内容。

Repairer 按修复策略表执行：

| 核查结论 | 修复策略 |
|---|---|
| ❌ 错误 | 用修正建议替换错误表述 |
| ⚠️ 不完整 | 在原文自然补充缺失信息（不单独写"注意"callout） |
| ❓ 无法确定 | 嵌入 `[!待人工确认]` Markdown blockquote |
| ✅ 准确 | **不做任何修改**（这条不存在修复策略，因为 ✅ 不进 Repairer） |

过时信息处理：断言在引用版本成立但最新版本已变 → 不改原文，段落后加 `[!版本更新]` blockquote。

### Phase 4: 报告

向用户展示：

1. **核查摘要**：
   - 总共核查断言数 N
   - ✅ 准确：X
   - ⚠️ 不完整：Y
   - ❌ 错误：Z
   - ❓ 无法确定：W
2. **修复清单**：哪些问题已自动修复（含修复后位置）
3. **待人工确认项**：❓ 无法确定的内容
4. **输出文件**（项目级 audit log,git tracked,在 `docs/verification/` 下）：

   **`<article-slug>` 派生规则**:从用户传入的 article 文件路径取 basename,strip `.md`/`.markdown` 后缀,strip 路径前缀,转 kebab-case,匹配 `^[a-z0-9][a-z0-9-]{0,39}$`(与 brainstorming 的 plan-slug regex 对齐);不合规则退化为 `verify-YYYYMMDDTHHMMSSZ`(atomic timestamp,**无需计数**;同日多次 fallback 概率极低,真撞了让下面的碰撞 3 选项兜住)。例:`docs/articles/kubernetes-networking.md` → slug=`kubernetes-networking`;`./foo/Bar.md` → slug=`bar`。

   - `docs/verification/<article-slug>/article-verified.md` —— 修复后文章
   - `docs/verification/<article-slug>/verification-report.md` —— 完整核查报告（含所有断言 + 核查结论 + 来源）

   两个文件**必须带 YAML frontmatter**(让 `grep -l` 能跨多篇文章定位单次核查结果):

   **article-verified.md 的 frontmatter 模板**:

   ```yaml
   ---
   article: <article-slug>
   verified_at: <ISO-8601 UTC>
   verdict: pass
   ---
   ```

   `verdict` 取值:`pass`(全部 ✅)/ `warn`(含 ⚠️)/ `fail`(含 ❌)/ `uncertain`(含 ❓)。

   **verification-report.md 的 frontmatter 模板**:

   ```yaml
   ---
   article: <article-slug>
   verified_at: <ISO-8601 UTC>
   claims_total: 0
   claims_pass: 0
   claims_warn: 0
   claims_fail: 0
   claims_uncertain: 0
   ---
   ```

   5 个 `claims_*` 字段必须填整数(0 表示无该类断言),`claims_total = claims_pass + claims_warn + claims_fail + claims_uncertain`。

   **碰撞语义**:`docs/verification/<article-slug>/` 子目录**已存在** → 三选项让用户决策(非默默覆盖):
   - **覆盖**:删除旧版本后再写本次(本次 `verified_at` 成为单一记录)
   - **保留旧版 + 写新版本**:把旧目录改名为 `docs/verification/<article-slug>-<ISO日期前 8 位>/`,作为历史快照保留;本次目录用 `<article-slug>/`(此选项让本目录的 git diff 包含两次完整核查,审计 trail 更完整,**默认推荐**)
   - **保留旧版跳过本次**:本次 verify-chain 退化为只读模式,不写任何文件(适合用户只想看核查结果但不要 patch)

   `docs/verification/` 父目录在用户项目根（CWD）下首次创建；若已存在 `docs/verification/<article-slug>/` 子目录，按上述语义处理。

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "Verifier 直接用模型内置知识更快" | 内置知识有截止时间 + 容易编造命令参数;本 skill 的核心价值就是联网核查 |
| "断言数太多，并行启动会爆 token" | 超过 15 个时分批;分批是为了 rate limit,不是放弃并行 |
| "Repairer 把 ✅ 一并传入可以再检查一遍" | ✅ 是已确认正确的断言,再"检查"只会引入新错误;硬约束必须筛掉 |
| "Verifier 可以看 Critic 的输出更好理解上下文" | Critic 的判断可能带偏见,会污染 Verifier 的独立性;context 隔离是流水线可信度的基础 |
| "用户没指定模式，默认全自动就行" | 默认全自动 OK,但若用户明确说"先审再改"/"只查不改",严格按用户指示执行 |
| "文章太短不用走完整流程" | 即使 5 段文章也有 5+ 个断言可提取;流水线是统一接口,不分长短 |
| "可以省略修复步骤直接给报告" | 模式"只查不改"才省略;默认全自动必须包含修复 |
| "输出到 docs/verification/ 麻烦，直接放 CWD 根" | 不再允许。`docs/verification/<article-slug>/` 是两轴原则下唯一合规的项目级 audit log 落点；除非用户主动用 `<article-slug>` 派生规则特例（比如 `.verification/` 单目录变 `docs/verification/<slug>/` 子目录），否则切到新路径是默认行为，不需用户授权 |

## Red Flags

- Critic 输出断言数 < 5 但直接进入 Phase 2（提取不足，遗漏会扩大核查盲区）
- Verifier subagent 携带 Critic 完整输出 / 原文全文 / 其他断言（破坏 context 隔离）
- Verifier 仅凭模型内置知识给结论（无 URL 来源标注）
- Verifier 引用 CSDN / 掘金 / 个人博客作为主要来源（违反来源优先级）
- Repairer 输入含 ✅ 断言（硬约束违反）
- Repairer 改写 ✅ 断言的措辞（最小改动原则违反）
- 输出文件直接覆盖 `docs/verification/<article-slug>/` 而不提示用户（git tracked 目录里被默默覆盖会留下可疑的丢失 commit,丢失用户既有审计历史）
- 跳过 `WebSearch` / `WebFetch` 工具就用本 skill（等于让 Verifier 盲猜）

## Verification

完成本 skill 后确认:

- [ ] Critic 输出了 ≥ 5 个断言（且按价值排序）
- [ ] 每个断言有独立的 Verifier subagent（context 隔离）
- [ ] 每个 Verifier 的核查结果带 ≥ 1 个权威来源 URL
- [ ] 综合结论分布合理：✅ / ⚠️ / ❌ / ❓ 四类都有合理占比（全部 ✅ 通常意味着核查太宽松）
- [ ] Repairer 输入只含 ⚠️ / ❌ / ❓（无 ✅）
- [ ] 修复后文章保持原作者语气（diff 检验：未修改段落应与原文完全一致）
   - [ ] `docs/verification/<article-slug>/article-verified.md` 存在（含 `article` / `verified_at` / `verdict` frontmatter）
   - [ ] `docs/verification/<article-slug>/verification-report.md` 存在（含 `article` / `verified_at` / `claims_total` / 5 个分布计数 frontmatter）
- [ ] 若模式为"先审再改"或"只查不改"，Phase 3 / 4 已按模式跳过

## omo Integration

Track Critic/Verifier/Repairer tasks in OMO, store sources and results in the notepad/evidence ledger, and use `review-work` for publication readiness.
## Related Skills

- 完成门：检查事实类已完成：[`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md) —— 编程任务的 Iron Law，本 skill 是写作任务的对应
- 写作前的设计探索：[`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) —— 写文章前的"该不该写 + 写什么"对齐
- 创建/编辑本类 skill：[`writing-skills`](~/.agents/skills/writing-skills/SKILL.md) —— 用 TDD-for-docs 流程
