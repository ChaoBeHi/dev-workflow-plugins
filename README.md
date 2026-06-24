# dev-workflow-plugins

人机协作开发工作流插件集合 — 将 dev-workflow 的 11 阶段拆分为编排器 + 4 个独立插件 + 1 个安装器，团队成员可按需安装，零硬编码依赖，运行时自动匹配本地技能。

## 安装

### Linux / macOS

```bash
git clone git@github.com:ChaoBeHi/dev-workflow-plugins.git ~/dev-workflow-plugins
~/dev-workflow-plugins/install.sh
```

### Windows (PowerShell)

```powershell
git clone git@github.com:ChaoBeHi/dev-workflow-plugins.git $HOME\dev-workflow-plugins
$HOME\dev-workflow-plugins\install.ps1
```

### Windows (CMD)

```cmd
git clone git@github.com:ChaoBeHi/dev-workflow-plugins.git %USERPROFILE%\dev-workflow-plugins
powershell -File %USERPROFILE%\dev-workflow-plugins\install.ps1
```

> Windows 建议开启开发者模式（设置 → 开发者选项）以启用 symlink；否则自动退化为文件复制。

重启 Claude Code 即可使用。

## 使用

```
/dev-workflow       核心编排器
/dev-planing         规划插件
/dev-implement       实现插件
/dev-quality         质量插件
/dev-delivery        交付插件
/dev-installer       安装器 (扫描本地技能生成映射)
```

## 插件清单

| 技能 | 覆盖阶段 | 行数 | 角色 |
|------|---------|------|------|
| `dev-workflow` | 全 11 阶段 | 164 | 核心编排器：Iron Law、流程图、阶段索引、安全边界 |
| `dev-planing` | 1-3 (input→context→planing) | 73 | 需求理解、代码库检索、方案模板、用例设计 |
| `dev-implement` | 4-5 (coding→scope-check) | 72 | 按方案编码、规范优先级、范围差异检查 |
| `dev-quality` | 6-8 (testing→fixing→retest) | 88 | 测试执行、缺陷分类、回归验证、循环熔断 |
| `dev-delivery` | 9-11 (review→output→knowledge) | 83 | 三维审查、PR 交付、ADR 知识归档 |
| `dev-installer` | — | 90 | 扫描本地 skill 生成阶段→技能映射文件 |

## 设计原则

- **零硬编码引用**：插件只描述"能力需求"，不写具体 skill 名。Claude 运行时从 system-reminder 自动匹配。
- **可拆卸**：`dev-workflow` 必装，其余 4 个插件按需选择。未安装的对应阶段不阻塞。
- **安装器可选**：`dev-installer` 扫描本地 skill 目录生成 `.workflow/mappings.json`，提供精准的阶段→技能路由。

## 更新

```bash
cd ~/dev-workflow-plugins && git pull
```

- **symlink 用户**（Linux/macOS/Windows 开发者模式）：`git pull` 后自动生效，无需额外操作。
- **复制模式用户**（Windows 非开发者模式）：`git pull` 后需重新运行安装脚本以同步文件：

  ```powershell
  $HOME\dev-workflow-plugins\install.ps1
  ```

## 目录结构

```
dev-workflow-plugins/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── dev-workflow/SKILL.md
│   ├── dev-planing/SKILL.md
│   ├── dev-implement/SKILL.md
│   ├── dev-quality/SKILL.md
│   ├── dev-delivery/SKILL.md
│   └── dev-installer/SKILL.md
├── install.sh     (Linux/macOS)
├── install.ps1    (Windows PowerShell)
└── README.md
```

## 协议

MIT
