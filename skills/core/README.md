# Core Skills(必装集 · 8 个)

工作流骨架。所有项目都装。

## 8 个 skill 一览

| Skill | 做什么 |
|---|---|
| [`using-meisijiya-skills`](./using-meisijiya-skills/) | meta dispatcher。每次响应前检查是否要加载其他 skill,协调 omo Sisyphus + IntentGate routing |
| [`brainstorming`](./brainstorming/) | **HARD-GATE** pre-design 探索:用户没批准设计前不许写代码。一次一个问题 + 2-3 方案 + 推荐 |
| [`spec-driven-development`](./spec-driven-development/) | 写代码前先 spec。Spec 唯一落点为 omo plan (Prometheus / `.omo/plans/*.md`);诚实标注 OpenCode Tier 3 限制 |
| [`incremental-implementation`](./incremental-implementation/) | 垂直切片(每片 ≤ 100 行),逐片交付 + 验证。Slice 依赖/HITL-AFK 元数据,桥接 OMO `review-work` |
| [`test-driven-development`](./test-driven-development/) | red-green-refactor。先红,后绿,后重构 |
| [`verification-before-completion`](./verification-before-completion/) | **Iron Law**:任何完成声明都要新鲜证据。两段验证: in-session self-check + OMO `review-work`(新上下文审查)+ `visual-qa`(人工 QA 闸门) |
| [`debugging-and-error-recovery`](./debugging-and-error-recovery/) | 5 步排错:reproduce → localize → reduce → fix → guard |
| [`source-driven-development`](./source-driven-development/) | 用 context7 / grep_app / websearch 校 API,不用记忆。收紧触发条件(只针对陌生库 / 版本敏感 / 调试诡异行为) |

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

## 安装

```bash
npx skills add https://github.com/meisijiya/Skills --from skills/core
```

完整写作规范见 [`skill-anatomy.md`](../../skill-anatomy.md)。