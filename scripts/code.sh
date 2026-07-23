#!/usr/bin/env bash
#
# code.sh — jump into (or create) a tmux project session with a standard
# set of windows: terminal, code, ai.
#
# Usage:
#   code.sh [-t|--terminal-only] [project-name]
#
# Layout:
#   ~/projects/<...>/<project>/   any depth; a folder is a project iff it
#                                 contains a .git directory. Discovery is
#                                 recursive and prunes the names listed in
#                                 DISCOVER_PRUNE (never descends into
#                                 node_modules, src, etc.).
#
# Source this file (e.g. from ~/.bashrc) to also get tab-completion:
#   source ~/bin/code.sh

BASE_DIR="$HOME/projects"

# Directory names discovery will never traverse into. These are common
# source/dependency/build folders that live *inside* a project (whose .git
# already marks the root) or would just slow the scan / surface nested
# submodule repos we don't want as top-level projects.
DISCOVER_PRUNE=(
    node_modules .next .turbo .cache dist build target out
    vendor .venv venv __pycache__ .pytest_cache .mypy_cache .tox
    .idea .vscode .direnv .terraform
    src internal cmd pkg api test tests docs examples scripts bin
    archive # personal preference: don't want to see old archived projects
)

WINDOW_ORDER=(
    terminal code ai
    # git
    # http
)
declare -A WINDOW_CMD=(
    [code]='nvim'
    [ai]='opencode'
    # [git]='lazygit'
    # [http]='posting -c requests'
)

declare -A PROJECT_PATHS
VALID_PROJECTS=()

parse_args() {
    TERMINAL_ONLY=0
    TARGET_PROJECT=""

    while [ $# -gt 0 ]; do
        case "$1" in
            -t|--terminal-only)
                TERMINAL_ONLY=1
                ;;
            -*)
                echo "Usage: code.sh [-t|--terminal-only] [project-name]" >&2
                exit 2
                ;;
            *)
                if [ -n "$TARGET_PROJECT" ]; then
                    echo "Usage: code.sh [-t|--terminal-only] [project-name]" >&2
                    exit 2
                fi
                TARGET_PROJECT="$1"
                ;;
        esac
        shift
    done

    if [ "$TERMINAL_ONLY" -eq 1 ]; then
        WINDOW_ORDER=(terminal)
    fi
}

# ---------------------------------------------------------------------------
# Discovery: populate VALID_PROJECTS / PROJECT_PATHS from BASE_DIR
# ---------------------------------------------------------------------------
discover_projects() {
    local entry name p first=1
    local -a prune=()

    VALID_PROJECTS=()
    PROJECT_PATHS=()

    # Build a find prune expression: -name X -o -name Y -o ... -name Z
    for p in "${DISCOVER_PRUNE[@]}"; do
        [ $first -eq 1 ] && first=0 || prune+=(-o)
        prune+=(-name "$p")
    done

    # Recursively locate .git directories; each one's parent is a project
    # root. Pruned names are skipped, and matched .git dirs are themselves
    # pruned (-print -prune) so find never descends into their internals.
    while IFS= read -r entry; do
        [ -z "$entry" ] && continue
        entry="$(dirname "$entry")"
        name="$(basename "$entry")"
        # first occurrence wins; avoids duplicate completion entries when
        # two projects share a basename (e.g. work/foo, personal/foo)
        [ -n "${PROJECT_PATHS[$name]:-}" ] && continue
        VALID_PROJECTS+=("$name")
        PROJECT_PATHS["$name"]="$entry"
    done < <(find "$BASE_DIR" \( "${prune[@]}" \) -prune \
                -o -type d -name .git -print -prune 2>/dev/null)
}

is_valid_project() {
    local candidate="$1" name
    for name in "${VALID_PROJECTS[@]}"; do
        [ "$name" = "$candidate" ] && return 0
    done
    return 1
}

# ---------------------------------------------------------------------------
# Bash completion (only runs when this file is *sourced*, not executed)
# ---------------------------------------------------------------------------
setup_completion() {
    if [ -n "$ZSH_VERSION" ]; then
        # Substring matches (e.g. `vi` -> nvim, viject) share no common
        # prefix, so zsh's default unambiguous-prefix insertion shows nothing
        # on the first Tab. `menu select` drops straight into a selectable,
        # cyclable list instead of waiting for a second Tab.
        zstyle ':completion:*:*:code:*'    menu select
        zstyle ':completion:*:*:code.sh:*' menu select

        _code_completions() {
            local cur="${words[CURRENT]}" name
            local -a matches
            for name in "${VALID_PROJECTS[@]}"; do
                [[ "$name" == *"$cur"* ]] && matches+=("$name")
            done
            compadd -U -- "${matches[@]}"
        }
        compdef _code_completions code.sh
        compdef _code_completions code
    elif [ -n "$BASH_VERSION" ]; then
        _code_completions() {
            local cur name
            cur="${COMP_WORDS[COMP_CWORD]}"
            COMPREPLY=()
            for name in "${VALID_PROJECTS[@]}"; do
                [[ "$name" == *"$cur"* ]] && COMPREPLY+=("$name")
            done
        }
        complete -F _code_completions code.sh
        complete -F _code_completions code
    fi
}

