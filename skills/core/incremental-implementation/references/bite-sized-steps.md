# Bite-sized Steps: TDD 5 步 + Exact Code (§3.6)

**每个 slice 必须用 TDD 5 步分解**(每步 2-5 分钟):

```markdown
**Steps:**

- [ ] **Step 1: Write the failing test**
```typescript
// tests/users/getUserById.test.ts
import { getUserById } from '@/users/service';
import { setupTestDB, teardownTestDB } from '../helpers/db';

describe('getUserById', () => {
  beforeEach(setupTestDB);
  afterEach(teardownTestDB);

  test('returns user when id exists', async () => {
    const created = await createUser({ email: 'a@b.co' });
    const found = await getUserById(created.id);
    expect(found?.email).toBe('a@b.co');
  });

  test('returns null when id does not exist', async () => {
    const found = await getUserById('nonexistent');
    expect(found).toBeNull();
  });
});
```
- [ ] **Step 2: Run test to verify it fails**

Run: `pnpm test tests/users/getUserById.test.ts`
Expected: FAIL with "Cannot find module '@/users/service' or its corresponding type declarations." (or "getUserById is not a function")

- [ ] **Step 3: Write minimal implementation**
```typescript
// src/users/service.ts
export async function getUserById(id: string): Promise<User | null> {
  const row = await db.users.findUnique({ where: { id } });
  return row ? toUser(row) : null;
}
```
- [ ] **Step 4: Run test to verify it passes**

Run: `pnpm test tests/users/getUserById.test.ts`
Expected: PASS — 2/2 tests

- [ ] **Step 5: Commit**
```bash
git add tests/users/getUserById.test.ts src/users/service.ts
git commit -m "feat(users): add getUserById"
```
```

**强约束**(从 Superpowers No Placeholders 直接吸收):

- ❌ 禁止 "TBD" / "TODO" / "implement later" / "fill in details"
- ❌ 禁止 "Add appropriate error handling" / "add validation" / "handle edge cases"
- ❌ 禁止 "Similar to Task N" — 必须重复代码,executor 可能乱序读
- ❌ 禁止 "Write tests for the above" without actual test code
- ❌ 禁止 描述 "做什么" 而不展示 "怎么做" — 代码块必填
- ❌ 禁止 引用未定义的类型/函数/方法
- ✅ exact paths 必填 (`tests/exact/path/test.ts`)
- ✅ complete code in every step — 即使代码已在 Step 1 写过,Step 3 仍需重新展示
- ✅ exact commands with expected output(每个 command 必带 Expected: PASS/FAIL 行)

**WHY**:executor 在 fresh context,看不到 plan 全貌,无法"参考前面步骤",只能照猫画虎。每步必须独立可执行。