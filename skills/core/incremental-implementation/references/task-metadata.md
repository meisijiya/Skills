# OMO Task Metadata 结构化字段 (§3.8)

OMO `task_create` 工具已经支持 `metadata: record<string, unknown>` 字段。我们**用 metadata 传结构化 brief** 而不是塞 free text description:

```typescript
task_create({
  subject: "slice-2b-read-user-v2: Read user list v2",
  metadata: {
    globalConstraints: [/* 引用 Phase 1 Global Constraints 段 */],
    interfaces: {
      consumes: [
        { symbol: "createUser", file: "src/users/service.ts:42" },
        { symbol: "User", file: "src/users/types.ts:5-12" }
      ],
      produces: [
        { symbol: "getUserById", file: "src/users/service.ts", signature: "(id: string) => Promise<User | null>" }
      ]
    },
    biteSizedSteps: [
      { step: 1, action: "Write failing test", files: ["tests/users/getUserById.test.ts"], code: "...", verify: "pnpm test tests/users/getUserById.test.ts", expected: "FAIL: Cannot find module" },
      { step: 2, action: "Run test to verify fails", command: "pnpm test tests/users/getUserById.test.ts", expected: "FAIL with 'getUserById is not a function'" },
      // ...
    ],
    noPlaceholders: true,  // 写入即 commit 此契约
    statusContract: "DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED"
  }
})
```

**为什么不写 `description` 字段**:OMO 的 task description 是 free text,executor 看到的是 description 而不是 metadata。**metadata 是结构化的、可被脚本读取的**。我们的 `~/.agents/skills/incremental-implementation/scripts/task-brief.sh` 直接从 metadata 提取 brief 文件,executor 拿到的 brief 包含完整 step-by-step 代码。