---
name: dev-installer
description: 当用户请求"扫描技能"、"生成技能映射"、"安装 dev-workflow 插件"或需要扫描本地 Claude Code 技能目录并生成阶段→技能映射文件时，应使用此技能。
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
3. 按以下关键词规则初步匹配到阶段（匹配技能目录名 + description，不扫正文）：

| 阶段 | 匹配关键词 |
|------|-----------|
| context | 检索、搜索、代码分析、上下文 |
| planing | 方案、计划、设计系统、brainstorm、架构、architect（全词）、design（全词） |
| coding | 编码、代码风格、代码规范、standard（全词）、implement（全词）、TDD |
| scope-check | diff（全词）、变更范围、scope（全词） |
| testing | 测试、E2E、playwright、vitest、coverage（全词） |
| fixing | 调试、debug、修复、排查、troubleshoot |
| review | 评审、review（全词）、security、漏洞、audit（全词） |
| output | PR、提交规范、commit（全词）、分支管理、合并、merge（全词） |
| knowledge | 记忆、memory（全词）、归档、evolve（全词）、知识管理 |

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
- 若某阶段有映射技能 → 优先从映射列表中选择
- 若无映射 → 根据阶段能力需求自动匹配

---

## 注意事项

- 安装器生成的映射是**当前快照**，skill 增删后应重跑
- `mappings.json` 应加入 `.gitignore`（属于本地环境配置）
- 团队成员各自运行安装器，生成各自的映射文件（技能库不同）
