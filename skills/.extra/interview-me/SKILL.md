---
name: interview-me
description: "Extracts the user's actual goal through one-question-at-a-time interview, building ~95% confidence before any work begins. Use when the request is underspecified, ambiguous, or when the user explicitly invokes 'interview me' / 'grill me'."
allowed-tools: "Read AskUserQuestion"
---

# interview-me

## Overview

一问一答的需求探查 —— **每次只问一个问题**,直到 ~95% 置信度。批问 5 个问题 = 用户答不全 + 你乱猜 + 返工。一问一答 = 用户聚焦 + 你澄清 + 一次到位。

omo 的 Prometheus 是 interview-mode planner,但**每次只问一个**仍是纪律——多个并行问题让用户疲劳,降低答案质量。

## When to Use

**Use when:**
- 用户请求模糊("帮我做个 X")
- 多个合理解释,选哪个影响很大
- 用户说"interview me" / "grill me" / "你想清楚再问"
- 决策不可逆(选型、架构、API 设计)
- 时间紧但方向不能错

**NOT for:**
- 已经清晰的请求(直接 spec-driven-development)
- 已知 trivial 改动
- 用户明确说"先随便做做"
- 紧急 hotfix(时间是关键约束)

## Process

### 1. Form a hypothesis

Before asking, state to yourself: "我猜用户其实想做的是 X,对吗?" The hypothesis sharpens the question.

### 2. Ask ONE question

Use the AskUserQuestion tool (or its equivalent) with exactly **one** question. The question must:
- Be answerable in 1-3 sentences
- Have 2-4 mutually exclusive options (no "other" trap)
- Reveal the most consequential unknown
- Not depend on the answer to a question you haven't asked yet

### 3. Update hypothesis

Based on the answer, update your model. If still < 95% confident, identify the next most consequential unknown.

### 4. Loop until ≥ 95% confident

3-7 questions is typical. > 10 questions means you should have used `spec-driven-development` instead — break it down.

### 5. Confirm before proceeding

When you reach ~95%, summarize your understanding in 2-3 sentences and ask: "我理解的对吗?" If yes, proceed.

## Question Quality Rules

| Don't ask | Ask instead |
|---|---|
| "你想要什么样的 UI?" | "主色调用 [冷色调 / 暖色调 / 中性]?" |
| "需要支持哪些功能?" | "MVP 必含: [A / A+B / A+B+C]?" |
| "你想要什么样的 API?" | "API 风格: [REST / GraphQL / RPC]?" |
| "你的目标用户是谁?" | "主要给 [开发者 / 终端用户 / 内部团队] 用?" |

**Always 2-4 mutually exclusive options.** Never open-ended.

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "用户忙,我替他决定" | 用户替他决定 = 你猜 = 返工。问 1 分钟省 1 小时。 |
| "我已经问了 5 个,够了" | 5 个没问到 95% 就是不够。继续问,直到收敛。 |
| "用户答得模糊,我多问几个细节" | 答案模糊 = 问题太宽。换更具体的选项。 |
| "并排问 3 个省时间" | 并排问 = 用户答最不重要的那个 = 你最想知道的反而没答。 |
| "我已经知道答案了,只是确认" | 如果已经知道,不用问。问 = 真的不知道,且后果重要。 |

## Red Flags

- 一轮问 2+ 个问题
- 选项不是互斥的
- 答案模糊就跳过继续
- 问完不总结就动手
- 问超过 10 个问题(改用 spec)
- 用 open-ended 问题("你想要什么样的 X?")

## Verification

Before proceeding to work, confirm:
- [ ] Asked 3-7 questions (not 1, not 10+)
- [ ] All questions one-at-a-time
- [ ] All questions have 2-4 mutually exclusive options
- [ ] Summarized understanding back to user
- [ ] User confirmed: "对 / OK / 干"
- [ ] Wrote summary to `progress.md` so post-compaction agent has context

## pwf Integration

Maps to `task_plan.md` **Phase 0: Intake**. The Q&A summary goes in `progress.md`, NOT `task_plan.md` — interview answers are conversational, not attestation-locked.

```markdown
### Phase 0: Intake
- Q1: <question> → <answer>
- Q2: <question> → <answer>
- ...
- Understanding: <2-3 sentence summary>
- User confirmed: yes
```

See [pwf-integration.md](../../pwf-integration.md).