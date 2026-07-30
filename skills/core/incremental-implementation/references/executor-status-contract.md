# Executor Status Contract — 4 态 (§3.7)

executor 跑完 slice **必须**返回 4 态之一,不是 free text:

| Status | Meaning | Controller action |
|---|---|---|
| `DONE` | slice 完成 + 全部测试通过 + commit 落地 | 派 review-slice / 进入下一个 slice |
| `DONE_WITH_CONCERNS` | 完成 + 测试通过,但发现潜在的边缘 case / 设计疑问 | Controller 读 concerns → 决定补 spec / 跳到下个 slice |
| `NEEDS_CONTEXT` | executor 需要超出 brief 的信息(consumes 不够 / produce 缺上下文) | Controller 补 brief → 重派 executor |
| `BLOCKED` | executor 撞到 blocker(dependency 错 / 设计错 / 任务过大) | Controller 评估:补 ctx / 升模型 / 拆任务 / 回到 brainstorming |

**实现**:executor 在 dispatch prompt 里**只能**返回 4 态 + 1 行总结(< 200 字符)。详细 RED/GREEN evidence、commit、concerns 写到 report 文件(`~/.agents/skills/incremental-implementation/scripts/task-brief.sh` 生成 brief,executor 写 report)。

**WHY**(来自 Superpowers 实验):允许 free text status 时,executor 会写"looks good" / "should pass" 等 self-assessment,controller 盲信导致 phantom completion(实测案例:verifier 报告 "tests pass" 但代码是 stub,只有独立 run test 才能抓到)。4 态契约 + 强制 report 文件 + mandatory re-run by reviewer 是反 phantom completion 的核心机制。