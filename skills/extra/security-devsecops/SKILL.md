---
name: security-devsecops
description: "Secures the supply-chain + deployment pipeline. Use when adding or upgrading dependencies (npm install / pip install / lockfiles), rotating secrets or API keys, configuring CI/CD, writing IaC (Terraform / Kubernetes / Ansible / Docker), building container images, or preparing a production deployment. Under omo, uses security-research mode for production-critical pre-deploy audits, oracle agent for IaC architecture questions, websearch MCP for latest supply-chain CVEs, context7 MCP for security tool docs."
allowed-tools: "Read Edit Bash Glob Grep WebFetch"
---

# security-devsecops

## Overview

代码写完之后、上线之前的安全——supply chain、secrets、CI/CD、IaC、container、pre-deploy gate。这是 [`security-and-hardening`](~/.agents/skills/security-and-hardening/SKILL.md) 不覆盖的"deploy-side"安全。

**与 security-and-hardening 的边界**：

| 阶段 | Skill | 焦点 |
|---|---|---|
| 写代码时 | `security-and-hardening` | input validation / auth / OWASP / secrets-in-code |
| 写完 → 上线前 | **`security-devsecops`**（本 skill） | deps / SBOM / rotation / CI/CD / IaC / container / pre-deploy |
| 上线后被攻击 | `security-incident-response` | detect / contain / eradicate / recover / postmortem |

**OMO 集成**：本 skill 大量用 OMO 工具做 evidence-bound 检查：
- `security-research` mode 跑生产前深度审计（3 hunters + 2 PoC）
- `oracle` agent 棘手的 IaC 架构决策（读-only high-IQ 推理）
- `websearch` MCP 查最新 supply chain 攻击 / CVE
- `context7` MCP 查安全工具最新文档（trivy / gitleaks / OPA 等）
- `review-work` skill 跑 deploy-side code review

## When to Use

**Use when:**
- 添加或升级依赖（`npm install` / `pip install` / lockfile 改动）
- 生成 SBOM 或做 supply chain 追踪
- 轮换 API key / DB password / JWT secret
- 配置 CI/CD pipeline（GitHub Actions / GitLab CI / Jenkins）
- 写 IaC：Terraform / Kubernetes manifest / Ansible / CloudFormation
- 构建容器镜像（Dockerfile / podman）
- 准备生产部署（deploy / release / publish / 上线 / 发版）
- 设置 secret manager（Vault / AWS Secrets Manager / Doppler）
- 配置 IaC policy（OPA / Sentinel / Conftest）

**NOT for:**（场景描述——具体用哪个 skill 由 description 匹配决定）
- 写代码本身（user input / auth / OWASP 规则）→ [`security-and-hardening`](~/.agents/skills/security-and-hardening/SKILL.md)
- 已经发生攻击 / 需要事后响应 → `security-incident-response`
- 部署后跑性能 / 可用性监控 → [`observability-and-instrumentation`](~/.agents/skills/observability-and-instrumentation/SKILL.md)
- 纯代码 review（不带 deploy / supply chain 维度）→ [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md)

## Process

### 1. Dependency scanning

每次添加 / 升级依赖都跑：

```bash
npm audit            # Node
pip-audit            # Python
cargo audit          # Rust
go list -m -json all | nancy --skip-update-check   # Go
```

**Block merge on high/critical severity**（不只是 warn）。Pin major versions in lockfiles; allow patch updates only.

CI 集成：把 `npm audit --audit-level=high` 加进 pre-merge check；不要 `--audit-level=low`（噪音淹没）。

OMO 增强：用 `grep_app` MCP 搜 GitHub 看 CVE 是否已有 in-the-wild fix：
```
mcp__grep_app__searchGitHub <CVE-id> <library>
mcp__grep_app__searchGitHub "CVE-2024-XXXX" "package.json"
```

### 2. SBOM + supply chain

**SBOM** (Software Bill of Materials) = 你的软件包含什么、来自哪里。

工具：
```bash
syft <image>             # 生成 SBOM（多格式）
grype <sbom-file>        # 基于 SBOM 扫已知漏洞
cdxgen                   # CycloneDX 格式 SBOM
```

**Typosquatting 防御**：
- 装包前在 npm / PyPI 官方站确认名字拼写
- 用 `--ignore-scripts` (`npm install --ignore-scripts`) 阻止 postinstall 跑任意代码
- 锁文件用 `npm ci` 而不是 `npm install` 进 CI（防止 lockfile 漂移）

