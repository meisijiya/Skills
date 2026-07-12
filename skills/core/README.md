# Core Skills(必装集 · 6 个)

工作流骨架。所有项目都装。

## 6 个 skill 一览

| Skill | 做什么 |
|---|---|
| [`using-meisijiya-skills`](./using-meisijiya-skills/) | meta dispatcher。每次响应前检查是否要加载其他 skill,初始化 pwf(若未启动) |
| [`spec-driven-development`](./spec-driven-development/) | 写代码前先 spec。IntentGate 驱动:澄清 → 计划 → 设计 → 写测试 |
| [`incremental-implementation`](./incremental-implementation/) | 垂直切片(每片 ≤ 100 行),逐片交付 + 验证 |
| [`test-driven-development`](./test-driven-development/) | red-green-refactor。先红,后绿,后重构 |
| [`debugging-and-error-recovery`](./debugging-and-error-recovery/) | 5 步排错:reproduce → localize → reduce → fix → guard |
| [`source-driven-development`](./source-driven-development/) | 用 context7 / grep_app / websearch 校 API,不用记忆 |

## 为什么必装

| Skill | 缺了的后果 |
|---|---|
| `using-meisijiya-skills` | agent 不知道有 skill 系统 → 不会按 description 匹配调用 → 整套机制失效 |
| `spec-driven-development` | spec 阶段没指引 → agent 跳过澄清 → 实现跑飞 |
| `incremental-implementation` | build 阶段没指引 → 一次写大文件 → 难调试 |
| `test-driven-development` | test 阶段没指引 → 先写代码后补测试(或不测) |
| `debugging-and-error-recovery` | 报错时 agent 随机试 → 浪费时间还可能引入新 bug |
| `source-driven-development` | 用陌生库时凭记忆写 → API 用错、过时 |

## 安装

```bash
npx skills add https://github.com/meisijiya/Skills --from skills/core
```

完整写作规范见 [`skill-anatomy.md`](../../skill-anatomy.md)。