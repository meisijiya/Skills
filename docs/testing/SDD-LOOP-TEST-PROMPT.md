# SDD loop 端到端测试提示词

把下面整段粘贴到一个**新 session**(避免污染当前会话的对话上下文),让模型按这个引导跑完整个 SDD 循环。

---

## 任务背景

我刚在 `meisijiya-skills` 仓库完成 Superpowers-style SDD(Subagent-Driven Development)改造:

- 新增 `skills/extra/slice-review/` — per-slice 轻量审查
- 新增 3 个 shell 脚本:`skills/core/incremental-implementation/scripts/{task-brief.sh, slice-progress.sh}` + `skills/extra/slice-review/scripts/review-package.sh`
- 在 `skills/core/incremental-implementation/SKILL.md` 增加 5 个 Phase 3 slice metadata 字段(Global Constraints / Interfaces Consumes · Produces / bite-sized steps / No Placeholders / 4 态契约)

我需要你**实际跑一遍完整 SDD loop**,验证端到端可行。**不要只读 SKILL.md 描述就回答"可以工作"**——必须真的创建一个 git repo 雏形,写 plan,跑脚本,派 subagent。

## 仓库位置

`/home/ljh2923/opencode-project/meisijiya-skills/`

脚本都在仓库内:
- `skills/core/incremental-implementation/scripts/task-brief.sh`
- `skills/core/incremental-implementation/scripts/slice-progress.sh`
- `skills/extra/slice-review/scripts/review-package.sh`

## 测试用例(请按顺序执行)

### Step 1: 创建最小可运行的 demo 项目

在 `/tmp` 下建一个 git repo,模拟"Slice 1: 给一个 Express server 加一个 `/health` endpoint"。

```bash
mkdir -p /tmp/sdd-demo && cd /tmp/sdd-demo
git init -q && git config user.email test@example.com && git config user.name test
# package.json
cat > package.json <<'EOF'
{
  "name": "sdd-demo",
  "version": "0.0.1",
  "type": "module",
  "engines": { "node": ">=20.10" },
  "scripts": {
    "start": "node server.js",
    "test": "node --test test/"
  }
}
EOF
# server.js
cat > server.js <<'EOF'
import express from 'express';
const app = express();
app.get('/health', (req, res) => res.json({ status: 'ok' }));
app.listen(3000);
EOF
git add . && git commit -q -m "initial commit"
```

### Step 2: 写一个最小 plan 含 1 个 slice

在 `/tmp/sdd-demo/.omo/plans/demo-plan.md` 写一个 plan 文件,Phase 3 含 1 个 task,但**没有** metadata 结构化字段(故意 — 测试脚本是否能优雅处理空 metadata)。

```bash
mkdir -p /tmp/sdd-demo/.omo/plans
cat > /tmp/sdd-demo/.omo/plans/demo-plan.md <<'EOF'
# Demo Plan

## Phase 1: Spec

**Goal:** Add /health endpoint to Express server.

**Acceptance Criteria:**
- [ ] GET /health returns 200 with `{status: "ok"}`

## Phase 3: Tasks

- [ ] 1. Add /health endpoint
EOF
cd /tmp/sdd-demo
```

### Step 3: 测试 task-brief.sh 在 metadata 缺失时的行为

注意:OMO 的 task tools 需要先调用 `task_create` 才有 task JSON。我们的脚本会处理 missing metadata — 看它是否输出 warning 而非崩溃。

```bash
# 没有真实 OMO 任务,所以模拟一个空 task JSON
mkdir -p /tmp/sdd-demo/.omo/sdd/demo-plan
cat > /tmp/sdd-demo/.omo/sdd/demo-plan/T-test1.json <<'EOF'
{"id":"T-test1","subject":"test","description":"","status":"pending","blocks":[],"blockedBy":[]}
EOF

# 用我们的脚本读它(注意我们的脚本默认读 $OPENCODE_CONFIG_DIR,需要 override)
TASK_ID=T-test1
TASKS_DIR=/tmp/sdd-demo/.omo/sdd/demo-plan bash /home/ljh2923/opencode-project/meisijiya-skills/skills/core/incremental-implementation/scripts/task-brief.sh $TASK_ID --plan demo-plan --output /tmp/sdd-demo/.omo/sdd/demo-plan/test-brief.md
echo "---"
echo "exit code: $?"
cat /tmp/sdd-demo/.omo/sdd/demo-plan/test-brief.md
```

**期望**:exit code 4 (metadata 缺失的警告),brief 文件**仍生成**且包含"⚠️ WARNING"标记。

### Step 4: 测试完整 happy path(metadata 完整 + 真实 commit)

```bash
# 删除旧文件,重建一个完整 metadata 的 task JSON
cat > /tmp/sdd-demo/.omo/sdd/demo-plan/T-test2.json <<'EOF'
{
  "id": "T-test2",
  "subject": "Add /health endpoint",
  "description": "Add GET /health returning {status: ok}",
  "status": "pending",
  "blocks": [],
  "blockedBy": [],
  "metadata": {
    "globalConstraints": ["Node >= 20.10", "Use ESM", "No new deps"],
    "interfaces": {
      "consumes": [{"symbol": "express", "file": "package.json:1"}],
      "produces": [{"symbol": "healthRoute", "file": "server.js", "signature": "(req: Request, res: Response) => void"}]
    },
    "biteSizedSteps": [
      {"step": 1, "action": "Write failing test", "code": "import test from 'node:test';..."},
      {"step": 2, "action": "Run test, expect FAIL"},
      {"step": 3, "action": "Write minimal implementation"},
      {"step": 4, "action": "Run test, expect PASS"},
      {"step": 5, "action": "Commit"}
    ],
    "noPlaceholders": true,
    "statusContract": "DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED"
  }
}
EOF

cd /tmp/sdd-demo
bash /home/ljh2923/opencode-project/meisijiya-skills/skills/core/incremental-implementation/scripts/task-brief.sh T-test2 --plan demo-plan --output /tmp/sdd-demo/.omo/sdd/demo-plan/test2-brief.md
echo "---"
echo "exit code: $?"
cat /tmp/sdd-demo/.omo/sdd/demo-plan/test2-brief.md | head -50
```

