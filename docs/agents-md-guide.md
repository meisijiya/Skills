# AGENTS.md 书写规范

> **适用文件**:
> - `~/.config/opencode/AGENTS.md`(user-level)
> - `<project>/AGENTS.md`(project-level)
> - `meisijiya-skills/AGENTS.md` Section A(被 inject 到 user-level)
> - `meisijiya-skills/AGENTS.md` Section C(项目级 AGENTS.md 使用规范)
>
> **不适用**:`README.md` release section、`CHANGELOG.md`、`git log` — 这些是历史/发布载体,不是 agent 运行时规则。

## 核心原则

**AGENTS.md = agent 启动时读的运行时规则**,不是历史档案:

1. **现在态 + 指令式** — `Do X / Don't do Y / Invoke Z when W`
2. **现状描述,不做历史对比** — `skill X is for Y`,绝不 `skill X was added in vX.Y.Z`
3. **数字易腐,标注来源或删除** — `(9)` / `(10)` 随 skill 增减而过时,要么不写,要么脚本同步
4. **指"在哪",不指"从哪来"** — 给 install path(`~/.agents/skills/<name>/SKILL.md`),不给变更历史

## 错误案例 → 正确案例

### E1. 版本叙事 ❌

```markdown
## v0.4.0 status

meisijiya-skills now has 19 skills (was 16 in v0.3.0). 3 new
superpowers-derived core skills added in v0.4.0.
```

```markdown
## Catalog

- [skill-A] — for X
- [skill-B] — for Y
```

### E2. 历史对比 ❌

```markdown
We used to have 16 skills, now we have 19.
```

```markdown
[19 skills listed, no "we used to" or "now"]
```

### E3. 变更说明 ❌

```markdown
3 newly added superpowers skills went to .core/ because they're
cross-cutting discipline, not opt-in utilities.
```

```markdown
**.core/ — load always:**
- [skill-A] — meta dispatcher
- [skill-B] — pre-design exploration
- ...
```

### E4. 易腐数字 ❌

```markdown
**.core/ — load always (9):**    ← 加新 skill 后忘了改就过期
```

```markdown
**.core/ — load always:**         ← 删掉数字,无歧义
[list]

# 或
**.core/ — load always (9):**    ← 用 scripts/check-marketplace.sh 在 CI 验证
```

## 易腐数字的 3 种处理法

| 做法 | 何时用 |
|---|---|
| 删掉数字 | 数字不重要,只关心"哪些 skill 在 core" |
| 写数字 + 手动同步 | 小型个人 repo,接受每次改 skill 时手动改 inject block |
| 写数字 + 脚本同步 | 大型 repo,用 `check-marketplace.sh` 在 CI 验证 `wc -l` 等于 `jq '.plugins[0].skills \| length'` |

meisijiya-skills 当前用做法 2(写 `(9)` / `(10)`,靠 `check-marketplace.sh` 兜底)。

## 历史叙事该写哪里

| 载体 | 内容 |
|---|---|
| `CHANGELOG.md` | 长篇 release notes(按版本) |
| `git log --oneline` | 每次 commit 的短描述 |
| `git tag -a vX.Y.Z -m "..."` | release 标记 |
| `README.md` 末尾 release section | 一行 `Latest: vX.Y.Z — N skills` |

**不要写进 AGENTS.md 任何变体。**

## 验证方法

手动 grep 注入块是否含版本叙事:

```bash
awk '/<!-- meisijiya-skills:start -->/{flag=1; next} /<!-- meisijiya-skills:end -->/{flag=0} flag' \
  AGENTS.md | grep -nE "v[0-9]+\.[0-9]+\.[0-9]+|\bwas\b|\bnow has\b|\bnewly added\b" \
  && echo "FAIL: version narrative in inject block" \
  || echo "PASS: clean"
```

(可选)做 pre-commit hook 跑上述 grep,失败则拒绝 commit。脚本占位:`scripts/check-agents-md-narrative.sh` — 留待真痛了再加(YAGNI)。

## 交叉引用

- [`AGENTS.md`](../AGENTS.md) Section A — 注入到 user-level 的内容
- [`AGENTS.md`](../AGENTS.md) Section B — 仓库贡献者指南
- [`AGENTS.md`](../AGENTS.md) Section C — 项目级 AGENTS.md 使用规范
- [`skill-anatomy.md`](../skill-anatomy.md) — SKILL.md 写作规范(同源精神,scope 不同)
- [`pwf-integration.md`](../pwf-integration.md) — pwf 协作约定
