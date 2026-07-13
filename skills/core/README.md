# Core Skills(必装集 · 9 个)

工作流骨架。所有项目都装。

> **v0.4.0 新增** `brainstorming` / `verification-before-completion` / `writing-skills` 三个 **discipline / process 技能**(从 [obra/superpowers](https://github.com/obra/superpowers) 借鉴)。它们是横切性纪律层,不是 opt-in 工具,所以放 `.core/`。

## 9 个 skill 一览

| Skill | 做什么 |
|---|---|
| [`using-meisijiya-skills`](./using-meisijiya-skills/) | meta dispatcher。每次响应前检查是否要加载其他 skill,初始化 pwf(若未启动),协调 omo Sisyphus |
| [`brainstorming`](./brainstorming/) | **HARD-GATE** pre-design 探索:用户没批准设计前不许写代码。一次一个问题,提议 2-3 方案 + 推荐,写设计 doc |
| [`spec-driven-development`](./spec-driven-development/) | 写代码前先 spec。IntentGate 驱动:澄清 → 计划 → 设计 → 写测试 |
| [`incremental-implementation`](./incremental-implementation/) | 垂直切片(每片 ≤ 100 行),逐片交付 + 验证 |
| [`test-driven-development`](./test-driven-development/) | red-green-refactor。先红,后绿,后重构 |
| [`verification-before-completion`](./verification-before-completion/) | **Iron Law**:任何完成声明都要新鲜证据(测试输出、build exit code 等)。IDENTIFY → RUN → READ → VERIFY → THEN claim |
| [`debugging-and-error-recovery`](./debugging-and-error-recovery/) | 5 步排错:reproduce → localize → reduce → fix → guard |
| [`source-driven-development`](./source-driven-development/) | 用 context7 / grep_app / websearch 校 API,不用记忆 |
| [`writing-skills`](./writing-skills/) | meta: 创建 / 编辑 skill 用 TDD-for-docs 流程。也用于"我老做 X,把 X 提炼成 skill" |

## 为什么必装

| Skill | 缺了的后果 |
|---|---|
| `using-meisijiya-skills` | agent 不知道有 skill 系统 → 不会按 description 匹配调用 → 整套机制失效 |
| `brainstorming` | agent 跳过设计直接写代码 → 假设错误,实现跑飞,user 才发现不对 |
| `spec-driven-development` | spec 阶段没指引 → agent 跳过澄清 → 实现跑飞 |
| `incremental-implementation` | build 阶段没指引 → 一次写大文件 → 难调试 |
| `test-driven-development` | test 阶段没指引 → 先写代码后补测试(或不测) |
| `verification-before-completion` | agent 凭印象宣称"done / 通过 / 完成" → 上线后才发现假完成,信任崩溃 |
| `debugging-and-error-recovery` | 报错时 agent 随机试 → 浪费时间还可能引入新 bug |
| `source-driven-development` | 用陌生库时凭记忆写 → API 用错、过时 |
| `writing-skills` | 团队里反复做的流程没人能抽象成可复用 skill → 永远口头传承,新人 onboarding 难 |

## 安装

```bash
npx skills add https://github.com/meisijiya/Skills --from skills/core
```

完整写作规范见 [`skill-anatomy.md`](../../skill-anatomy.md)。