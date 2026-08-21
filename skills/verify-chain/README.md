# 验证链(Verify Chain)Skill

## 这是什么

一个使用 "角色对抗 + 上下文隔离 + 联网交叉验证" 机制来提升 IT 技术文章准确性的 AI 工具链。

写完一篇技术文章后,运行验证链:
1. AI 自动提取文章中的关键断言
2. 多个独立 AI 实例并行联网核查每个断言
3. 发现问题自动修复

## 快速开始

### 触发

直接说 "帮我验证这篇文章" / "核查一下文章内容有没有错误"。
或在你写完一篇技术文章后,主动询问 "需要验证吗"。

### 模式

| 模式 | 说辞 | 说明 |
|------|------|------|
| 全自动 | "帮我验证这篇文章" | 提取 → 核查 → 修复 → 报告,一气呵成 |
| 先审再改 | "先审再改,验证文章" | 核查完成后暂停,等你审核再决定修什么 |
| 只查不改 | "只查不改,验证文章" | 只输出核查报告,不修改文章 |
| 重点检查 | "重点检查命令参数,验证文章" | 将关注点传递给 Critic |

## 它不能做什么

- 验证你的个人观点或主观评价("我认为 xxx 是最优方案" 这种)
- 验证纯原创理论(没有公开资料可对照)
- 替代专业领域专家的深度审稿
- 100% 消除所有错误(AI 本身也有局限)

## 文件结构

```
skills/verify-chain/
├── SKILL.md              # 入口 + 流程编排
├── prompts/
│   ├── critic.md         # Critic 系统提示词
│   ├── verifier.md       # Verifier 系统提示词
│   └── repairer.md       # Repairer 系统提示词
└── references/
    └── verification-report-example.md  # Spring Boot 4 验证报告案例
```

## 实现机制(给 agent 看)

- 每个 Verifier 通过 `task(subagent_type="explore", run_in_background=true)` 启动独立上下文
- 联网工具:`websearch_web_search_exa` + `webfetch`
- 收集并行结果:用 `background_output(task_id="bg_...")` 等待每个 subagent 完成