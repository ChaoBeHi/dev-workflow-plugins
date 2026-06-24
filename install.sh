#!/usr/bin/env bash
set -e

SKILLS_DIR="${HOME}/.claude/skills"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

SKILLS=(
    dev-workflow
    dw-planing
    dw-implement
    dw-quality
    dw-delivery
    dw-installer
)

echo "dev-workflow-plugins 安装程序"
echo "目标目录: ${SKILLS_DIR}"
echo ""

installed=0
skipped=0

for skill in "${SKILLS[@]}"; do
    source="${REPO_DIR}/${skill}"
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
echo "提示: 在 Claude Code 对话中输入 /dw-installer 可扫描本地技能生成映射文件"
