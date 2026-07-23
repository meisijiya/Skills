---
name: security-incident-response
description: "Handles security incidents after detection — breached credentials, exploited CVE, anomalous behavior, leaked secret, ransomware. Use when an actual or suspected breach is discovered, regardless of whether the trigger was a monitoring alert, user report, or third-party CVE disclosure. Under omo, uses security-research mode for post-incident root cause analysis, oracle agent for impact assessment, websearch MCP for CVE disclosures / attack IOCs, review-work skill for post-incident code review."
allowed-tools: "Read Write Edit Bash Glob Grep WebFetch"
---

# security-incident-response

## Overview

**已经发生 / 怀疑发生**安全事件时的标准响应流程。这是 [`security-and-hardening`](~/.agents/skills/security-and-hardening/SKILL.md)（写代码时）和 [`security-devsecops`](~/.agents/skills/security-devsecops/SKILL.md)（部署前）都**不**覆盖的——它们是预防型，本 skill 是事后型。

**重要前提**：即使作为非专业个人开发者，也要假设自己会遭遇安全事件（凭证泄露 / 依赖被植入后门 / 误配置导致数据外泄 / 被钓鱼）。**有响应流程 vs 没有流程**，决定事件是"小事故"还是"灾难"。

**与兄弟 skill 的边界**：

| 阶段 | Skill | 焦点 |
|---|---|---|
| 写代码时 | `security-and-hardening` | input / auth / OWASP / secrets-in-code |
| 写完 → 上线前 | `security-devsecops` | deps / SBOM / rotation / CI/CD / IaC / pre-deploy gate |
| **被攻击 / 怀疑被攻击** | **`security-incident-response`**（本 skill） | detect → triage → contain → eradicate → recover → postmortem |

**OMO 集成**：
- `security-research` mode 跑 post-incident 根因分析（3 hunters + 2 PoC 重新审视代码 + 配置）
- `oracle` agent 决策链（影响评估 / 何时通知用户 / 是否公开）
- `websearch` MCP 查 CVE 公告 / 攻击 IOC（indicator of compromise）
- `context7` MCP 查 incident response 工具文档
- `review-work` skill 跑 post-incident code review

## When to Use

**Use when:**
- 监控告警触发（异常登录 / 异常流量 / 异常 API 调用）
- 用户报告异常（"我的账号被盗了" / "我看到不该看到的数据"）
- 第三方披露 CVE 影响你的依赖（依赖里有 known exploited CVE）
- 凭证泄漏（API key commit 进 public repo / secret manager 被 dump）
- 收到勒索 / 威胁消息
- 发现系统出现未知账号 / 未知进程 / 未知 outbound 连接
- 怀疑被供应链攻击（依赖包可疑 / 拉取数异常）

**NOT for:**（场景描述——具体用哪个 skill 由 description 匹配决定）
- 写代码时的预防 → [`security-and-hardening`](~/.agents/skills/security-and-hardening/SKILL.md)
- 部署前的供应链 → [`security-devsecops`](~/.agents/skills/security-devsecops/SKILL.md)
- 部署后的正常运行监控（无 incident 触发）→ [`observability-and-instrumentation`](~/.agents/skills/observability-and-instrumentation/SKILL.md)
- Bug 调试（非安全相关）→ [`debugging-and-error-recovery`](~/.agents/skills/debugging-and-error-recovery/SKILL.md)

## Process

按 NIST CSF 简化为 6 阶段。**任何阶段跳步骤 = 风险**——例如 Triage 没做就 Eradicate 可能漏掉第二个攻击入口。

### 1. Detect — 识别 incident

**触发源**：
- 监控告警（Sentry / Datadog / SIEM）
- 用户报告（"我账号被盗"）
- 第三方公告（CVE / 供应商通知）
- 自查发现（异常 commit / 异常 outbound traffic）

**第一次动作（无论触发源）**：
1. **记录时间戳**：incident 起点 = 你知道的最早可疑时间（不是发现时间）
2. **冻结证据**：不要立刻修改受影响系统，避免破坏法证（forensic）证据
3. **拉一份独立笔记**：`.omo/incidents/<incident-id>/incident.md`（不写入受害系统的日志，因为日志可能已被攻陷；incident 笔记独立于 `.omo/notepads/<plan>/` 的 per-plan 命名空间，因为 incident 跨 plan）

