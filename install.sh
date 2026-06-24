#!/usr/bin/env bash
set -e

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

# ── 平台定义 ──────────────────────────────────────────────────────────

declare -A PLATFORM_LABEL
PLATFORM_LABEL[1]="Claude Code"
PLATFORM_LABEL[2]="Hermes"

declare -A PLATFORM_SKILLS
PLATFORM_SKILLS[1]="${HOME}/.claude/skills"
PLATFORM_SKILLS[2]="${HOME}/.hermes/skills"

declare -A PLATFORM_COMMANDS
PLATFORM_COMMANDS[1]="${HOME}/.claude/commands"
PLATFORM_COMMANDS[2]="${HOME}/.hermes/commands"

# ── 平台选择（TUI 多选）──────────────────────────────────────────────

# 用法: multiselect <opt1> <opt2> ...
# 返回: 全局变量 SELECTED_INDICES 数组（1-based 索引，仅选中项）
# 调用前应已打印提示文本
multiselect() {
    _opts=("$@")
    _n=${#_opts[@]}

    # 初始：仅第一个选中
    _sel=()
    for ((_i=0; _i<_n; _i++)); do _sel[$_i]=0; done
    _sel[0]=1
    _cur=0

    # 预留空间 + 锁定重绘锚点
    for ((_i=0; _i<_n+1; _i++)); do printf '\n'; done
    # 上移到预留区域第一行，保存为锚点
    printf '\033[%dA' "$((_n + 1))"
    printf '\033[s'
    printf '\033[?25l'  # 隐藏光标

    _redraw() {
        printf '\033[u'  # 恢复到锚点
        for ((_i=0; _i<_n; _i++)); do
            local _mark=" "
            [ "${_sel[$_i]}" -eq 1 ] && _mark="✔"
            printf '\033[2K\r'
            if [ "$_i" -eq "$_cur" ]; then
                printf '\033[7m  [%s] %s\033[0m\n' "$_mark" "${_opts[$_i]}"
            else
                printf '  [%s] %s\n' "$_mark" "${_opts[$_i]}"
            fi
        done
        printf '\033[2K\r'"  ↑↓ 移动  Space 选择  Enter 确认"
    }

    _redraw

    while true; do
        local _key
        IFS= read -rsn1 _key
        case "$_key" in
            $'\033')
                read -rsn2 -t 0.1 _key2 2>/dev/null || true
                case "$_key2" in
                    "[A") ((_cur--)) || true; [ "$_cur" -lt 0 ] && _cur=$((_n - 1)) ;;
                    "[B") ((_cur++)) || true; [ "$_cur" -ge "$_n" ] && _cur=0 ;;
                esac ;;
            " ")
                [ "${_sel[$_cur]}" -eq 1 ] && _sel[$_cur]=0 || _sel[$_cur]=1 ;;
            "")
                break ;;
        esac
        _redraw
    done

    # 恢复光标并确保在干净行上
    printf '\n\033[?25h\n' || true

    SELECTED_INDICES=()
    for ((_i=0; _i<_n; _i++)); do
        if [ "${_sel[$_i]}" -eq 1 ]; then
            SELECTED_INDICES+=("$((_i + 1))")
        fi
    done
}

echo "dev-workflow-plugins 安装程序"
echo ""
echo "选择安装目标平台（↑↓ 移动  Space 勾选  Enter 确认）："
echo ""

multiselect \
    "Claude Code  (~/.claude/)" \
    "Hermes       (~/.hermes/)"

SELECTED_PLATFORMS=("${SELECTED_INDICES[@]}")