**Verify 来源**：内部 npm registry / private PyPI / JFrog Artifactory 配置 trusted registry，避免误装外部恶意包。

### 3. Secrets rotation

定期轮换 secrets，绝不长期放 .env：

| Secret 类型 | 轮换周期 | 工具 |
|---|---|---|
| API key（外部服务） | 90 天 | secret manager 自动 |
| DB password | 90 天 | secret manager + 双密码过渡期 |
| JWT signing key | 180 天 | key rotation protocol（双 key + grace period） |
| TLS certificate | 90 天前（acme.sh / Let's Encrypt） | 自动续期 |
| OAuth client secret | 365 天 | secret manager |

**Secret manager**：不要手维护 .env。用：
- AWS Secrets Manager / GCP Secret Manager / Azure Key Vault
- HashiCorp Vault（自托管）
- Doppler / Infisical（SaaS 友好）

**.env 安全**：
- `.env` / `.env.*.local` 加进 `.gitignore`（**永远**）
- 不要把 .env commit 进 git（即使删了 commit，history 仍有）
- 用 `git rm --cached` 撤出 tracked 状态 + BFG / git-filter-repo 清历史

### 4. Deployment pipeline security

CI/CD 是攻击者最喜欢的横向移动入口。**Pipeline 必须**：

- [ ] **Secret scanning** 每次 commit：gitleaks / trufflehog / GitHub secret scanning
- [ ] **Branch protection** main 分支不允许 force-push
- [ ] **PR review required** 不是 admin 也要 ≥1 approve
- [ ] **OIDC token** 代替 long-lived secret（GitHub Actions → AWS / GCP 用 OIDC）
- [ ] **Deployment key 权限最小化**：deploy key 只能写特定 service，不能改 IAM / billing
- [ ] **环境隔离**：dev / staging / prod 三套独立 secrets / IAM role

**Pre-deploy hook**：deploy 前跑：
```bash
# 1. Secret scan
gitleaks detect --source . --verbose

# 2. Dependency audit
npm audit --audit-level=high

# 3. IaC lint（如果改了 terraform）
tfsec .

# 4. Container scan（如果改了 Dockerfile）
trivy image <image-name>
```

**OMO 增强**：用 `security-research` mode 跑 production-critical pre-deploy audit（[security-and-hardening Step 6.5](~/.agents/skills/security-and-hardening/SKILL.md) 同样的 3 hunters + 2 PoC 机制，但焦点是 pipeline 不是 application code）。

### 5. IaC + Container security

#### Terraform / OpenTofu

```bash
tfsec .                # 静态扫描
checkov -d .           # 更细的 policy
terrascan scan         # OPA-based
```

常见问题：
- S3 bucket public access 没禁
- Security group 0.0.0.0/0
- IAM policy *:*
- RDS / EBS 没加密

#### Kubernetes manifest

```bash
kube-score score <manifest.yaml>      # 评分
polaris --files <manifest.yaml>        # best-practice
conftest test <manifest.yaml>          # OPA Rego policy
```

常见问题：
- privileged: true（容器不应有 root）
- hostNetwork: true（容器不应共享 host 网络）
- readOnlyRootFilesystem: false（root fs 应只读）
- resource limits 没设（DoS 风险）

#### Container image

```bash
trivy image <image>           # 多层扫（OS + language + config）
grype <image>                 # Anchore 的替代
docker scout cves <image>     # Docker 官方
```

常见问题：
- base image 用 `latest` tag（不可重现）
- 跑 root user（应用容器不应 root）
- 包管理器缓存没清（增加 attack surface）

### 6. Pre-deployment gate

合并所有 devsecops check 形成 unified gate（**Step 7 of security-and-hardening 不覆盖 deploy-side**）：

Before merging anything that's about to deploy:
- [ ] Dependency audit clean（high/critical = 0）
- [ ] SBOM 已生成并 attach 到 release
- [ ] Secrets 不在代码 / config / commit（`gitleaks detect` exit 0）
- [ ] CI/CD pipeline 配置已 review（branch protection + OIDC + deploy key 权限）
- [ ] IaC lint clean（tfsec / conftest）
- [ ] Container scan clean（trivy image）
- [ ] Pre-deploy smoke test 通过（dev/staging 环境验证）
- [ ] Rollback plan 准备好（如何快速回滚）
- [ ] For production-critical deploy: OMO `security-research` audit completed

