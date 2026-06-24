#!/usr/bin/env bash
set -e

SKILLS_DIR="${HOME}/.claude/skills"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

SKILLS=(
    dev-workflow
    dev-planing
    dev-implement
    dev-quality
    dev-delivery
    dev-installer
)

echo "dev-workflow-plugins 安装程序"
echo "目标: ${SKILLS_DIR}"
echo ""

installed=0
skipped=0

for skill in "${SKILLS[@]}"; do
    source="${REPO_DIR}/skills/${skill}"
    target="${SKILLS_DIR}/${skill}"

    if [ ! -d "$source" ]; then
        echo "[FAIL] 源目录不存在: ${source}"
        continue
    fi

    if [ -e "$target" ]; then
        echo "[SKIP] ${skill} — 已存在"
        ((skipped++)) || true
    else
        ln -s "$source" "$target"
        echo "[ OK ] ${skill} → ${target}"
        ((installed++)) || true
    fi
done

echo ""
echo "安装完成: ${installed} 个新装, ${skipped} 个跳过"
echo ""
echo "可调用:"
echo "  /dev-workflow      核心编排器"
echo "  /dev-planing       规划插件"
echo "  /dev-implement     实现插件"
echo "  /dev-quality       质量插件"
echo "  /dev-delivery      交付插件"
echo "  /dev-installer     安装器 (扫描本地技能生成映射)"
