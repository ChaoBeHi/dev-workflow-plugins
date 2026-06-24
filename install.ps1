#Requires -Version 5.1

$ErrorActionPreference = "Stop"

$SkillsDir = Join-Path $HOME ".claude" "skills"
$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path

$Skills = @(
    "dev-workflow",
    "dev-planing",
    "dev-implement",
    "dev-quality",
    "dev-delivery",
    "dev-installer"
)

Write-Host "dev-workflow-plugins 安装程序"
Write-Host "目标: $SkillsDir"
Write-Host ""

# Ensure target directory exists
if (-not (Test-Path $SkillsDir)) {
    New-Item -ItemType Directory -Path $SkillsDir -Force | Out-Null
}

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
        # Try symlink first (requires Developer Mode or admin on Windows)
        New-Item -ItemType SymbolicLink -Path $target -Target $source -Force -ErrorAction Stop | Out-Null
        Write-Host "[ OK ] ${skill} (symlink)" -ForegroundColor Green
        $installed++
    }
    catch [System.UnauthorizedAccessException] {
        # Fallback: copy directory (no symlink privilege)
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

Write-Host ""
Write-Host "安装完成: $installed 个新装, $skipped 个跳过" $(if ($failed -gt 0) { ", $failed 个失败" })

if ($installed -gt 0) {
    Write-Host ""
    Write-Host "可调用:"
    Write-Host "  /dev-workflow      核心编排器"
    Write-Host "  /dev-planing       规划插件"
    Write-Host "  /dev-implement     实现插件"
    Write-Host "  /dev-quality       质量插件"
    Write-Host "  /dev-delivery      交付插件"
    Write-Host "  /dev-installer     安装器 (扫描本地技能生成映射)"
}

# Warn if copy was used instead of symlink (updates won't auto-sync)
if ($installed -gt 0) {
    Write-Host ""
    Write-Host "提示: 若显示 copy 而非 symlink，更新仓库后需重新运行本脚本。"
    Write-Host "      开启 Windows 开发者模式可启用 symlink: 设置 → 开发者选项 → 开发者模式"
}
