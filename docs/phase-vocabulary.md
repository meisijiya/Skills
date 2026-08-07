# Phase Vocabulary (权威 phase 词汇表)

> **Authoritative source for project-lifecycle phase numbers used by all meisijiya skills.**
>
> 任何 skill / doc / plan 文件引用 `Phase N` 时,必须以本表为准。
>
> 维护:Phase 词汇变更需要先在本表登记,再写 SKILL.md / plan / spec;反向操作算 doc drift。

---

## 1. 文档定位(scope)

本文档定义的是 **项目生命周期 phase**(写进 `.omo/plans/<slug>.md` 的 plan 段落编号),**不是**:

- **skill 链路 phase**(见 [`process-chains.md`](../skills/core/using-meisijiya-skills/references/process-chains.md) 的 12 条 chain)
- **plugin 分组 phase**(core / security / cicd / observability / meta / domain / frontend)
- **skill 内部 phase**(production-incident-playbook 的 Detect/Triage/Mitigate/Resolve/Communicate/Close;verify-chain 的 Critic/Verifier/Repairer/Report;closed-loop-delivery 的 5-Gate)

后三者属于各 skill 自己的方法论,不应与项目生命周期 phase 编号混淆。

---

## 2. 项目生命周期 phase 表

| Phase | 名称 | 定义(完成态) | 触发 / 写入 skill | 是否主流 | 备注 |
|---|---|---|---|---|---|
| **0** | Design | 用户批准的设计意图,作为 spec 的输入 | [`brainstorming`](../skills/core/brainstorming/SKILL.md)(单会话)或 [`wayfinder`](../skills/extra/wayfinder/SKILL.md) close(多会话) | ✅ 主流 | wayfinder close 时也会写入此段;同一 slot 二选一 |
| **1** | Spec | 含 goal / scope / acceptance criteria / risks 的 PRD | [`spec-driven-development`](../skills/core/spec-driven-development/SKILL.md) | ✅ 主流 | 唯一审批门,attestation 后才能进 1.25 / 1.5 / 2 / 3 |
| **1.2** | Prototype Resolve | `[PROTO-RESOLVE]` 标记全部 resolved,choice 落 `decisions.md` | [`prototype`](../skills/extra/prototype/SKILL.md) | ⚪ 可选 | 仅当 Phase 1 spec 含有 `[PROTO-RESOLVE]` 标记时启用;缺此 phase 不阻塞主流程 |
| **1.25** | Contract Review | open-world 契约 / state / timing / concurrency / boundary / reversibility 风险审查完成 | [`contract-strengthening`](../skills/extra/contract-strengthening/SKILL.md) | ⚪ 可选 extra | 在 attested Spec 之后、1.5/2/3 之前;**missing extra 不阻塞核心流程**;external verifier 永不自动安装 |
| **1.5** | UI Design Spec | 项目级 UI/UX 设计规范(色彩 / 字体 / 组件规范 / anti-pattern)落 `docs/design-spec/<plan-slug>/spec.md`(git tracked) | [`designer-handoff`](../skills/extra/designer-handoff/SKILL.md) | ⚪ 可选 | 仅当 Phase 1 spec 含 UI surface 时启用;visual-engineering category 接手 |
| **2** | Research | 必要的外部权威信息(官方文档 / RFC / OSS 源码)被引入 plan,缺口被关闭 | [`source-driven-development`](../skills/core/source-driven-development/SKILL.md) + [`research`](../skills/extra/research/SKILL.md) | ⚪ 可选 | 仅当 Phase 1 spec 含 "需权威信息" 信号时启用;走 OMO `librarian` |
| **3** | Slices | 验收为 ticket DAG 的可执行切片,首条 ticket 为 Tracer Bullet | [`incremental-implementation`](../skills/core/incremental-implementation/SKILL.md) | ✅ 主流 | Kanban ticket board;blockedBy 构成 executable frontier;atlas 据此排程 |
| **3.5** | Visual / Build Gate | UI 一致性 / 教学风格 / 设计对齐已通过设计闸门 | [`build-gate-visual-review`](../skills/extra/build-gate-visual-review/SKILL.md) | ⚪ 可选,用户明确意图触发 | **不能因为 OMO 计划中存在此 phase 就自动跑**;仅当用户选择 gate 时作为可选记录 |
| **4** | Verification | per-slice TDD + verification-before-completion Stage 1/2 + OMO review-work 5-lane 全 APPROVE | [`test-driven-development`](../skills/core/test-driven-development/SKILL.md) + [`verification-before-completion`](../skills/core/verification-before-completion/SKILL.md) + OMO `review-work` | ✅ 主流 | "DoneClaim" 阶段;`slice-review` 提供 per-slice 轻量审查 |
| **5** | Fix / Mitigation | 已知 error / bug / 防御缺口有 guard test 与根因修复 | [`debugging-and-error-recovery`](../skills/core/debugging-and-error-recovery/SKILL.md) → [`diagnosing-bugs`](../skills/core/diagnosing-bugs/SKILL.md)(若根因非显然) → [`test-driven-development`](../skills/core/test-driven-development/SKILL.md) 写 guard | ⚪ 按需 | 不是计划阶段,是异常分支;`production-incident-playbook` 的 Detect→Triage→Mitigate→Resolve→Communicate→Close 是 skill 内部 phase,**不映射到此编号** |
| **7** | ADR | 不可逆 / 跨时 / 跨团队的架构选型落 `docs/adr/<NNNN>-<slug>.md` | [`documentation-and-adrs`](../skills/extra/documentation-and-adrs/SKILL.md) | ⚠️ **撤出主流程** | 文档明确:`Phase 7 不再是默认必走(已撤出主流程)。只有真的产生"重大架构选型"的 phase 才走本 skill` |

