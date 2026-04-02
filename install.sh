#!/bin/bash
# ✿ Kawaii Statusline Installer for Claude Code ✿
# Cross-platform: Linux, macOS, Windows (Git Bash / MSYS2)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
TARGET_SCRIPT="$CLAUDE_DIR/statusline.sh"
SOURCE_SCRIPT="$SCRIPT_DIR/statusline.sh"

# ─── Colors ──────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()  { echo -e "${CYAN}[INFO]${RESET} $1"; }
ok()    { echo -e "${GREEN}[OK]${RESET} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${RESET} $1"; }
err()   { echo -e "${RED}[ERROR]${RESET} $1"; exit 1; }

# ─── Pre-checks ─────────────────────────────────────────────
[ -f "$SOURCE_SCRIPT" ] || err "statusline.sh not found in $SCRIPT_DIR"

# ─── Step 1: Detect OS and install jq ───────────────────────
install_jq() {
    if command -v jq &>/dev/null; then
        ok "jq is already installed ($(jq --version))"
        return 0
    fi

    info "jq not found. Attempting to install..."
    case "$(uname -s)" in
        Linux*)
            if command -v apt-get &>/dev/null; then
                sudo apt-get update -qq && sudo apt-get install -y -qq jq
            elif command -v yum &>/dev/null; then
                sudo yum install -y jq
            elif command -v pacman &>/dev/null; then
                sudo pacman -S --noconfirm jq
            elif command -v apk &>/dev/null; then
                sudo apk add jq
            else
                err "Could not detect package manager. Please install jq manually: https://jqlang.github.io/jq/download/"
            fi
            ;;
        Darwin*)
            if command -v brew &>/dev/null; then
                brew install jq
            else
                err "Homebrew not found. Install jq via: brew install jq"
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*)
            if command -v winget &>/dev/null; then
                info "Installing jq via winget..."
                winget install jqlang.jq --accept-source-agreements --accept-package-agreements || true
                # winget installs to a path not in Git Bash's PATH, so we must copy to ~/bin
                mkdir -p "$HOME/bin"
                export PATH="$HOME/bin:$PATH"
                # Search multiple known locations for jq.exe
                JQ_EXE=""
                for search_dir in \
                    "$LOCALAPPDATA/Microsoft/WinGet/Packages" \
                    "$LOCALAPPDATA/Microsoft/WinGet/Links" \
                    "/c/ProgramData/winget/Links" \
                    "$PROGRAMFILES/jq"; do
                    [ -d "$search_dir" ] || continue
                    JQ_EXE=$(find "$search_dir" -name "jq.exe" 2>/dev/null | head -1)
                    [ -n "$JQ_EXE" ] && break
                done
                if [ -n "$JQ_EXE" ]; then
                    cp "$JQ_EXE" "$HOME/bin/jq.exe"
                    ok "jq copied to ~/bin/jq.exe"
                else
                    warn "Could not find jq.exe after winget install."
                    warn "Please manually copy jq.exe to ~/bin/:"
                    warn "  1. Find jq.exe:  find \"\$LOCALAPPDATA/Microsoft/WinGet/Packages\" -name \"jq.exe\""
                    warn "  2. Copy it:       cp <path-to-jq.exe> ~/bin/jq.exe"
                    err "jq.exe not found in known install paths. See above for manual fix."
                fi
                # Verify jq is now accessible
                if ! command -v jq &>/dev/null; then
                    warn "jq installed but not in PATH. Ensure ~/bin is in your PATH."
                    warn "The statusline script adds ~/bin to PATH automatically, but if you"
                    warn "need jq elsewhere, add this to your ~/.bashrc:"
                    warn '  export PATH="$HOME/bin:$PATH"'
                fi
            else
                err "winget not found. Please install jq manually:"
                err "  1. Download from https://jqlang.github.io/jq/download/"
                err "  2. Copy jq.exe to ~/bin/ (create the folder if needed)"
                err "  3. Re-run this installer"
            fi
            ;;
        *)
            err "Unsupported platform: $(uname -s). Please install jq manually."
            ;;
    esac

    command -v jq &>/dev/null || err "jq installation failed. Please install it manually."
    ok "jq installed ($(jq --version))"
}

# ─── Step 2: Copy statusline.sh ─────────────────────────────
install_script() {
    mkdir -p "$CLAUDE_DIR"

    if [ -f "$TARGET_SCRIPT" ]; then
        warn "~/.claude/statusline.sh already exists."
        read -r -p "Overwrite? [y/N] " answer
        case "$answer" in
            [yY]|[yY][eE][sS]) ;;
            *) info "Skipped copying statusline.sh"; return 0 ;;
        esac
    fi

    cp "$SOURCE_SCRIPT" "$TARGET_SCRIPT"
    chmod +x "$TARGET_SCRIPT"
    ok "Installed statusline.sh -> $TARGET_SCRIPT"
}

# ─── Step 3: Configure settings.json ────────────────────────
configure_settings() {
    local STATUS_LINE_CONFIG='{"type":"command","command":"bash ~/.claude/statusline.sh"}'

    if [ -f "$SETTINGS_FILE" ]; then
        # Check if statusLine is already configured
        EXISTING=$(jq -r '.statusLine.command // ""' "$SETTINGS_FILE" 2>/dev/null)
        if [ "$EXISTING" = "bash ~/.claude/statusline.sh" ]; then
            ok "settings.json already configured"
            return 0
        fi

        # Merge: only add/update the statusLine field, keep everything else
        local TMP_FILE="${SETTINGS_FILE}.tmp"
        jq --argjson sl "$STATUS_LINE_CONFIG" '.statusLine = $sl' "$SETTINGS_FILE" > "$TMP_FILE"
        mv "$TMP_FILE" "$SETTINGS_FILE"
        ok "Updated statusLine in existing settings.json (other settings preserved)"
    else
        # Create new settings.json with only statusLine
        mkdir -p "$CLAUDE_DIR"
        echo "{}" | jq --argjson sl "$STATUS_LINE_CONFIG" '.statusLine = $sl' > "$SETTINGS_FILE"
        ok "Created settings.json with statusLine config"
    fi
}

# ─── Main ────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}✿ Kawaii Statusline Installer for Claude Code ✿${RESET}"
echo ""

install_jq
install_script
configure_settings

echo ""
echo -e "${GREEN}${BOLD}Installation complete!${RESET}"
echo -e "Restart your Claude Code session to see the new status line."
echo ""
case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
        echo -e "${CYAN}Windows note:${RESET} jq.exe has been copied to ~/bin/."
        echo -e "The statusline script adds ~/bin to PATH automatically."
        echo -e "If the statusline shows no data after restart, see the README"
        echo -e "for troubleshooting: ${BOLD}Windows: jq PATH Setup${RESET} section."
        echo ""
        ;;
esac
