---
name: verify-chain
description: "Role-adversarial tech article verification: Critic extracts claims, parallel Verifier subagents web-check, Repairer auto-fixes. Use after writing IT articles."
license: MIT
---

# 验证链(Verify Chain)

## 触发条件

当用户明确表示以下意图时调用此技能:
- "验证这篇文章"、"核查文章内容"、"check 文章"、"verify article"
- "检查有没有错误"、"帮我审稿"
- 写完一篇 IT 技术文章后主动询问是否需要验证
- 用户问"这篇有没有问题"、"这数据对吗"

## 适用场景

- IT 技术文章(K8s、Docker、Linux、编程语言、架构设计、DevOps 等)
- 技术教程、操作指南、最佳实践文档
- 技术博客、技术对比评测

## 不适用场景

- 纯理论/学术论文(需要专家同行评审,AI 无法替代)
- 非技术类内容(散文、小说、新闻评论)
- 纯个人经验分享("我在项目中遇到的一个坑"——个人经历无法核查)

## 执行流程

### 阶段 1:Critic — 断言提取

```
使用 Critic System Prompt(prompts/critic.md)
输入:完整文章 Markdown
输出:10-20 个关键断言,按 6 类标注
```

**执行方式**:串行。这是整个流程的入口,必须先完成。

**输出解析**:从 Critic 的输出中解析出每个断言的结构化数据(编号、原文摘录、类别、核查问题、建议核查路径)。

如果 Critic 返回的断言数量 < 5,重新执行一次 Critic,要求它更仔细地审查。

### 阶段 2:Verifier — 并行交叉验证

```
使用 Verifier System Prompt(prompts/verifier.md)
对每个断言启动一个独立 subagent
Subagent 需携带联网搜索能力
```

**执行方式**:所有 Verifier subagents 并行启动。

**关键要求**:
- 每个 subagent 通过 `task(subagent_type="explore" | "general-purpose", run_in_background=true)` 启动,使用**独立的对话上下文**
- 每个 subagent 携带 Verifier System Prompt + 单个断言的数据
- Subagent 需要联网搜索权限:`websearch_web_search_exa` + `webfetch` 工具
- 禁止 Critic 的输出和原文全文进入 Verifier 上下文(仅携带其负责的单个断言)

**并发控制**:
- 默认同时启动全部 subagents(`run_in_background=true` 后用 `background_output(task_id="bg_...")` 收集)
- 如果断言数量较多(>15),可分批启动(每批 10 个)

**输出收集**:等待所有 subagents 完成后,按编号收集核查结果。

### 阶段 3:Repairer — 自动修复

```
使用 Repairer System Prompt(prompts/repairer.md)
输入:原始文章全文 + 所有核查结果
输出:修复报告 + 修复后文章
```

**执行方式**:串行。必须在所有 Verifier 完成后执行。

**筛选输入**:只将有问题的核查结果(⚠️ 不完整 / ❌ 错误 / ❓ 无法确定)传给 Repairer。✅ 准确的断言不需要修复。

### 阶段 4:报告

向用户展示:

1. **核查摘要**:
   - 总共验证了 N 个断言
   - ✅ 准确:X 个
   - ⚠️ 不完整:Y 个
   - ❌ 错误:Z 个
   - ❓ 无法确定:W 个

2. **修复清单**:哪些问题已自动修复

3. **待人工确认项**:❓ 无法确定的内容

4. **输出文件**:
   - `article-verified.md`:修复后的文章
   - `verification-report.md`:完整核查报告(含所有断言 + 核查结论 + 来源)

## 用户交互规则

- **默认全自动执行**:Critic → Verifier × N → Repairer → 报告,中间不询问用户
- **如果用户说"先审再改"**:阶段 2 完成后暂停,展示核查结果让用户审核,由用户决定哪些要修复,再进入阶段 3
- **如果用户说"只查不改"**:跳过阶段 3,只输出核查报告
- **如果用户标注了特定关注点**(如"重点检查命令参数"):在阶段 1 中将用户指示传递给 Critic

## 核心设计原则

1. **角色分离**:Critic 只提问不回答,Verifier 只核查不修改,Repairer 只修复不质疑
2. **上下文隔离**:每个 Verifier 独立上下文,避免 Critic 的偏见"传染"给 Verifier
3. **联网优先**:所有核查必须基于联网搜索结果,不得仅凭模型内置知识
4. **权威来源**:严格区分可信来源和内容农场,宁缺毋滥
5. **最小修复**:只改有问题的部分,保持原文风格

## 参考

- `prompts/critic.md` — Critic 系统提示词
- `prompts/verifier.md` — Verifier 系统提示词(独立事实核查员)
- `prompts/repairer.md` — Repairer 系统提示词(技术编辑)
- `references/verification-report-example.md` — Spring Boot 4 文章的完整验证报告案例(20 个断言, 19 个被自动修复)