**不要做**：
- ❌ 不要先发公开声明（信息不完整会失真）
- ❌ 不要先 reset 受影响账户（可能破坏证据链 / 阻止攻击者继续操作帮你定位）
- ❌ 不要重启服务器（丢失内存中证据）

### 2. Triage — 严重度 + 影响范围

**严重度**（按后果分，不由"看起来多大"分）：

| 级别 | 标准 | 例子 |
|---|---|---|
| **Critical** | 数据丢失 / 用户凭证大规模泄漏 / 服务瘫痪 / 资金影响 | DB 全表 dump / admin token 公开 / 持续 ransomware |
| **Major** | 限定范围的数据 / 凭证泄漏 / 服务降级 | 单用户 token 泄漏 / 单 endpoint 数据外泄 / 短时 DDoS |
| **Minor** | 潜在风险但未确认实际影响 / 已知 CVE 但未观察到利用 | CVE 公告但尚未影响 / 可疑登录但未确认成功 |

**影响范围评估**（用 oracle agent 决策）：
- 哪些用户受影响？（用户量 / 用户类型 / 是否含 PII / 是否含支付信息）
- 哪些数据受影响？（type / volume / 是否加密）
- 哪些系统受影响？（isolated 还是横向移动了）
- 攻击者还能访问吗？（active 还是 historical）

**输出**：incident 笔记加严重度 + 影响范围段

### 3. Contain — 止血

**最小权限先动**——只做最小动作切断攻击者访问：

| 情形 | 动作 |
|---|---|
| Credential 泄漏（API key / DB password） | revoke + rotate（不需停服务，但所有调用方立即更新） |
| 单一账号被盗 | 冻结账号 + revoke 所有 session token + force password reset |
| 整个服务被攻陷 | 切流量到 maintenance 页面（不要直接下线，先观察攻击者行为） |
| 勒索软件 | **隔离受感染主机**（断网不断电），不要重启 |
| 数据外泄进行中 | 切断 outbound 网络（防火墙规则 / WAF），保留 log |

**不要做**：
- ❌ 不要直接 patch 漏洞（这是 Eradicate 阶段）
- ❌ 不要通知用户（Triage 完整后再决定）
- ❌ 不要恢复数据（这是 Recover 阶段）

### 4. Eradicate — 根除

清理攻击者留下的所有痕迹：

| 痕迹 | 处理 |
|---|---|
| 后门 / 新增账号 / 修改的 config | 删除 + revert 到已知干净的 commit |
| 凭据（即使 rotate 过） | 全部重置，包括 backup 系统的 |
| 持久化机制（cron / systemd / SSH key） | 全盘审计清除 |
| 漏洞本身 | patch / upgrade / 替换依赖 |
| 受感染的 binary / container image | rebuild from clean source + verify checksum |

**OMO 增强**：用 `security-research` mode 跑 post-incident root cause 分析：
```
/security-research --scope "post-incident on <incident-id>"
```
3 hunters 各审一个 attack surface；2 PoC engineers 写 working exploit 验证漏洞已彻底修补。

### 5. Recover — 恢复

从干净 backup 恢复 / 重新部署：

- [ ] **从已知干净的 backup / commit 恢复**，不是从被攻陷的 snapshot
- [ ] **更换所有凭据**（不只 rotate，**全部** 换新）
- [ ] **重新部署** 服务（用干净 image + 干净 config）
- [ ] **加强监控**（本次 attack vector 加 specific alert）
- [ ] **验证** 服务恢复正常 + 没有残留

**Communicate**（按法律 / 用户合同要求）：
- 用户通知：按 GDPR / CCPA / 行业法规时限（如 GDPR 72 小时）
- 监管报告：按合规框架
- 公开声明：critical / major 通常需要；minor 不一定

### 6. Postmortem — 复盘

**blameless postmortem**：目的是学习，不是追责。

**模板**（写入 `.omo/incidents/<incident-id>/postmortem.md`）：

```markdown
# Postmortem — <incident-id>

## Summary
- 触发: <一句话>
- 严重度: Critical / Major / Minor
- 影响范围: <users / data / systems>
- 检测时间 / 止血时间 / 根除时间 / 恢复时间
- 总时长: <duration>

## Timeline
- <t0>: <可疑起点>
- <t1>: <detect>
- <t2>: <triage done>
- <t3>: <contain done>
- <t4>: <eradicate done>
- <t5>: <recover done>

## Root cause (5 whys)
1. Why 1:...
2. Why 2:...
3. Why 3:...
4. Why 4:...
5. Why 5: <根本原因>

## Action items
- [ ] 改 spec / 加 checklist
- [ ] 加监控 / alert
- [ ] 加测试
- [ ] 改流程

## Lessons
- <一句话核心学习>
```