if (return 0 2>/dev/null); then
    discover_projects
    setup_completion
    return 0
fi

# ---------------------------------------------------------------------------
# New-project creation flow
# ---------------------------------------------------------------------------
prompt_create_project() {
    local project="$1" reply project_dir

    read -r -p "Project '$project' does not exist. Create it at $BASE_DIR/$project? [y/N] " reply
    case "$reply" in
        [yY][eE][sS]|[yY]) ;;
        *)
            echo "Aborted. Valid options are: ${VALID_PROJECTS[*]}"
            exit 1
            ;;
    esac

    project_dir="$BASE_DIR/$project"
    if [ -e "$project_dir" ]; then
        echo "Error: $project_dir already exists but wasn't picked up as a valid project (check its structure)."
        exit 1
    fi

    mkdir -p "$project_dir"
    git init "$project_dir" >/dev/null

    VALID_PROJECTS+=("$project")
    PROJECT_PATHS["$project"]="$project_dir"
    echo "Created new project at $project_dir"
}

resolve_project() {
    local project="$1" selection

    if [ -z "$project" ]; then
        # Format: "name | /path/to/project"
        # fzf will only search/show the first field (--with-nth=1)
        selection="$(for name in "${!PROJECT_PATHS[@]}"; do
            printf '%s\t%s\n' "$name" "${PROJECT_PATHS[$name]}"
        done | fzf \
            --style full \
            --delimiter='\t' \
            --with-nth=1 \
            --preview 'eza --tree --level=1 --git-ignore --color=always --group-directories-first --icons {2}' \
            --bind 'ctrl-/:change-preview-window(down|hidden|)')"

        [ -z "$selection" ] && exit 0

        # Extract the name (field 1) and path (field 2) from the selection
        TARGET_PROJECT="$(echo "$selection" | cut -f1)"
        PROJECT_DIR="$(echo "$selection" | cut -f2)"
    elif ! is_valid_project "$project"; then
        prompt_create_project "$project"
    fi
}

# ---------------------------------------------------------------------------
# tmux setup
# ---------------------------------------------------------------------------
window_exists() {
    tmux list-windows -t "$TARGET_PROJECT" -F '#{window_name}' 2>/dev/null | grep -qx "$1"
}

ensure_session() {
    if tmux has-session -t "$TARGET_PROJECT" 2>/dev/null; then
        return
    fi
    tmux new-session -d -s "$TARGET_PROJECT" -c "$PROJECT_DIR"
    tmux rename-window -t "$TARGET_PROJECT:1" terminal
}

ensure_requests_dir() {
    # needed before the http window starts, since it runs `posting -c requests`
    [ -d "$PROJECT_DIR/requests" ] && return

    mkdir -p "$PROJECT_DIR/requests"
    if ! grep -q "requests" "$PROJECT_DIR/.git/info/exclude" 2>/dev/null; then
        echo "requests" >> "$PROJECT_DIR/.git/info/exclude"
    fi
}

create_missing_windows() {
    local name
    for name in "${WINDOW_ORDER[@]}"; do
        window_exists "$name" && continue

        tmux new-window -t "$TARGET_PROJECT" -n "$name" -c "$PROJECT_DIR"
        if [ -n "${WINDOW_CMD[$name]:-}" ]; then
            tmux send-keys -t "$TARGET_PROJECT:$name" "${WINDOW_CMD[$name]}" Enter
        fi
    done
}

reorder_windows() {
    local name tmp_index=100 final_index=1

    # Pass 1: push everything to a temporary high index range so the
    # final-position moves in pass 2 never collide with each other.
    for name in "${WINDOW_ORDER[@]}"; do
        if window_exists "$name"; then
            tmux move-window -s "$TARGET_PROJECT:$name" -t "$TARGET_PROJECT:$tmp_index" 2>/dev/null
            tmp_index=$((tmp_index + 1))
        fi
    done

    # Pass 2: place windows into their final positions, in WINDOW_ORDER order.
    for name in "${WINDOW_ORDER[@]}"; do
        if window_exists "$name"; then
            tmux move-window -s "$TARGET_PROJECT:$name" -t "$TARGET_PROJECT:$final_index" 2>/dev/null
            final_index=$((final_index + 1))
        fi
    done
}

attach_or_switch() {
    tmux select-window -t "$TARGET_PROJECT:terminal"

    if [ -n "${TMUX:-}" ]; then
        tmux switch-client -t "$TARGET_PROJECT"
    else
        tmux attach -t "$TARGET_PROJECT"
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    parse_args "$@"
    discover_projects

    resolve_project "$TARGET_PROJECT"

    if [ -z "$PROJECT_DIR" ]; then
      PROJECT_DIR="${PROJECT_PATHS[$TARGET_PROJECT]}"
    fi

    ensure_session
    # ensure_requests_dir
    create_missing_windows
    reorder_windows
    attach_or_switch
}

main "$@"
