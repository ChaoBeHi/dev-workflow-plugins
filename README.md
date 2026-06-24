# dev-workflow-plugins

人机协作开发工作流插件集合 — 将 dev-workflow 的 11 阶段拆分为编排器 + 4 个独立插件 + 1 个安装器，团队成员可按需安装，零硬编码依赖，运行时自动匹配本地技能。

## 插件清单

| 插件 | 覆盖阶段 | 行数 | 角色 |
|------|---------|------|------|
| `dev-workflow` | 全 11 阶段 | 164 | 核心编排器（必装）：Iron Law、流程图、目录结构、阶段索引、安全边界 |
| `dw-planing` | 1-3 (input→context→planing) | 73 | 需求理解、代码库检索、方案文档模板、测试用例设计 |
| `dw-implement` | 4-5 (coding→scope-check) | 72 | 按方案编码、规范优先级、范围差异检查 |
| `dw-quality` | 6-8 (testing→fixing→retest) | 88 | 测试执行、缺陷分类、回归验证、循环熔断 |
| `dw-delivery` | 9-11 (review→output→knowledge) | 83 | 三维审查、PR 交付、ADR 知识归档 |
| `dw-installer` | — | 90 | 扫描本地 skill 目录生成阶段→技能映射文件 |

## 设计原则

- **零硬编码引用**：插件只描述"能力需求"（如"代码库检索与分析"），不写具体 skill 名。Claude 运行时根据 system-reminder 中的可用技能列表自动匹配。
- **可拆卸**：编排器 `dev-workflow` 必装，其余 4 个插件按需选择。未安装的插件对应阶段不阻塞——编排器按简述继续执行。
- **安装器可选**：`dw-installer` 扫描 `~/.claude/skills/` 生成 `.workflow/mappings.json`，提供精准的阶段→技能路由表。不运行也能工作。

## 安装

```bash
git clone git@github.com:<org>/dev-workflow-plugins.git ~/dev-workflow-plugins
cd ~/dev-workflow-plugins
./install.sh
```

`install.sh` 将每个插件的 `SKILL.md` 目录软链到 `~/.claude/skills/`，Claude Code 即时识别。

可选：运行安装器生成本地映射：

```
在 Claude Code 对话中输入 /dw-installer
```

## 更新

```bash
cd ~/dev-workflow-plugins && git pull
```

symlink 自动指向新版本，无需重新安装。

## 按需裁剪

不需要某个插件？删除对应的 symlink：

```bash
rm ~/.claude/skills/dw-quality   # 去掉质量门禁
```

## 目录结构

```
dev-workflow-plugins/
├── README.md
├── install.sh
├── dev-workflow/SKILL.md
├── dw-planing/SKILL.md
├── dw-implement/SKILL.md
├── dw-quality/SKILL.md
├── dw-delivery/SKILL.md
└── dw-installer/SKILL.md
```

## 协议

MIT
