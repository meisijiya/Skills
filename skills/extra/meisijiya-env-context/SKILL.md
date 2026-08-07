---
name: meisijiya-env-context
description: >-
  Loads user-level environment context (language, OS, architecture principles,
  deployment topology, port exposure rules, mirror sources). Use for tasks
  involving infra, deploy, database, port, network, container, mirror, domain,
  or environment-specific configuration.
allowed-tools: "Read Grep"
---

# meisijiya-env-context

## Overview

装载用户级 AGENTS.md(`~/.config/opencode/AGENTS.md`)的 **4 个 L3 环境 block**:Personal Rules / Architecture Principles / Port Exposure Rules / Mirror Sources,让涉及基础设施、部署、数据库、端口、网络、容器、镜像源、域名配置的任务在执行前先对齐环境硬规则。**只读装载,不修改**用户级 AGENTS.md。

与 omo Sisyphus 内置 `env-context`(时区/locale)区分:本 skill 是 meisijiya 系,装载的是**本机部署环境约束**(中文/WSL2、DB 分离架构、12121 端口规则、镜像源 fallback 策略)。

## When to Use

**Use when:**
- 任务涉及 **infra / deploy / database / port / network / container / mirror / domain**(描述字段触发词)
- 用户提到部署、数据库连接、端口选择、镜像源配置、云资源限制、域名/nginx 相关配置
- 需要判断"本地机器上能不能跑这个服务/进程/端口"这类环境约束问题

**装载的 4 个 L3 block(见下各节):**
1. **Personal Rules** — 中文回答 + WSL2 环境
2. **Architecture Principles** — DB 分离硬规则 + 云资源限制
3. **Port Exposure Rules** — 端口暴露表 + 12121 硬规则
4. **Mirror Sources** — 官方优先镜像 fallback + GitHub 操作规则

**NOT for:**
- 纯逻辑/纯代码问题(与部署环境无关的功能实现)— 不装载
- 时区/locale 类环境问题 — 那是 omo Sisyphus 内置 `env-context` 的职责
- 修改用户级 `~/.config/opencode/AGENTS.md` — 那是用户操作,本 skill 只读

## Process

1. **检查源文件存在**:`~/.config/opencode/AGENTS.md` 不存在 → 静默跳过(block 内容以本文件转载为准,但标注来源失效)。
2. **按需查询**:用 `Read`/`Grep` 从 `~/.config/opencode/AGENTS.md` 定位对应 block(按 `<!-- <BLOCK>_START -->` / `<!-- <BLOCK>_END -->` 标记),以**源文件为准**;源文件不可读时,用本 SKILL.md 转载内容(带 `<!-- source: ... -->` 行号标注,见下 4 节)。
3. **对齐规则**:把相关 block 的硬规则纳入本次任务约束(如选端口避开 12121 规则、装依赖走镜像 fallback 顺序、数据库必须放独立机器)。
4. **不修改源**:任何情况下不编辑用户级 AGENTS.md;规则冲突时向用户报告冲突,不自行裁决。

## L3 Block: Personal Rules

<!-- source: ~/.config/opencode/AGENTS.md L3-6 -->

- **Please answer in Chinese(中文)**。**Regardless of the language of the question, respond entirely in Chinese(中文)**。
- The current machine environment is Ubuntu 24.04 on WSL2。

## L3 Block: Architecture Principles

<!-- source: ~/.config/opencode/AGENTS.md L120-135 -->

**DB 分离(硬规则)**:数据服务(MySQL / Redis / PG / MongoDB)跑**独立服务器**,本地只跑 FE + BE(test/prod 同);隔离用独立库(`ai_food_dev` / `_staging` / `_prod`)或 schema/user 前缀;**本地禁任何 DB 进程**(反例:`vite preview` 连本地 DB / `docker run mysql` → 数据污染、不可复现);直连走内网 IP(腾讯云互通,无 SSH tunnel)。

