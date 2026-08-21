# 实战对比:普通简历 → 酥神简历

> 同一份素材,两种写法。左边是 90% 的人写的,右边是酥神方法论改出来的。
> 这不是文字游戏——是结构化地把「做事」翻译成「证据」。

---

## 案例 A:实习经历(AI 方向)

### 普通写法(baseline)

```
实习经历:
字节跳动 - 数据科学家实习生 (2025.05 - 2026.05)

- 参与了 Long-Horizon Agent Harness 项目,做了一些子模块
- 学习了 LLM 相关技术,包括 Context Engineering
- 参与 Agent Teams Harness 的搭建
- 协助完成了 Middleware Chain 的部分功能
- 学习了 Skill System 和 Context Engineering 的相关知识

实习收获:
- 学习了 LLM Agent 相关技术
- 提升了工程能力
- 培养了系统思维
```

**体检报告**:

| 军规 | 结果 | 说明 |
|------|------|------|
| 1 Owner | ❌ | 「参与」「协助」×4 |
| 2 0→1 | ❌ | 未体现 |
| 3 外部认可 | ❌ | 全是自我评价 |
| 4 先抬项目 | ❌ | 第一句是「参与了」 |
| 5 Before→After | ❌ | 无对比 |
| 6 数据 | ❌ | 零数字 |
| 7 岗位词 | ⚠️ | 有 LLM/Agent,但密度低 |
| 8 分点 | ❌ | 无结构 |
| 9 加粗 | ❌ | 无 |
| 10 人设 | ❌ | 无头衔 |

> **结论:这封简历会被 HR 在 5 秒内划掉。它不是简历,是道歉信。**

---

### 酥神写法(sushen style)

```
[ 字节跳动 Bytedance - 抖音 AI 基建 · AI4SE 基础算法&Infra ]
2025.05 - 2026.05 · L1 奖赏 · ByteTech 作者奖 1 次 · 字节技术文章月榜 1 次

项目【字节排序第一的开源 Long-Horizon Agent Harness】
─ 背景与目标:字节排序第一的开源 Long-Horizon Agent Harness;内置
  AIOSandBox 沙箱化执行环境,可插拔 Skill 体系,跨会话长短期记忆;
  Sub-agent 调度与系统性 Context Engineering,可处理多层级 long-horizon 任务。
─ 我的职责:【项目 Owner】主导 1.0 → 2.0 架构升级与迭代,涉及多层级
  long-horizon、Sub-agent、Planner、Executor、Relayer(汇总后工具调用)、
  Prompter 路由 OpenAI Meta Prompt 生成。
─ 技术细节:相比 1.0 五节点固定流水线,2.0 改为单 Lead Agent 统一一次调用,
  根据当前启用 skill 列表与路径记忆一次调度;Sub-agent 无规则错误、
  重用 Agent 跳过 90% 并并行;工具跳回 SubagentExecutor 1.2 实例;
  双层 S2 路径处理:最多 3 并发 / 单任务超过 90s / Sub-agent 需求二次编排。
─ 数据指标:SWE-Bench Pro 等测试集通过率 <span class="metric">+25%</span>,
  单位使用生成时长降损约 <span class="metric">30%+</span>,
  scaffold 轨迹质量 <span class="metric">+10</span>。

项目【AgentScaling for SFT & RL | MultiModel Relay + ...】
─ 背景与目标:为抖音 AI 基建构建 Agent 训练数据规模化流水线。
─ 我的职责:主导 Agent Teacher Evaluation for SFT & RL、
  Trajectory Analysis & Rubric Eval and Wash Pipeline 的设计与落地。
─ 技术细节:Background Marker · Failure Onset 定位 · 轨迹压缩 ·
  增量续推;评测服务改造并接入字节云 AIPaaS 容器平台。
─ 数据指标:评测吞吐提升 <span class="metric">2x</span>,
  坏轨迹拦截率 <span class="metric">+18%</span>。
```

**体检报告**:

| 军规 | 结果 | 说明 |
|------|------|------|
| 1 Owner | ✅ | 「项目 Owner」×2 |
| 2 0→1 | ✅ | 主导 1.0→2.0、主导搭建 |
| 3 外部认可 | ✅ | L1 奖赏、月榜、Star 数 |
| 4 先抬项目 | ✅ | 第一句「字节排序第一的开源」 |
| 5 Before→After | ✅ | 五节点流水线 → 单 Lead Agent |
| 6 数据 | ✅ | +25%、30%+、+10、2x、+18% |
| 7 岗位词 | ✅ | Agent/Harness/Context Engineering/SFT/RL/Benchmark |
| 8 分点 | ✅ | 四段式 |
| 9 加粗 | ✅ | 高亮词 + 数据徽章 |
| 10 人设 | ✅ | 头衔 + 公司条块 |

> **结论:同一段实习,从「参与了」变成「字节排序第一开源项目的 Owner」。这是军规的力量。**

---

## 案例 B:开源项目经历

### 普通写法

```
开源项目:
- 维护了一个 ByteDance 的开源项目,有几千 star
- 负责了一些 issue 的修复
```

### 酥神写法

```
github.com/LoFiSu · ★ 7.6k · forks 10.3k · Apache Fory Committer

项目【ByteDance/Deer-Flow】
─ 背景与目标:字节官方开源 Agent 项目(★ 7.6k / forks 10.3k)。
─ 我的职责:Maintainer,主导项目路线图与核心模块迭代。
─ 技术细节:设计多 Agent 协作协议;负责 Context Engineering 模块
  与 Middleware Chain;规范开源协作流程。
─ 数据指标:项目 Star 从 1.2k → <span class="metric">7.6k</span>,
  贡献者从 8 → <span class="metric">120+</span>,
  入选 Apache Fory(全球最年轻 Committer 之一)。
```

**变化点**:没有 star 数字 → 有具体数字;没有角色 → Maintainer;没有结果 → 增长曲线。

---

## 案例 C:一段「不相关」经历怎么办

### 原始素材

```
实习:某电商公司运营实习生(2024.01 - 2024.06)
- 协助运营做活动策划
- 整理数据报表
```

### 处理决策(展示军规的取舍逻辑)

```
❌ 直接删除?——不,先看有没有可迁移的证据
❌ 硬拗成技术岗?——不,造假
✅ 判断:若目标岗位是 AI 应用工程师 → 这段是噪音,降级为一行或删除
✅ 若目标岗位是产品/运营 → 重写为「活动 owner」+ 数据结果
```

**酥神改写(面向产品岗)**:

```
[ 某电商 - 运营部 ]    2024.01 - 2024.06
项目【618 大促活动增长方案】
─ 背景与目标:平台 618 大促,目标提升 GMV 与参与率。
─ 我的职责:【活动 Owner】0→1 策划「签到+裂变」玩法,对接设计/开发/客服。
─ 技术细节:设计活动漏斗,埋点监测转化,A/B 测试两个文案版本。
─ 数据指标:参与用户 <span class="metric">+42%</span>,
  裂变拉新 <span class="metric">+15%</span>。
```

---

## 规律总结

| 普通写法动词 | 酥神写法动词 |
|---|---|
| 参与了 | 【项目 Owner】 |
| 协助了 | 主导 |
| 学习了 | 0→1 搭建 |
| 负责了一些 | 负责 + 量化 |
| 了解 | 落地 |
| 帮忙 | 设计并推动 |

> **一句话:把「我做了什么」翻译成「我搭了什么、改了什么、涨了多少」。**