For deployment-related design decisions (e.g., "should we use blue-green or canary?"), use OMO `oracle` agent.

For verifying security tool docs (trivy / gitleaks / OPA), use OMO `context7` MCP.

For latest supply-chain attacks / CVEs, use OMO `websearch` MCP.

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "我们公司小，没人攻击供应链" | typosquatting 是 automated，不需要选目标。任何新装的包都可能踩坑 |
| "lockfile 跟 package.json 一起 commit 就够了" | lockfile 防漂移但不防漏洞；还需要 npm audit / SBOM scan |
| ".env 加进 .gitignore 就够了" | 防 commit 不防 secrets leak 进 log / Sentry / debug output。必须 secret manager |
| "Kubernetes 默认配置就够安全" | K8s 默认是**最宽松**配置（privileged containers allowed / host network allowed） |
| "Docker latest tag 方便" | latest 不可重现，今天 build 的 image 跟明天可能完全不同 |
| "gitleaks 跑过一次没问题就永远没问题" | secrets leak 可能在任意 commit 后；CI 必须每次跑 |
| "IaC 写完就能用" | IaC 没 lint = 部署时才发现 S3 bucket 是 public 的 |
| "deployment key 给 admin 权限方便" | 一个被盗 token = 整个 AWS account 失守 |
| "supply chain attack 不会针对我" | SolarWinds / 3CX / xz-utils 都是针对性攻击，连 OSS 维护者都被钓 |
| "用 OMO security-research 就行，devsecops skill 没必要" | `security-research` 是 audit 不是 prevent；本 skill 是 process + tools 让 supply chain 默认安全 |

## Red Flags

- 添加依赖没跑 `npm audit` / `pip-audit`
- 没生成 SBOM 就发版
- .env 文件被 commit 进 git（即使后来删了）
- `latest` tag 跑生产
- K8s manifest 跑 `privileged: true` / `hostNetwork: true`
- IaC 改完没跑 `tfsec` / `conftest`
- CI/CD 没有 secret scanning
- Deploy key 权限过大（admin / 全 IAM 写权限）
- 容器镜像 base image 来自不明 registry
- "Never rotate" secrets（API key 用了一年以上）
- Pre-deploy gate 跳过 "因为只是 hotfix"
- OMO `security-research` audit 对 production-critical deploy 不跑

## Verification

完成本 skill 后确认：

- [ ] Dependency audit 0 high/critical
- [ ] SBOM 已生成并存储在 release artifact
- [ ] Secrets 来源 = secret manager，无 .env / 硬编码
- [ ] CI/CD 配置已 review：branch protection / OIDC / deploy key 权限最小化
- [ ] IaC 改完跑了 `tfsec` / `checkov` / `conftest`
- [ ] Container image 跑过 `trivy` / `grype`
- [ ] Pre-deploy smoke test 通过
- [ ] Rollback plan 已写
- [ ] For production-critical deploy：OMO `security-research` audit 报告已收

## pwf Integration

Maps to `task_plan.md` **Phase 5.5: Security Review** sub-phase, **deploy-side half**（`security-and-hardening` handles app-side half）。Outputs:

- `task_plan.md` 加 Pre-deployment gate 段
- `.planning/<id>/sbom-<release>.json` — generated SBOM
- `.planning/<id>/deploy-checklist.md` — runbook
- `.planning/<id>/security-devsecops-report.md` — OMO `security-research` output

See [pwf-integration.md](../../pwf-integration.md).

## Related Skills

- **写代码时**：[`security-and-hardening`](~/.agents/skills/security-and-hardening/SKILL.md) — application-layer（input / auth / OWASP / secrets-in-code）
- **被攻击后**：`security-incident-response` — post-breach detect / contain / eradicate / recover / postmortem
- **配置监控 / 检测**：[`observability-and-instrumentation`](~/.agents/skills/observability-and-instrumentation/SKILL.md) — 部署后跑 metrics / logs / traces（可检测 anomaly）
- **完成门**：[`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md) — 完成 deploy 前跑
- **OMO 工具**：
  - `security-research` mode — production-critical pre-deploy audit
  - `oracle` agent — IaC 架构决策（read-only high-IQ）
  - `websearch` MCP — 查最新 CVE / supply chain attack
  - `context7` MCP — 查安全工具文档
  - `grep_app` MCP — 在 GitHub 找 CVE in-the-wild fix
  - `review-work` skill — deploy-side code review