**云资源(@cloud 2C/2G)**:单容器 `mem_limit ≤ 512m` + `cpus ≤ 0.5`(防 OOM);跨账号 / VPC 内网**不保证**,按需验证;公网入口留本地(nginx + Let's Encrypt + HSTS),云实例不暴露公网。

## L3 Block: Port Exposure Rules

<!-- source: ~/.config/opencode/AGENTS.md L139-163 -->

本机部分端口绑定 `0.0.0.0` / 公网放行。**HSTS 不完整**:只防浏览器降级 HTTPS,对 curl / 扫描器 / 直连 IP / WebSocket 无效。

| Port | Role | Public Exposure | Allowed Content |
|---|---|---|---|
| 80 / 443 | nginx HTTPS entry | Hostname locked | Only reverse-proxied content |
| 3000 | vite dev | **Disabled** | — |
| 4173 | vite preview | Intranet default; caution on public | — |
| **12121** | Design system static preview | **Reachable** (0.0.0.0) | **Non-sensitive static content only** |

### 12121 Hard Rules

- **Only allowed**:`dist/` 构建产物、纯 HTML/CSS/JS 静态资源、design mocks、公开文档
- **Forbidden**:`backend/build/`、`*.jar`、`.env*`、`~/.ssh/`、`~/local-private-notes/`、`backend.bak.*/`、运维脚本、`/etc/`、敏感目录
- 启动前:`ls` 检查 `--directory` 无敏感文件;`pgrep -fa 12121` 查残留先 kill
- 命令模板(替换 `<project-dist>`):

```bash
setsid nohup python3 -m http.server 12121 --directory <project-dist> --bind 0.0.0.0 < /dev/null > /tmp/<project>-preview.log 2>&1 & disown
```

## L3 Block: Mirror Sources

<!-- source: ~/.config/opencode/AGENTS.md L167-206 -->

机器在**中国大陆**:安装依赖 / 拉镜像 / 下载二进制 / **GitHub 读拉代码**默认**官方源**;镜像仅 fallback(官方 5-min SSL 超时后显式调用);全局 `insteadOf` **已移除**,镜像 opt-in。

### 已配置镜像 (fallback only)

| Tool | Mirror (fallback only, not auto-routed) |
|---|---|
| npm / pnpm / yarn | `https://registry.npmmirror.com/` |
| pip | `https://pypi.tuna.tsinghua.edu.cn/simple` |
| bun | `[install] registry = "https://registry.npmmirror.com/"` |
| Go | `https://goproxy.cn,direct` (not installed) |
| Docker | `https://docker.m.daocloud.io` |
| GitHub clone/fetch | `https://gh-proxy.com/https://github.com/` |
| apt | gh/trivy 单独源, noble 默认 |

### 安装硬规则

1. 先 `which <tool>` 验证是否已装
2. **默认官方源**;仅官方超时后换镜像 — **绝不预先全局 `insteadOf` 改写**
3. 新工具类别(rust / tex / conda):先验证官方;失败则镜像 + `curl -sI` HTTP 200 再标记 "implemented"
4. 镜像不可达:先 `curl -I`,不直接换源(可能临时不可用)
5. 临时绕过镜像(如 Daocloud 白名单限制):说明理由 + 定义 follow-up 动作
6. **GitHub**:默认 `https://github.com/...`;官方超时才换 gh-proxy(显式 URL,无全局改写)

### Daocloud

白名单机制:非白名单 `docker pull` 被拒(DaoCloud issue #2328);fallback `docker.io` 或本地 tar 导入。

### GitHub Operations

- 浏览:`gh repo view` / `gh issue list` / `gh release list` / `gh api`;下载 release:`gh release download`(均官方)
- raw 文件:`gh api repos/<o>/<r>/contents/<path>`(官方;超时走 gh-proxy raw);❌ `curl raw.githubusercontent.com`(5-min 超时)
- clone / push:`git clone https://github.com/...` + `gh pr create`;超时用显式 gh-proxy(无全局改写);❌ `curl github.com/.../releases/latest` → `gh release list`;❌ 全局 `insteadOf` 已移除

## Common Rationalizations

| 借口 | 反驳 |
|---|---|
| "这个任务只是改代码,不用管环境规则" | 端口 / 镜像 / DB 部署决策常藏在"顺手"操作里(如 `docker run mysql` 测试、`python3 -m http.server` 起预览);不装载 → 违反硬规则 |
| "12121 端口空着,随便起个服务" | 12121 只允许非敏感静态内容;起服务前必须 `ls` 检查目录 + `pgrep` 查残留 |
| "GitHub 超时了,直接配全局 insteadOf 走镜像" | 全局改写已被明确移除;镜像只按命令 opt-in,防静默走第三方代理 |
| "本地跑个 MySQL 测试一下很方便" | DB 分离是硬规则;本地 DB 进程 → 数据污染 + 单机不可复现 |
| "用户级 AGENTS.md 我顺手改一下" | 那是用户文件;本 skill 只读装载,规则冲突向用户报告 |

## Red Flags

- 涉及 deploy / database / port / mirror 的任务未装载 4 个 L3 block 就开始执行
- 在本地起数据库进程 / 把 DB 部署到本地机器(违反 Architecture Principles §1)
- 在 12121 端口起服务前未 `ls` 检查目录内容、未 `pgrep -fa 12121` 查残留
- 12121 服务暴露 `backend/build/`、`.env*`、`~/.ssh/` 等敏感路径
- 给依赖安装配置全局 `url.*.insteadOf` 改写(违反 Mirror Sources 硬规则 2/6)
- 未经官方源超时验证就默认走镜像源
- 修改了用户级 `~/.config/opencode/AGENTS.md`(只读装载)
- 把本 skill 与 omo 内置 `env-context`(时区/locale)混淆

## Verification

- [ ] 任务涉及 4 个 L3 block 的触发词时,已装载对应 block(以 `~/.config/opencode/AGENTS.md` 源文件为准,转载内容有 `<!-- source: ... -->` 标注)
- [ ] 未在本地机器上启动 / 部署任何数据库进程(Architecture Principles §1)
- [ ] 12121 端口服务:已 `ls` 确认目录仅含非敏感静态内容 + 已 `pgrep -fa 12121` 清理残留
- [ ] 依赖安装 / GitHub 操作用官方源,超时才显式 opt-in 镜像,无全局 `insteadOf` 改写
- [ ] 用户级 `~/.config/opencode/AGENTS.md` 未被修改;规则冲突已向用户报告而非自行裁决

## Related Skills

- 装载来源:[`using-meisijiya-skills`](~/.agents/skills/using-meisijiya-skills/SKILL.md)(dispatcher,§Process 1 检查 handoff) — 本 skill 是其环境约束装载层
- 互补:omo Sisyphus 内置 `env-context`(时区/locale) — 本 skill 装载部署环境约束,两者职责分离
- 相关:镜像/供应链相关任务可叠 [`security-devsecops`](~/.agents/skills/security-devsecops/SKILL.md)(CVE 扫描)与 [`supply-chain-risk-auditor`](~/.agents/skills/supply-chain-risk-auditor/SKILL.md)(依赖信任审计)
