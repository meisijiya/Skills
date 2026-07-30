# Rollback Protocol (§10)

Slice 上线后被判定需要回收时(数据丢失 / 安全洞 / correctness regression / 用户主动撤回 / fix-the-fix 反效果),按本协议收尾。

**注意**:rollback 是 § 9 amend 的姐妹协议 —— § 9 处理"需求变了,spec 与 slice 还没坏"(见 [`mid-build-changes.md`](mid-build-changes.md));本协议处理"已落地的 slice 必须撤回"。两者状态机独立,但共用 `.omo/notepads/<plan-name>/` 日志约定。

## 10.1 触发条件

满足下列任一即触发本协议:

1. OMO `review-work` Stage 2 报 **critical severity** `🔴`(数据丢失 / 安全 / 修复引入新 bug)
2. 用户主动说"回滚那一段"
3. [`debugging-and-error-recovery`](../../debugging-and-error-recovery/SKILL.md) Step 4 fix 引入新 regression(reproduce 命令倒过来了)
4. § 9 amend 反向:某个 spec amendment 决定撤回上线分支
5. Pre-merge 检查发现主线 cherry-pick 错位(合并前最后一道关)

## 10.2 协议(必须按顺序)

1. **HALT frontier** — 任何并行 slice 立即停下:`.omo/notepads/<plan-name>/decisions.md` append `[halt] <slice-id> reason:<一句话>`。正在 `in_progress` 的 slice 必须 halt 后才走后续步骤(进 `rolled_back`,不要直接 `complete`)。
2. **选择恢复方式**:
   - `git revert <sha>`(已 commit 但未 publish)
   - `git reset --hard <safe-sha>`(永远仅在 main 之外用)
   - `cherry-pick --abort` 或 `rebase --abort`
   - 删除 worktree 整目录(`git worktree remove`)
3. **更新 slice 状态**:见 § 10.3 状态机新增 6 态 `rolled_back`,必填 `rolled_back_at` / `rolled_back_reason`。
4. **Log `[rollback]`**(必写,模板见 § 10.4,append 到 `.omo/notepads/<plan-name>/decisions.md`)。这是事后 audit "为什么 X 段被回收" 的唯一线索。
5. **(critical severity 必做)** Postmortem — 在 `[rollback]` 行后 append 一句"如何防再次发生"(action item:新增防漏测试 / 新 checklist / 新 spec 段落)。
6. **修 Spec(若根因是 spec 错)**:走 [`spec-driven-development`](../../spec-driven-development/SKILL.md) Step 5.5 amend,re-attest 后再继续。任何"只回退代码不修 Spec"的捷径见 § 10.6 Red Flags。
7. **验证回滚真完成**:`[rollback]` 行写齐 7 个字段 / `verify` 命令重跑且退出 0 / 受影响的 sibling slice `verify` 仍过。

## 10.3 slice 状态机扩展

```
pending  ──► in_progress ──► complete
                │   │              │
                │   │ halted       ├──► deprecated   (留旧不演化)
                │   ▼              │
                │  [halt]          └──► superseded   (被新 slice 接替)
                │   │
                │   └────► rolled_back (post-complete rollback;git history preserved)
                │              ↑
                │              outcome of incidents;详细见 § 10
                ▼
              (rollback 流程见 § 10)
```

**写代码纪律**(rollback 专属):

- 禁止无 `[rollback]` 日志就改 git 历史(`git reset` / `git rebase --interactive`)。
- 禁止 `rolled_back` slice 不填 `rolled_back_at` / `rolled_back_reason`。
- 禁止"只回退代码不回退 spec 假设" —— 若根因是 spec 错,amend 必走。
- `rolled_back` slice 不允许再回 `complete`(除非 amend 一遍后整个 acceptance 重做)。
- 多个 slice 同时被影响的"事件级 rollback":`[rollback]` 里 `affected:` 字段列多个,`postmortem` 写在最后一条。

## 10.4 `[rollback]` 日志模板

```
[rollback] <slice-id | commit-sha> at <ts> by <actor>
     trigger:    <review-work-crit | user-request | fix-the-fix | spec-retro | pre-merge-cherry-pick>
     severity:   <critical | major | minor>
     recovered:  <git-revert <sha> | git-reset <sha> | rebase-abort | worktree-remove | cherry-pick-abort>
     reason:     <一句话 5-whys 第一层>
     affected:   <slice-id-1, slice-id-2...>
     action:     <fix-tests | amend-spec | new-blocking-slice | none-yet>
[postmortem] <一句话如何防再次发生>  ← critical severity 必写
[test-gap]    <新测试名 / 新 checklist / 新 spec 段落>  ← optional
```

## 10.5 Common Rationalizations

| Excuse | Reality |
|---|---|
| "已经 git revert 了,日志可以省" | revert 只是个动作,不是 audit 入口。下次人看到 git log 时,**[rollback]** 是唯一的"为什么这段代码不再有效"说明。无日志 = 历史虚无。 |
| "只是个小 bug,不用 critical 严重度" | 严重度由后果定,不由大小定。"小 bug"如果导致 P95 latency 翻倍 → **major**;导致数据丢失 → **critical**。不分严重度 → § 10.2 step 5 的 postmortem 被跳过,下次同样坑。 |
| "[rollback] 之后再补日志吧,先恢复代码" | 事故发生时补日志最容易遗漏(上下文已切换)。本协议要求 revert 与 log 同步:revert 完立刻写 `.omo/notepads/<plan-name>/`。 |
| "spec 不需要 amend,只是某个 edge case" | 如果触发是 spec 没覆盖到该 edge case,这就是"spec 错",amend 必走。否则下次同一个 edge case 又会出现。 |
| "rolled_back 跟 complete 差不多" | **错**:`rolled_back` 的 slice **不算** shipping 成功的能力,3 个月后看 planner 的人若把它当 `complete` 引用,会引入回归。状态机分清这两态是为了 audit,不是冗余。 |

## 10.6 Red Flags

- `git reset --hard` 在 main 分支上
- `git push --force` 到 main/release
- 在没有 `[rollback]` log 的情况下改了 git history
- "git pull 失败了,直接 reset 到 origin" — 跳过 audit
- `rolled_back` slice 没填 `rolled_back_at` / `rolled_back_reason`
- rollback 后没跑 sibling slice `verify`(确认没有牵连破坏)
- critical rollback 没写 postmortem
- rollback 但没 amend spec(若 spec 是根因之一)