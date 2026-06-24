#Requires -Version 5.1

$ErrorActionPreference = "Stop"

$SkillsDir = Join-Path $HOME ".claude" "skills"
$CommandsDir = Join-Path $HOME ".claude" "commands"
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

Write-Host "dev-workflow-plugins 安装程序"
Write-Host "目标: $SkillsDir"
Write-Host ""

# Ensure target directories exist
foreach ($dir in @($SkillsDir, $CommandsDir)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# ── 安装技能 ──────────────────────────────────────────────────────────

$installed = 0
$skipped = 0
$failed = 0

foreach ($skill in $Skills) {
    $source = Join-Path $RepoDir "skills" $skill
    $target = Join-Path $SkillsDir $skill

    if (-not (Test-Path $source)) {
        Write-Host "[FAIL] 源目录不存在: $source" -ForegroundColor Red
        $failed++
        continue
    }

    if (Test-Path $target) {
        Write-Host "[SKIP] ${skill} — 已存在"
        $skipped++
        continue
    }

    try {
        New-Item -ItemType SymbolicLink -Path $target -Target $source -Force -ErrorAction Stop | Out-Null
        Write-Host "[ OK ] ${skill} (symlink)" -ForegroundColor Green
        $installed++
    }
    catch [System.UnauthorizedAccessException] {
        try {
            Copy-Item -Path $source -Destination $target -Recurse -Force -ErrorAction Stop
            Write-Host "[ OK ] ${skill} (copy — 需要管理员权限才能创建 symlink)" -ForegroundColor Yellow
            $installed++
        }
        catch {
            Write-Host "[FAIL] ${skill} — 无法创建: $_" -ForegroundColor Red
            $failed++
        }
    }
    catch {
        Write-Host "[FAIL] ${skill} — $_" -ForegroundColor Red
        $failed++
    }
}

# ── 安装命令 ──────────────────────────────────────────────────────────

$cmd_installed = 0
$cmd_skipped = 0

foreach ($cmd in $Commands) {
    $source = Join-Path $RepoDir "commands" "${cmd}.md"
    $target = Join-Path $CommandsDir "${cmd}.md"

    if (-not (Test-Path $source)) {
        Write-Host "[FAIL] 源文件不存在: $source" -ForegroundColor Red
        continue
    }

    if (Test-Path $target) {
        Write-Host "[SKIP] /${cmd} 命令 — 已存在"
        $cmd_skipped++
        continue
    }

    try {
        New-Item -ItemType SymbolicLink -Path $target -Target $source -Force -ErrorAction Stop | Out-Null
        Write-Host "[ OK ] /${cmd} (symlink)" -ForegroundColor Green
        $cmd_installed++
    }
    catch {
        try {
            Copy-Item -Path $source -Destination $target -Force -ErrorAction Stop
            Write-Host "[ OK ] /${cmd} (copy)" -ForegroundColor Yellow
            $cmd_installed++
        }
        catch {
            Write-Host "[FAIL] /${cmd} — 无法创建: $_" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "安装完成: $installed 个技能, $cmd_installed 个命令 | 跳过: $skipped 个技能, $cmd_skipped 个命令"

Write-Host ""
Write-Host "技能:"
Write-Host "  /dev-workflow      核心编排器"
Write-Host "  /dev-planing       规划插件"
Write-Host "  /dev-implement     实现插件"
Write-Host "  /dev-quality       质量插件"
Write-Host "  /dev-delivery      交付插件"
Write-Host "  /dev-installer     安装器 (扫描本地技能生成映射)"
Write-Host ""
Write-Host "命令:"
Write-Host "  /dev-workflow start <name>   启动完整工作流"
Write-Host "  /dev-workflow jump <phase>   跳转特定阶段"
Write-Host "  /dev-workflow resume         恢复中断的流程"
Write-Host "  /dev-workflow status         查看当前进度"

# Warn if copy was used instead of symlink (updates won't auto-sync)
if ($installed -gt 0 -or $cmd_installed -gt 0) {
    Write-Host ""
    Write-Host "提示: 若显示 copy 而非 symlink，更新仓库后需重新运行本脚本。"
    Write-Host "      开启 Windows 开发者模式可启用 symlink: 设置 → 开发者选项 → 开发者模式"
}
