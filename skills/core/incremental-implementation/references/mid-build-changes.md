# Mid-build Requirement Changes (§9)

需求进入实施阶段后用户说"改成 X" / "其实应该是 Y" / "再加一条 Z"。**禁止假装没听见,继续按 Spec 写** —— 这等于把 Spec 与代码漂移、attest 失真、后续 review-work 必红的循环里。

## 9.1 Classify the change (5 个类型 → 5 个路由)

| 改动类型 | 例 | 路由 | 副作用 |
|---|---|---|---|
| **Cosmetic** | "字段叫 `name` 改成 `fullName`" / "措辞 / 边界值调整" | 只改 Phase 1 文字;不 amend Spec、不动 slice | 无 |
| **Implementation detail (HOW)** | 换库 / 换算法 / 调实现顺序 | 不动 Spec;改既有 slice 的 `verify` 命令或加新 slice | slice 表更新;**不改** `blockedBy` 拓扑 |
| **Data-shape / API contract (WHAT)** | 加字段 / 改 schema / 改 endpoint 签名 | **重入 Phase 1 Spec**;amend + 重新跑 Momus 拿 `[OKAY]`;旧 slice 标 `superseded` 由新 slice 替换 | 旧 slice 走 `git revert`(项目 git policy 下)+ 标 `status=superseded` 并填 `superseded_by`;新 slice 入 frontier |
| **Feature re-scope (WHY)** | 用户说"其实我们要做的不是 X,是 Y" | **重入 Phase 0 Brainstorming**;只保留 Phase 0 Design 的设计骨架;再走 § Phase 1 Spec 重写 | 大部分已有 slice 走 `status=superseded` 或 `deprecated`;新设计产出新 Phase 1 Spec |
| **Pure addition (orthogonal)** | "再加一个 Y,不影响已存在的 X" | append 到 Phase 1 Spec(amend + Momus);**仅在 frontier 末尾追加新 slice**,旧 slice 不动 | frontier 增长;不改既有 `blockedBy` 拓扑 |

## 9.2 Process for any requirement change

1. **Detect**:用户或 review-work 🔴 报告"需求 / 验收标准变了"。
2. **Classify**:用 § 9.1 的 5 档表对位(只取一行,不许混)。
3. **Halt in-flight slice**:`in_progress` 的 slice 若被 impacted,先停下,不要再 commit,记录当前进度 `.omo/notepads/<plan-name>/issues.md` 加 `[halt] <slice-id> reason:<一句话>`。
4. **Route to the right phase**:
   - Cosmetic / HOW → 不出 Phase 3,仅修改既有 row 或 append row
   - **Data-shape / Pure addition →** invoke [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md) Step 5.5 Amend + re-attest
   - **WHY changed →** invoke [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) Phase 0 重新对齐,完成后再走 Phase 1 amend
5. **Deprecate or supersede impacted slices**:用 § 9.3 的状态机更新 `status` + `superseded_by`;OMO `atlas` 自动把它们从 frontier 排除。
6. **Log amendment**:`.omo/notepads/<plan-name>/decisions.md` append 一段(用 `Edit`,不要 `Write` —— `notepad-write-guard` hook 强制 append-only):
   ```
   [amend] <type> at <ts> by <actor> reason:<一句话>
        sections:   <Phase-1.Section-list, e.g. Acceptance / Test Strategy>
        momus-verdict: <OKAY | REJECT — issues>
        affected:   <slice-id-1, slice-id-2...>
        action:     <deprecate / supersede / append / modify>
        spec:       .omo/plans/<slug>.md#Phase-1.Section
   ```
   这是事后 audit"为什么 X 被作废"的唯一线索。`sections` + `momus-verdict` 是必备字段:前者定位改动位置,后者证明 amend 经过了 Momus 评审(防止"amend 后忘了评审")。
7. **Resume**:**只在 Momus 通过新 plan + 新 slice 表上**继续 frontier work。任何 `in_progress` 的旧 slice 必须 halt 并 supersede,绝不允许续写半成品。

## 9.3 Slice status machine(含 halted 路径)

```
pending  ──► in_progress ──► complete
                │                  │
                │ halted           ├──► deprecated  (需求改但旧实现保留;git 不删)
                ▼                  │
            [halt]+superseded      └──► superseded  (需求改,新 slice 接替;必填 superseded_by)
               (halt 中途
                amendment 是合法
                路径,见 § 9.2 step 3 + 5)
```

**写代码纪律**:

- 禁止 `deprecated` ↔ `superseded` 的来回切换 — deprecated 是"被废弃保留",superseded 是"被替换",方向感不一样。
- 禁止无 `superseded_by` 的 `superseded` slice。
- 旧 slice 即使 `deprecated`,其 `verify` 命令仍应在 CI 通过 = "没坏但不再演化"。如果 verify 失败,先解 verify 再标 deprecated。
- `in_progress` slice 在 § 9.2 step 3 halt 后,只能:
  - 进 `superseded`(若新 slice 接替) — **必须**用 § 9.2 step 3 + step 5 的 [halt]+[amend] 协议,不能直接跳。
  - 退回 `pending`(若变更撤回) — 但这等于放弃已做的工作,通常由 OMO `git stash` 配合。
  - 不要从 `in_progress` 直接进 `complete`(已 halt 的不算完成)。
- 任何 status 变更必须 append 到 `.omo/notepads/<plan-name>/` 的 `[amend]` 段。