**5 whys 是核心**：不停在表层。例如 "credential 泄漏" 不是 root cause；继续问 "为什么 commit 进 public repo" → "因为.env 没加.gitignore" → "因为 dev 不知道要加" → "因为 onboarding 文档没写" → "因为 spec 没要求"。

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "是小事故，不用走完整流程" | 严重度判定是 Triage 阶段的工作，不是跳阶段的理由。流程是给所有严重度的事件用的 |
| "先 patch 再 triage 节省时间" | 没 Triage 你不知道第二个攻击入口在哪。跳 Triage = 给攻击者开后门 |
| "不要告诉用户，免得恐慌" | GDPR / CCPA / 用户合同有强制时限。不通知 = 法律风险 |
| "证据不重要，先恢复服务" | forensic 证据是追责 / 防止再次发生 / 法律诉讼的关键。恢复前必须留证据 |
| "我们没 security team，incident response 不适用" | 个人 / 小团队更要走流程——他们没专职安全人员兜底。流程是给"出问题时还能做对事"的保险 |
| "只 reset 受影响账号就行，不用换全部凭据" | 攻击者已 lateral movement 是常态。**全部** 重置 |
| "公开声明会让用户跑掉" | 公开声明是法律义务 + 长期信任。不公开 = 用户发现后信任崩盘 |
| "写完 postmortem 就够了，不需要 follow-up action" | 没 action item = 下次同原因再来。Action 是 incident response 的输出 |

## Red Flags

- Triage 阶段就 reset 受影响账号（破坏证据链）
- Contain 后立刻 Recover（跳 Eradicate = 攻击者还在）
- Eradicate 不验证漏洞彻底修补（用 security-research 跑 PoC）
- Recover 用被攻陷的 backup（必须从已知干净源恢复）
- Postmortem 跳过 5 whys（停在表层）
- Postmortem 找不到 action item（流程白走）
- Critical / major 不通知用户（违反法律 + 信任）
- 一个 incident 处理完后不更新 runbook（下次还是手忙脚乱）
- 兄弟 skill 触发：写代码预防（走 security-and-hardening）/ 部署前供应链（走 security-devsecops）

## Verification

完成本 skill 后确认：

- [ ] incident 笔记已写到 `.omo/incidents/<incident-id>/incident.md`（含 timeline + 证据保留段）
- [ ] 严重度 + 影响范围 已记录（Triage 段）
- [ ] Contain 动作已完成 + 记录
- [ ] Eradicate 验证：OMO `security-research` 跑 post-incident PoC，确认漏洞已彻底修补
- [ ] Recover 用干净 source + 全部凭据已重置
- [ ] 用户通知已按法律时限发送（critical / major 必须）
- [ ] Postmortem 已写：5 whys + action items + lessons
- [ ] Runbook 已更新（下次 incident 不再手忙脚乱）
- [ ] 本 skill 未做任何**未授权的**代码改动（只做最小隔离 + 补丁）

## omo Integration

Use task tools/Boulder for incident phases, oracle for impact decisions, notepad/evidence ledger for the timeline, and `review-work` for the postmortem gate.
## Related Skills

- **写代码时**：[`security-and-hardening`](~/.agents/skills/security-and-hardening/SKILL.md) — app-layer 预防
- **部署前**：[`security-devsecops`](~/.agents/skills/security-devsecops/SKILL.md) — supply chain + deployment 预防
- **运行监控**：[`observability-and-instrumentation`](~/.agents/skills/observability-and-instrumentation/SKILL.md) — 检测异常 alert 是本 skill Detect 阶段的输入源
- **修复实现**：incident 触发的修复走 [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md) Kanban ticket
- **Bug 调试**：[`debugging-and-error-recovery`](~/.agents/skills/debugging-and-error-recovery/SKILL.md) — 非安全 bug
- **OMO 工具**：
  - `security-research` mode — post-incident root cause + PoC 验证
  - `oracle` agent — 影响评估 + 决策链
  - `websearch` MCP — CVE 公告 + 攻击 IOC
  - `context7` MCP — incident response 工具文档
  - `review-work` skill — post-incident code review