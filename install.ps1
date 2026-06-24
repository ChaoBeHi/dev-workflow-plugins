#Requires -Version 5.1

$ErrorActionPreference = "Stop"

$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path

$Skills = @(
    "dev-workflow",
    "dev-planing",
    "dev-implement",
    "dev-quality",
    "dev-delivery",
    "dev-installer"
)

$Commands = @(
    "dev-workflow"
)

# ── 平台定义 ──────────────────────────────────────────────────────────

$Platforms = @{
    "1" = @{
        Label    = "Claude Code"
        Skills   = Join-Path $HOME ".claude" "skills"
        Commands = Join-Path $HOME ".claude" "commands"
    }
    "2" = @{
        Label    = "Hermes"
        Skills   = Join-Path $HOME ".hermes" "skills"
        Commands = Join-Path $HOME ".hermes" "commands"
    }
}

# ── 平台选择 ──────────────────────────────────────────────────────────

Write-Host "dev-workflow-plugins 安装程序"
Write-Host ""
Write-Host "选择安装目标平台（可多选，空格分隔）："
Write-Host "  1. Claude Code  (~/.claude/)"
Write-Host "  2. Hermes       (~/.hermes/)"
Write-Host ""

$input = Read-Host "输入序号 [1 2 / 1]"
$selected = @()

foreach ($num in ($input -split "\s+")) {
    if ($Platforms.ContainsKey($num)) {
        $selected += $num
    } elseif ($num -ne "") {
        Write-Host "[WARN] 忽略无效序号: $num" -ForegroundColor Yellow
    }
}

if ($selected.Count -eq 0) {
    $selected = @("1")
}

Write-Host ""
Write-Host "将安装到:"
foreach ($p in $selected) {
    Write-Host "  - $($Platforms[$p].Label) ($($Platforms[$p].Skills))"
}
Write-Host ""

# ── 安装函数 ──────────────────────────────────────────────────────────

function Install-ToPlatform {
    param([string]$PlatformId)

    $label    = $Platforms[$PlatformId].Label
    $skillsDir   = $Platforms[$PlatformId].Skills
    $commandsDir = $Platforms[$PlatformId].Commands

    Write-Host "--- ${label} ---"
    Write-Host ""

    # Ensure directories exist
    foreach ($dir in @($skillsDir, $commandsDir)) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }

    $sOk = 0; $sSkip = 0; $cOk = 0; $cSkip = 0

    # 技能
    foreach ($skill in $Skills) {
        $source = Join-Path $RepoDir "skills" $skill
        $target = Join-Path $skillsDir $skill

        if (-not (Test-Path $source)) {
            Write-Host "  [FAIL] 源目录不存在: $source" -ForegroundColor Red
            continue
        }

        if (Test-Path $target) {
            Write-Host "  [SKIP] ${skill}"
            $sSkip++
            continue
        }

        try {
            New-Item -ItemType SymbolicLink -Path $target -Target $source -Force -ErrorAction Stop | Out-Null
            Write-Host "  [ OK ] ${skill}" -ForegroundColor Green
            $sOk++
        }
        catch [System.UnauthorizedAccessException] {
            try {
                Copy-Item -Path $source -Destination $target -Recurse -Force -ErrorAction Stop
                Write-Host "  [ OK ] ${skill} (copy)" -ForegroundColor Yellow
                $sOk++
            }
            catch {
                Write-Host "  [FAIL] ${skill} — $_" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "  [FAIL] ${skill} — $_" -ForegroundColor Red
        }
    }

    # 命令
    foreach ($cmd in $Commands) {
        $source = Join-Path $RepoDir "commands" "${cmd}.md"
        $target = Join-Path $commandsDir "${cmd}.md"

        if (-not (Test-Path $source)) {
            Write-Host "  [FAIL] 源文件不存在: $source" -ForegroundColor Red
            continue
        }

        if (Test-Path $target) {
            Write-Host "  [SKIP] /${cmd}"
            $cSkip++
            continue
        }

        try {
            New-Item -ItemType SymbolicLink -Path $target -Target $source -Force -ErrorAction Stop | Out-Null
            Write-Host "  [ OK ] /${cmd}" -ForegroundColor Green
            $cOk++
        }
        catch {
            try {
                Copy-Item -Path $source -Destination $target -Force -ErrorAction Stop
                Write-Host "  [ OK ] /${cmd} (copy)" -ForegroundColor Yellow
                $cOk++
            }
            catch {
                Write-Host "  [FAIL] /${cmd} — $_" -ForegroundColor Red
            }
        }
    }

    Write-Host ""
    Write-Host "  ${label}: ${sOk} 个技能, ${cOk} 个命令 | 跳过 ${sSkip} 个技能, ${cSkip} 个命令"
    Write-Host ""
}

# ── 执行安装 ──────────────────────────────────────────────────────────

foreach ($p in $selected) {
    Install-ToPlatform $p
}

# ── 使用说明 ──────────────────────────────────────────────────────────

Write-Host "使用:"
Write-Host "  技能（自然语言触发）："
Write-Host "    /dev-workflow      核心编排器"
Write-Host "    /dev-planing       规划插件"
Write-Host "    /dev-implement     实现插件"
Write-Host "    /dev-quality       质量插件"
Write-Host "    /dev-delivery      交付插件"
Write-Host "    /dev-installer     安装器"
Write-Host ""
Write-Host "  命令（显式调用）："
Write-Host "    /dev-workflow start <name>   启动完整工作流"
Write-Host "    /dev-workflow jump <phase>   跳转特定阶段"
Write-Host "    /dev-workflow resume         恢复中断的流程"
Write-Host "    /dev-workflow status         查看当前进度"

# Warn if copy was used instead of symlink
Write-Host ""
Write-Host "提示: 若显示 copy 而非 symlink，更新仓库后需重新运行本脚本。"
Write-Host "      开启 Windows 开发者模式可启用 symlink: 设置 → 开发者选项 → 开发者模式"
