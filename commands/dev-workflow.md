---
description: 人机协作开发工作流入口 — start 启动完整流程、jump 跳转特定阶段、resume 恢复中断、status 查看进度
argument-hint: <action> [phase-name | feature-name]
allowed-tools: ["Read", "Write", "Bash", "Skill", "AskUserQuestion"]
---

# /dev-workflow

核心编排入口。不重复 SKILL.md 的流程细节，只做参数解析和阶段路由。

**指令来源**：`skills/dev-workflow/SKILL.md` 的 Iron Law 和阶段索引表是本命令的权威参考。

---

## 用法

```
/dev-workflow start <feature-name>    从 input 阶段启动完整 11 阶段流程
/dev-workflow resume                  恢复上次中断的阶段（读取 .workflow/ 下最新文件推断）
/dev-workflow jump <phase-name>       跳转到指定阶段的 🚨Checkpoint，执行该阶段后停止
/dev-workflow status                  查看当前工作流状态（当前阶段、已完成阶段、产出文件）
```

---

## jump 阶段映射

解析 `$ARGUMENTS` 中的阶段名称，加载对应插件并进入 Checkpoint：

| 阶段 | 插件 | 进入行为 |
|------|------|----------|
| `input` | dev-planing | 复述需求 → 🚨等待人类确认 |
| `context` | dev-planing | 代码库检索 → 输出检索摘要 → 有阻塞点则暂停 |
| `planing` | dev-planing | 方案规划 → 🚨方案评审 → 🚨用例评审 |
| `coding` | dev-implement | 按方案编码，不扩展范围 |
| `scope-check` | dev-implement | 变更范围一致性校验 → 有差异则报告 |
| `testing` | dev-quality | 执行测试用例 → 产出测试报告 |
| `fixing` | dev-quality | 缺陷分类与修复 → 非轻量修复需人类评审 |
| `retest` | dev-quality | 回归验证 → 循环熔断检查 |
| `review` | dev-delivery | 设计/逻辑/安全三维审查 → 严重问题则暂停 |
| `output` | dev-delivery | 代码落地、PR、最终报告 → 🚨人类确认合并 |
| `knowledge` | dev-delivery | ADR 归档与记忆更新 |

**执行规则**：
1. 用 `Skill` 工具加载对应插件，获取该阶段的完整执行指令
2. 执行该阶段的步骤，在 🚨Checkpoint 处停下来等待人类决策
3. **不自动进入下一阶段**——jump 只执行一个阶段后停止

---

## status 逻辑

1. 检查 `.workflow/` 目录是否存在
2. 列出已有产出文件及其对应阶段：
   - `plans/` → planing 已完成
   - `tests/cases/` → 用例已编写
   - `tests/reports/` → 测试已执行
   - `review/` → review 已完成
   - `knowledge/decisions/` → ADR 已归档
   - `reports/` → 最终报告已产出
3. 推断当前阶段并报告

---

## resume 逻辑

1. 读取 `.workflow/` 下最新修改的文件，推断中断前所在的阶段
2. 若无 `.workflow/` 目录或无产出文件 → 提示"无进行中的工作流，请使用 start 启动"
3. 从该阶段的 🚨Checkpoint 处继续（不是从头执行该阶段）

---

## 安全约束

- `start` 和 `resume` 遵循 `skills/dev-workflow/SKILL.md` 的完整 Iron Law
- `jump` 跳过的前置阶段可能留下未完成的前提工作，执行前提示人类确认