---

## 3. 命名规则与 anti-pattern

### 3.1 主流程编号只能是:0 / 1 / 1.2 / 1.25 / 1.5 / 2 / 3 / 3.5 / 4 / 5 / 7

中间任何空隙(例如 1.3 / 2.5 / 4.5 / 5.1 / 6 / 7.5)都被视为 **doc drift**;`validate-skills.sh` + `check-doc-drift.sh` 应报警。

**例外**:`docs/migrations/pwf-to-omo-native.md` 中存在历史 Phase 1-8 编号 — 这是 PWF 迁移文档的旧编号,**不是当前词汇表的一部分**;在引用时需明确 "pwf-era" 标记。

### 3.2 不要在 SKILL.md 自由发明 phase 编号

如需新 phase:

1. 先在本表登记(`Phase N+0.05` 占位 + 命名 + 定义 + 触发 skill)
2. 经 7-lane review 中的 `a-architecture` lane 审过
3. 再在 SKILL.md 引用

直接写 `## Phase 6: X` 进 SKILL.md 而不更新本表 = 文档漂移。

### 3.3 不要把 skill 内部 phase 写到 plan 文件

`production-incident-playbook` 内部的 Detect/Triage/Mitigate 等不会出现在 `.omo/plans/<slug>.md`;它们是该 skill 的方法论,属于 `## Process` 章节(`### Step 1 / Step 2 / ...`),不是 `## Phase N`。

### 3.4 "Phase 7" 的特殊处理

`documentation-and-adrs` 自身明确:**Phase 7 不再是默认必走**。当某项目真的产生了 ADR-worthy 决策时:

- plan 文件的对应 phase 仍标 "Phase 7"(历史延续)
- 但**不应在 `incremental-implementation` 的 slice 列表里出现 "Phase 7 ADR" 行**,除非显式需要

---

## 4. 与 wayfinder 的关系

| 触发条件 | 入口 skill | 产物 phase |
|---|---|---|
| 单会话能搞定的 design | `brainstorming` | Phase 0 |
| 跨会话才能搞定的 design | `wayfinder`(DAG ticket 图) | close 后生成 Phase 0 |

wayfinder close 前的 ticket resolution 不算 Phase 0;Phase 0 仅在 `.omo/plans/<slug>.md` 出现 `Goal` + `Approach` 段时才算正式存在。

---

## 5. 与 OMO Prometheus 的关系

OMO Prometheus 是 plan 文件的 *作者*,但 **phase 编号约定源自 meisijiya skill 体系**(参考 `docs/migrations/pwf-to-omo-native.md` 第 16-18 行的 brainstoriming/spec/source/incremental/test/debug 对应 Phase 0/1/2/3/4/5)。

**boundary**:

- meisijiya 定义 phase 含义 + 触发 skill
- OMO Prometheus 写 plan 文件 + 调度 atlas 执行
- meisijiya 不编辑 `.omo/plans/<slug>.md` 的 task checkbox(per ADR-0001 §"Decision")
- OMO Prometheus 不定义 phase 含义,只接受 plan 模板

---

## 6. 维护机制

- **修改本文档**:走 brainstorming HARD-GATE(任何 phase 编号 / 含义变更影响 6+ skill)
- **CI 校验**:`scripts/check-doc-drift.sh` 应扫描所有 SKILL.md 的 `Phase N` 引用并与本表对账;新增 phase 但未在本表登记 = 报警
- **撤销流程**:Phase 7 是先例 — 在本文档标 ⚠️ 撤出主流程,保留定义但下游 skill 显式声明不默认走

---

## 7. 一句话总结

> 当前共 **11 个 phase 编号**(0/1/1.2/1.25/1.5/2/3/3.5/4/5/7),其中 5 个主流(0/1/3/4 + 隐式 5/fix)、5 个可选(1.2/1.25/1.5/2/3.5)、1 个撤出主流程(7);任何 SKILL.md 引用 phase 必须先在本表登记,否则视为 doc drift。