if [ ${#SELECTED_PLATFORMS[@]} -eq 0 ]; then
    echo "[FAIL] 未选择任何有效平台。"
    exit 1
fi

echo ""
echo "将安装到:"
for p in "${SELECTED_PLATFORMS[@]}"; do
    echo "  - ${PLATFORM_LABEL[$p]} (${PLATFORM_SKILLS[$p]})"
done
echo ""

# ── 安装函数 ──────────────────────────────────────────────────────────

install_to_platform() {
    local platform_id="$1"
    local skills_dir="${PLATFORM_SKILLS[$platform_id]}"
    local commands_dir="${PLATFORM_COMMANDS[$platform_id]}"
    local label="${PLATFORM_LABEL[$platform_id]}"

    echo "--- ${label} ---"
    echo ""

    mkdir -p "$skills_dir"
    mkdir -p "$commands_dir"

    local s_ok=0 s_skip=0 c_ok=0 c_skip=0

    # 技能
    for skill in "${SKILLS[@]}"; do
        local source="${REPO_DIR}/skills/${skill}"
        local target="${skills_dir}/${skill}"

        if [ ! -d "$source" ]; then
            echo "  [FAIL] 源目录不存在: ${source}"
            continue
        fi

        if [ -e "$target" ]; then
            echo "  [SKIP] ${skill}"
            ((s_skip++)) || true
        else
            ln -s "$source" "$target"
            echo "  [ OK ] ${skill}"
            ((s_ok++)) || true
        fi
    done

    # 命令
    for cmd in "${COMMANDS[@]}"; do
        local source="${REPO_DIR}/commands/${cmd}.md"
        local target="${commands_dir}/${cmd}.md"

        if [ ! -f "$source" ]; then
            echo "  [FAIL] 源文件不存在: ${source}"
            continue
        fi

        if [ -e "$target" ]; then
            echo "  [SKIP] /${cmd}"
            ((c_skip++)) || true
        else
            ln -s "$source" "$target"
            echo "  [ OK ] /${cmd}"
            ((c_ok++)) || true
        fi
    done

    echo ""
    echo "  ${label}: ${s_ok} 个技能, ${c_ok} 个命令 | 跳过 ${s_skip} 个技能, ${c_skip} 个命令"
    echo ""
}

for p in "${SELECTED_PLATFORMS[@]}"; do
    install_to_platform "$p"
done

# ── 使用说明 ──────────────────────────────────────────────────────────

echo "使用:"
echo "  技能（自然语言触发）："
echo "    /dev-workflow      核心编排器"
echo "    /dev-planing       规划插件"
echo "    /dev-implement     实现插件"
echo "    /dev-quality       质量插件"
echo "    /dev-delivery      交付插件"
echo "    /dev-installer     安装器"
echo ""
echo "  命令（显式调用）："
echo "    /dev-workflow start <name>   启动完整工作流"
echo "    /dev-workflow jump <phase>   跳转特定阶段"
echo "    /dev-workflow resume         恢复中断的流程"
echo "    /dev-workflow status         查看当前进度"

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

    for skill_dir in "$skills_dir"/*/; do
        [ -d "$skill_dir" ] || continue
        local skill_md="${skill_dir}SKILL.md"
        [ -f "$skill_md" ] || continue

        local skill_name
        skill_name="$(basename "$(dirname "$skill_md")")"

        [[ " ${SKILLS[*]} " =~ " ${skill_name} " ]] && continue

        local desc
        desc=$(head -20 "$skill_md" | grep -i "^description:" | head -1 | cut -d':' -f2- | sed 's/^[[:space:]]*//')

        local matched_phases=()
        for phase in "${phases[@]}"; do
            local kw="${phase_keywords[$phase]}"
            local matched_flag=false

            echo "$skill_name" | grep -qiE "$kw" 2>/dev/null && matched_flag=true
            [ -n "$desc" ] && echo "$desc" | grep -qiE "$kw" 2>/dev/null && matched_flag=true

            $matched_flag && matched_phases+=("$phase")
        done

        if [ ${#matched_phases[@]} -gt 0 ]; then
            matched+=("${skill_name}:${matched_phases[*]}")
        else
            unmatched+=("$skill_name")
        fi
    done

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
