---
name: dev-installer
description: dev-workflow 插件安装器：扫描本地 ~/.claude/skills/ 目录，分析每个 skill 的描述与内容，自动匹配到工作流阶段，生成 .workflow/mappings.json 映射文件。用户可选择是否执行扫描。
---

# 开发工作流安装器

## 功能

扫描本地 skill 目录，自动将已安装的技能映射到 dev-workflow 的 11 个阶段，生成 `.workflow/mappings.json`。

此映射文件帮助 AI 在每个阶段内精准选择最合适的执行技能，同时保持插件本身零硬编码引用。

---

## 执行流程

### Step 1: 询问用户

```
是否扫描本地 skill 目录生成阶段→技能映射？
- [Y] 是，扫描 ~/.claude/skills/ 并生成映射
- [N] 否，跳过（插件运行时 AI 自行匹配）
```

### Step 2: 扫描（用户选择 Y 时）

1. 列出 `~/.claude/skills/` 下所有子目录（排除以 `.` 开头的隐藏目录）。
2. 对每个包含 `SKILL.md` 的目录，提取：
   - `name`（frontmatter）
   - `description`（frontmatter）
   - 核心内容摘要（前 50 行）
3. 按以下关键词规则初步匹配到阶段：

| 阶段 | 匹配关键词 |
|------|-----------|
| context | 检索、搜索、分析、理解、explain、trace、context |
| planing | 方案、计划、plan、设计、design、brainstorm、架构、architect |
| coding | 编码、代码、规范、standard、pattern、implement、TDD、安全 |
| scope-check | diff、变更、范围、scope |
| testing | 测试、test、E2E、playwright、vitest、coverage |
| fixing | 调试、debug、修复、fix、排查 |
| review | 评审、review、安全、security、检查 |
| output | PR、提交、commit、分支、branch、合并、merge |
| knowledge | 记忆、memory、归档、evolve、知识 |

### Step 3: 生成映射

输出 `.workflow/mappings.json`：

```json
{
  "generated_at": "YYYY-MM-DD HH:MM",
  "source_dir": "~/.claude/skills/",
  "phases": {
    "context": ["<skill-name>", ...],
    "planing": ["<skill-name>", ...],
    "coding": ["<skill-name>", ...],
    "scope-check": [],
    "testing": ["<skill-name>", ...],
    "fixing": ["<skill-name>", ...],
    "review": ["<skill-name>", ...],
    "output": ["<skill-name>", ...],
    "knowledge": ["<skill-name>", ...]
  },
  "unmatched": ["<skill-name>", ...]
}
```

### Step 4: 报告

- 展示每个阶段匹配到的技能清单
- 标注未匹配的技能（`unmatched` 列表），供人类手动分配
- 提示：可手动编辑 `.workflow/mappings.json` 调整映射；重跑安装器会覆盖

---

## 映射文件的使用

`mappings.json` 生成后，各阶段插件运行时会检查此文件：
- 若某阶段有映射技能 → AI 优先从映射列表中选择
- 若无映射 → AI 根据阶段能力需求自行匹配

---

## 注意事项

- 安装器生成的映射是**当前快照**，skill 增删后应重跑
- `mappings.json` 应加入 `.gitignore`（属于本地环境配置）
- 团队成员各自运行安装器，生成各自的映射文件（技能库不同）
