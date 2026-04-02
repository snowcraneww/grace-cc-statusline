#!/bin/bash
# ✿ Kawaii Statusline v7 for Claude Code ✿
# Light/white bg | 2 lines | uniform color bar
# Fixed: single jq call, cumulative tokens, git cache, null handling

export PATH="$HOME/bin:$PATH"

input=$(cat)

# ─── Single jq extraction (perf: 1 fork instead of 10+) ─────
IFS=$'\t' read -r MODEL CWD_RAW CONTEXT_SIZE NATIVE_PCT \
     CU_INPUT CU_OUTPUT CU_CACHE_R CU_CACHE_C \
     TOTAL_IN TOTAL_OUT COST_RAW HAS_CU <<< "$(
  echo "$input" | jq -r '[
    (.model.display_name // .model.id // "Unknown"),
    (.workspace.current_dir // .cwd // "."),
    (.context_window.context_window_size // 200000 | tostring),
    (.context_window.used_percentage // "" | tostring),
    (if .context_window.current_usage == null then "0"
     else (.context_window.current_usage.input_tokens // 0 | tostring) end),
    (if .context_window.current_usage == null then "0"
     else (.context_window.current_usage.output_tokens // 0 | tostring) end),
    (if .context_window.current_usage == null then "0"
     else (.context_window.current_usage.cache_read_input_tokens // 0 | tostring) end),
    (if .context_window.current_usage == null then "0"
     else (.context_window.current_usage.cache_creation_input_tokens // 0 | tostring) end),
    (.context_window.total_input_tokens // 0 | tostring),
    (.context_window.total_output_tokens // 0 | tostring),
    (.cost.total_cost_usd // "" | tostring),
    (if .context_window.current_usage == null then "false" else "true" end)
  ] | join("\t")'
)"

CWD="$CWD_RAW"
# Handle both Windows backslash and Unix forward slash paths
PROJECT="$(basename "$(echo "$CWD" | tr '\\' '/')")"

# ─── Context % (prefer native, fallback to current_usage calc) ─
if [ -n "$NATIVE_PCT" ] && [ "$NATIVE_PCT" != "null" ] && [ "$NATIVE_PCT" != "" ]; then
    PCT=$(awk "BEGIN {printf \"%d\", $NATIVE_PCT}")
elif [ "$HAS_CU" = "true" ]; then
    TOT=$((CU_INPUT + CU_CACHE_R + CU_CACHE_C))
    [ "$CONTEXT_SIZE" -gt 0 ] 2>/dev/null && PCT=$((TOT * 100 / CONTEXT_SIZE)) || PCT=0
else
    PCT=0
fi
PCT=$((PCT < 0 ? 0 : (PCT > 100 ? 100 : PCT)))

# ─── Token display: use CUMULATIVE session totals (these actually grow!) ─
IN_T=${TOTAL_IN:-0}
OUT_T=${TOTAL_OUT:-0}
CACHE_R=${CU_CACHE_R:-0}
CACHE_C=${CU_CACHE_C:-0}

fmt() {
    local n=$1
    if [ "$n" -ge 1000000 ] 2>/dev/null; then awk "BEGIN {printf \"%.1fM\", $n/1000000}"
    elif [ "$n" -ge 1000 ] 2>/dev/null; then awk "BEGIN {printf \"%.1fk\", $n/1000}"
    else echo "${n:-0}"; fi
}

# ─── Colors (white bg) ─────────────────────────────────────
HP='\033[38;5;199m'; RO='\033[38;5;211m'; PU='\033[38;5;135m'
LV='\033[38;5;141m'; BL='\033[38;5;33m';  CY='\033[38;5;37m'
TL='\033[38;5;30m';  GR='\033[38;5;35m'
YE='\033[38;5;178m'; OR='\033[38;5;208m';  RD='\033[38;5;196m'
CO='\033[38;5;209m'; GY='\033[38;5;245m'
B='\033[1m'; D='\033[2m'; R='\033[0m'

# ─── Model icon ─────────────────────────────────────────────
case "$MODEL" in
    *Opus*|*opus*)     MI="🎵"; MC="$PU" ;;
    *Sonnet*|*sonnet*) MI="📝"; MC="$BL" ;;
    *Haiku*|*haiku*)   MI="🍃"; MC="$GR" ;;
    *)                 MI="🤖"; MC="$CY" ;;
esac

# ─── Skills / Plugins / MCP counts ──────────────────────────
US=0; [ -d "$HOME/.claude/skills" ] && US=$(ls -1 "$HOME/.claude/skills/" 2>/dev/null | wc -l)
PL=0; PL_FILE="$HOME/.claude/plugins/installed_plugins.json"
[ -f "$PL_FILE" ] && PL=$(jq '.plugins | length' "$PL_FILE" 2>/dev/null || echo 0)
MN=0
for f in "$CWD/.mcp.json" "$HOME/.claude/settings.local.json" "$CWD/.claude/settings.local.json"; do
    if [ -f "$f" ]; then
        c=$(jq '.mcpServers | length' "$f" 2>/dev/null || echo 0)
        MN=$((MN + c))
    fi
done

# ═══════════════════════════════════════════════════════════════
# Line 1: Model + Project + Skills/Plugins/MCP
# ═══════════════════════════════════════════════════════════════
echo -e "${HP}${B}✿${R} ${MC}${B}${MI} ${MODEL}${R} ${GY}│${R} ${TL}📂 ${B}${PROJECT}${R} ${GY}│${R} ${RO}🎀 ${B}${US}${R}${D}skills${R} ${CY}🔌 ${B}${PL}${R}${D}plugins${R} ${TL}🌐 ${B}${MN}${R}${D}mcp${R}"

# ═══════════════════════════════════════════════════════════════
# Line 2: Context bar + Tokens + Git branch & status
# ═══════════════════════════════════════════════════════════════

# Bar: 20 wide, uniform color shifts with usage
BAR_W=20
FILLED=$((PCT * BAR_W / 100))

if [ "$PCT" -ge 85 ]; then
    PI="🔥"; BC="$RD"; PC="$RD"
elif [ "$PCT" -ge 60 ]; then
    PI="⚡"; BC="$OR"; PC="$OR"
elif [ "$PCT" -ge 30 ]; then
    PI="🧠"; BC="$BL"; PC="$BL"
else
    PI="🌱"; BC="$GR"; PC="$GR"
fi

BAR=""
for ((i=0; i<FILLED; i++)); do BAR+="█"; done
for ((i=FILLED; i<BAR_W; i++)); do BAR+="░"; done

# ─── Git branch + status (cached, 5s TTL) ───────────────────
GIT_CACHE="/tmp/claude-statusline-git-cache"
GIT_CACHE_TTL=5
GIT_PART=""

if git -C "$CWD" rev-parse --git-dir > /dev/null 2>&1; then
    NEED_REFRESH=true
    if [ -f "$GIT_CACHE" ]; then
        case "$(uname -s)" in
            Darwin) CACHE_MTIME=$(stat -f %m "$GIT_CACHE" 2>/dev/null || echo 0) ;;
            *)      CACHE_MTIME=$(stat -c %Y "$GIT_CACHE" 2>/dev/null || echo 0) ;;
        esac
        CACHE_AGE=$(( $(date +%s) - CACHE_MTIME ))
        [ "$CACHE_AGE" -lt "$GIT_CACHE_TTL" ] && NEED_REFRESH=false
    fi

    if $NEED_REFRESH; then
        BR=$(git -C "$CWD" branch --show-current 2>/dev/null)
        GS=$(git -C "$CWD" status --porcelain 2>/dev/null)
        MOD=$(echo "$GS" | grep -c '^ M\|^MM\|^ T' 2>/dev/null || echo 0)
        DEL=$(echo "$GS" | grep -c '^ D\|^D ' 2>/dev/null || echo 0)
        UNT=$(echo "$GS" | grep -c '^??' 2>/dev/null || echo 0)
        STG=$(echo "$GS" | grep -c '^[MADRC]' 2>/dev/null || echo 0)

        UP=$(git -C "$CWD" rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)
        AH=0; BH=0
        if [ -n "$UP" ]; then
            AH=$(git -C "$CWD" rev-list --count '@{upstream}..HEAD' 2>/dev/null || echo 0)
            BH=$(git -C "$CWD" rev-list --count 'HEAD..@{upstream}' 2>/dev/null || echo 0)
        fi

        # Save to cache
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s' "$BR" "$MOD" "$DEL" "$UNT" "$STG" "$AH" "$BH" > "$GIT_CACHE"
    fi

    # Read from cache
    IFS=$'\t' read -r BR MOD DEL UNT STG AH BH < "$GIT_CACHE"

    [ -n "$BR" ] && GIT_PART+="${LV}🌿 ${B}${BR}${R}"
    GP=""
    [ "$MOD" -gt 0 ] 2>/dev/null && GP+="${YE}✏️ ${MOD}${R} "
    [ "$DEL" -gt 0 ] 2>/dev/null && GP+="${RD}🗑${DEL}${R} "
    [ "$UNT" -gt 0 ] 2>/dev/null && GP+="${GY}❓${UNT}${R} "
    [ "$STG" -gt 0 ] 2>/dev/null && GP+="${CY}📦${STG}${R} "
    [ "$AH" -gt 0 ] 2>/dev/null && GP+="${PU}⬆${AH}${R} "
    [ "$BH" -gt 0 ] 2>/dev/null && GP+="${CO}⬇${BH}${R} "

    [ -n "$GP" ] && GIT_PART+=" ${GP}" || GIT_PART+=" ${GR}✨${R}"
    GIT_PART=" ${GY}│${R} ${GIT_PART}"
fi

# ─── Cache + Cost (only if present) ─────────────────────────
EXTRA=""
TC=$((CACHE_R + CACHE_C))
[ "$TC" -gt 0 ] 2>/dev/null && EXTRA+=" ${GY}│${R} ${PU}💾 $(fmt $CACHE_R)r $(fmt $CACHE_C)w${R}"
if [ -n "$COST_RAW" ] && [ "$COST_RAW" != "null" ] && [ "$COST_RAW" != "" ]; then
    COST_FMT=$(printf '$%.4f' "$COST_RAW" 2>/dev/null || echo "\$$COST_RAW")
    EXTRA+=" ${GY}│${R} ${YE}💰 ${COST_FMT}${R}"
fi

echo -e "  ${PI} ${BC}${BAR}${R} ${PC}${B}${PCT}%${R} ${GY}│${R} ${GR}📥 $(fmt $IN_T)${R} ${BL}📤 $(fmt $OUT_T)${R}${EXTRA}${GIT_PART}"