**期望**:exit code 0,完整 brief 含 Global Constraints / Interfaces / 5 step 等。

### Step 5: 测试 review-package.sh(模拟 2 个 commit)

```bash
cd /tmp/sdd-demo
# 模拟 executor 跑了 2 个 commit
echo "// added test" > test/health.test.js
git add . && git commit -q -m "test: add failing health.test.js"
sleep 1
sed -i "s|app.get('/health'|app.get('/healthz'|" server.js
sed -i "s|status: 'ok'|status: 'healthy'|" server.js
git add . && git commit -q -m "feat: implement /healthz endpoint"
BASE=$(git rev-parse HEAD~1)
HEAD=$(git rev-parse HEAD)
bash /home/ljh2923/opencode-project/meisijiya-skills/skills/extra/slice-review/scripts/review-package.sh T-test2 "$BASE" "$HEAD" --plan demo-plan --output /tmp/sdd-demo/.omo/sdd/demo-plan/test2-diff.patch
echo "---"
echo "exit code: $?"
cat /tmp/sdd-demo/.omo/sdd/demo-plan/test2-diff.patch | head -30
```

**期望**:exit code 0,diff 文件含 commit list + stat + diff with -U10。

### Step 6: 测试 slice-progress.sh(mark-complete + list)

```bash
cd /tmp/sdd-demo
BASE=$(git rev-parse HEAD~1)
HEAD=$(git rev-parse HEAD)
bash /home/ljh2923/opencode-project/meisijiya-skills/skills/core/incremental-implementation/scripts/slice-progress.sh mark-complete T-test2 "$BASE" "$HEAD" --review-verdict ok --plan demo-plan
echo "---"
bash /home/ljh2923/opencode-project/meisijiya-skills/skills/core/incremental-implementation/scripts/slice-progress.sh list --plan demo-plan
echo "---"
cat /tmp/sdd-demo/.omo/sdd/demo-plan/progress.md
```

**期望**:ledger 文件 `.omo/sdd/demo-plan/progress.md` 含 1 行 DONE 记录,含 commit range `xxxxxxx..yyyyyyy`(短 SHA)+ review verdict `ok`。

### Step 7: 错误路径测试(关键!)

#### 7a. base == head(无 commit)

```bash
cd /tmp/sdd-demo
SAME=$(git rev-parse HEAD)
bash /home/ljh2923/opencode-project/meisijiya-skills/skills/extra/slice-review/scripts/review-package.sh T-test2 "$SAME" "$SAME" --plan demo-plan 2>&1
echo "---"
echo "exit code: $?"
```
**期望**:exit code 3,错误信息"no commits between X and Y"。

#### 7b. 不存在的 plan

```bash
bash /home/ljh2923/opencode-project/meisijiya-skills/skills/core/incremental-implementation/scripts/task-brief.sh T-test2 --plan nonexistent-plan 2>&1
echo "---"
echo "exit code: $?"
```
**期望**:exit code 3,错误信息"plan file not found"。

#### 7c. 不存在的 task

```bash
bash /home/ljh2923/opencode-project/meisijiya-skills/skills/core/incremental-implementation/scripts/task-brief.sh T-doesnotexist --plan demo-plan 2>&1
echo "---"
echo "exit code: $?"
```
**期望**:exit code 2,错误信息"task file not found"。

### Step 8: 写测试报告

把测试结果写到 `/tmp/sdd-demo/TEST-REPORT.md`,**包含**:

1. 每个 Step 的 exit code(应该与"期望"匹配)
2. 任何意外行为(即使通过了 exit code,如果输出有错也应该报告)
3. SKILL.md 文档与实际脚本行为不符的地方
4. 改进建议(接口、错误信息、性能)

## 测试目标

我要确认的是:
- [ ] **3 个脚本 happy path 全部 exit 0**
- [ ] **metadata 缺失时 task-brief.sh 返回 exit 4 但仍生成文件**
- [ ] **错误路径(无 commit / 不存在 plan / 不存在 task)给出明确错误信息 + 正确 exit code**
- [ ] **brief 文件实际包含所有 metadata 字段(Global Constraints / Interfaces / 5 steps)**
- [ ] **review-package 文件包含 commit list + stat + diff**
- [ ] **progress.md ledger 包含完整 row(ts / task_id / status / commits / review)**

如果有任何 Step 失败,把失败的命令 + 实际输出 + exit code 全部贴出来。不要只说"通过了"。

## 测试完成后

把 `/tmp/sdd-demo/TEST-REPORT.md` 的内容贴回主 session,然后我们讨论结果。

如果遇到问题:
- **脚本语法错误**:贴出 bash error
- **jq 缺失**:`apt install jq` 或 `brew install jq`
- **git 问题**:贴出 git error
- **意外行为**:贴出实际输出 vs 期望输出

不要跳过任何 Step。即使某步失败,继续下一步 — 我们要看全链路哪个环节出问题。
