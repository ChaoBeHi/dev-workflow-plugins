#!/usr/bin/env bash
set -e

SKILLS_DIR="${HOME}/.claude/skills"
COMMANDS_DIR="${HOME}/.claude/commands"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

SKILLS=(
    dev-workflow
    dev-planing
    dev-implement
    dev-quality
    dev-delivery
    dev-installer
)

COMMANDS=(
    dev-workflow
)

echo "dev-workflow-plugins 安装程序"
echo "目标: ${SKILLS_DIR}"
echo ""

# ── 安装技能 ──────────────────────────────────────────────────────────

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

# ── 安装命令 ──────────────────────────────────────────────────────────

cmd_installed=0
cmd_skipped=0

for cmd in "${COMMANDS[@]}"; do
    source="${REPO_DIR}/commands/${cmd}.md"
    target="${COMMANDS_DIR}/${cmd}.md"

    if [ ! -f "$source" ]; then
        echo "[FAIL] 源文件不存在: ${source}"
        continue
    fi

    if [ -e "$target" ]; then
        echo "[SKIP] /${cmd} 命令 — 已存在"
        ((cmd_skipped++)) || true
    else
        ln -s "$source" "$target"
        echo "[ OK ] /${cmd} → ${target}"
        ((cmd_installed++)) || true
    fi
done

echo ""
echo "安装完成: ${installed} 个技能, ${cmd_installed} 个命令 | 跳过: ${skipped} 个技能, ${cmd_skipped} 个命令"
echo ""
echo "技能:"
echo "  /dev-workflow      核心编排器"
echo "  /dev-planing       规划插件"
echo "  /dev-implement     实现插件"
echo "  /dev-quality       质量插件"
echo "  /dev-delivery      交付插件"
echo "  /dev-installer     安装器 (扫描本地技能生成映射)"
echo ""
echo "命令:"
echo "  /dev-workflow start <name>   启动完整工作流"
echo "  /dev-workflow jump <phase>   跳转特定阶段"
echo "  /dev-workflow resume         恢复中断的流程"
echo "  /dev-workflow status         查看当前进度"

# ── 扫描全局技能库生成阶段映射 ──────────────────────────────────────────

scan_and_map() {
    local skills_dir="${HOME}/.claude/skills"
    local mappings_file="${REPO_DIR}/.workflow/mappings.json"

    if [ ! -d "$skills_dir" ]; then
        echo "[SKIP] 技能目录不存在: ${skills_dir}"
        return
    fi

    echo ""
    echo "正在扫描 ${skills_dir} ..."

    # 阶段→关键词映射
    declare -A phase_keywords
    phase_keywords[context]="检索|搜索|代码分析|上下文"
    phase_keywords[planing]="方案|计划|设计系统|brainstorm|架构|\\barchitect\\b|\\bdesign\\b"
    phase_keywords[coding]="编码|代码风格|代码规范|\\bstandard\\b|\\bimplement\\b|TDD"
    phase_keywords[scope-check]="\\bdiff\\b|变更范围|\\bscope\\b"
    phase_keywords[testing]="测试|E2E|playwright|vitest|\\bcoverage\\b"
    phase_keywords[fixing]="调试|debug|修复|排查|troubleshoot"
    phase_keywords[review]="评审|\\breview\\b|security|漏洞|\\baudit\\b"
    phase_keywords[output]="PR|提交规范|\\bcommit\\b|分支管理|合并|\\bmerge\\b"
    phase_keywords[knowledge]="记忆|\\bmemory\\b|归档|\\bevolve\\b|知识管理"

    local phases=(context planing coding scope-check testing fixing review output knowledge)
    local matched=()
    local unmatched=()

    # 遍历技能目录
    for skill_dir in "$skills_dir"/*/; do
        [ -d "$skill_dir" ] || continue
        local skill_md="${skill_dir}SKILL.md"
        [ -f "$skill_md" ] || continue

        local skill_name
        skill_name="$(basename "$(dirname "$skill_md")")"

        # 跳过 dev-workflow 自身的技能
        [[ " ${SKILLS[*]} " =~ " ${skill_name} " ]] && continue

        # 提取 description（frontmatter 中 description: 后的内容）
        local desc
        desc=$(head -20 "$skill_md" | grep -i "^description:" | head -1 | cut -d':' -f2- | sed 's/^[[:space:]]*//')

        # 匹配阶段：检查技能名 + description
        local matched_phases=()
        for phase in "${phases[@]}"; do
            local kw="${phase_keywords[$phase]}"
            local matched_flag=false

            # 技能目录名
            echo "$skill_name" | grep -qiE "$kw" 2>/dev/null && matched_flag=true
            # description
            [ -n "$desc" ] && echo "$desc" | grep -qiE "$kw" 2>/dev/null && matched_flag=true

            $matched_flag && matched_phases+=("$phase")
        done

        if [ ${#matched_phases[@]} -gt 0 ]; then
            matched+=("${skill_name}:${matched_phases[*]}")
        else
            unmatched+=("$skill_name")
        fi
    done

    # 生成 mappings.json
    mkdir -p "$(dirname "$mappings_file")"

    echo '{' > "$mappings_file"
    echo "  \"generated_at\": \"$(date '+%Y-%m-%d %H:%M')\"," >> "$mappings_file"
    echo "  \"source_dir\": \"${skills_dir}\"," >> "$mappings_file"
    echo "  \"phases\": {" >> "$mappings_file"

    for i in "${!phases[@]}"; do
        local phase="${phases[$i]}"
        local skills_for_phase=()
        for entry in "${matched[@]}"; do
            local name="${entry%%:*}"
            local entry_phases="${entry#*:}"
            if echo "$entry_phases" | grep -qw "$phase"; then
                skills_for_phase+=("$name")
            fi
        done

        local json_array="["
        local first=true
        for s in "${skills_for_phase[@]}"; do
            if $first; then
                json_array+="\"$s\""
                first=false
            else
                json_array+=", \"$s\""
            fi
        done
        json_array+="]"

        local comma=","
        [ "$i" -eq $((${#phases[@]} - 1)) ] && comma=""
        echo "    \"$phase\": $json_array${comma}" >> "$mappings_file"
    done

    echo "  }," >> "$mappings_file"

    # unmatched
    local unmatched_json="["
    local first=true
    for u in "${unmatched[@]}"; do
        if $first; then
            unmatched_json+="\"$u\""
            first=false
        else
            unmatched_json+=", \"$u\""
        fi
    done
    unmatched_json+="]"
    echo "  \"unmatched\": $unmatched_json" >> "$mappings_file"
    echo '}' >> "$mappings_file"

    # 报告
    echo ""
    echo "映射结果:"
    for phase in "${phases[@]}"; do
        local count=0
        for entry in "${matched[@]}"; do
            local entry_phases="${entry#*:}"
            if echo "$entry_phases" | grep -qw "$phase"; then
                ((count++)) || true
            fi
        done
        printf "  %-12s %d 个技能\n" "${phase}:" "$count"
    done

    if [ ${#unmatched[@]} -gt 0 ]; then
        echo ""
        echo "未匹配 (${#unmatched[@]} 个): ${unmatched[*]}"
    fi

    echo ""
    echo "映射文件: ${mappings_file}"
}

echo ""
read -r -p "是否扫描本地全局技能库生成阶段→技能映射？[Y/n] " answer
case "${answer:-Y}" in
    [Yy]|[Yy][Ee][Ss]) scan_and_map ;;
    *) echo "[SKIP] 跳过扫描。可稍后通过 /dev-installer 生成映射。" ;;
esac
