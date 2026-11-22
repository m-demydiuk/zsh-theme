# Custom ZSH theme of Volodymyr Stelmakh
# https://github.com/vstelmakh/zsh-theme
# MIT License

# ZSH Prompt-Expansion Reference
# https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html
# git:
# %s - vcs type
# %b - branch
# %a - action (rebase/merge)
# %m - misc content (set with git-check hook)
# prompt:
# %F - foreground color
# %f - reset color
# %B - bold
# %b - reset bold
# %~ - current path
# %(::) - prompt conditional - %(condition:true:false)

# Configuration (set before the theme is loaded to override)
: ${VSTELMAKH_THEME_PROMPT_SYMBOL:=➜}
: ${VSTELMAKH_THEME_DIRTY_SYMBOL:=•}
: ${VSTELMAKH_THEME_REF_MAX_LENGTH:=15}
: ${VSTELMAKH_THEME_COLOR_SUCCESS:=green}
: ${VSTELMAKH_THEME_COLOR_ERROR:=red}
: ${VSTELMAKH_THEME_COLOR_PATH:=cyan}
: ${VSTELMAKH_THEME_COLOR_GIT:=blue}
: ${VSTELMAKH_THEME_COLOR_REF:=red}
: ${VSTELMAKH_THEME_COLOR_DIRTY:=yellow}

# Hook to set Git reference to misc (%m) content
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' formats "%%F{${VSTELMAKH_THEME_COLOR_GIT}}[%m%%F{${VSTELMAKH_THEME_COLOR_GIT}}]%%f "
zstyle ':vcs_info:git*+set-message:*' hooks git-check
+vi-git-check() {
    local string_truncate() {
        local LENGTH=$1
        local ELLIPSIS=$2
        local STRING=$3

        if (( LENGTH < 0 )); then return 1; fi
        if (( ${#STRING} > LENGTH )); then
            if (( LENGTH <= ${#ELLIPSIS} )); then
                printf '%s' "${STRING[1,$LENGTH]}"
            else
                printf '%s' "${STRING[1,$((LENGTH-${#ELLIPSIS}))]}${ELLIPSIS}"
            fi
        else
            printf '%s' "$STRING"
        fi
    }

    # - branch name
    # - or tag name
    # - or short SHA of the commit
    local REF
    REF=$(git symbolic-ref --short HEAD 2> /dev/null) \
    || REF=$(git describe --tags --exact-match HEAD 2> /dev/null) \
    || REF=$(git rev-parse --short HEAD 2> /dev/null) \
    || return 0

    REF=$(string_truncate "${VSTELMAKH_THEME_REF_MAX_LENGTH}" "…" "${REF}")
    hook_com[misc]+="%F{${VSTELMAKH_THEME_COLOR_REF}}${REF}"

    local STATUS
    STATUS=$(git status --porcelain 2> /dev/null | tail -n 1)
    if [[ -n $STATUS ]]; then
        hook_com[misc]+=" %F{${VSTELMAKH_THEME_COLOR_DIRTY}}${VSTELMAKH_THEME_DIRTY_SYMBOL}" # repository has changes
    fi
}

setopt prompt_subst
precmd_functions+=( theme_precmd )
theme_precmd () {
    vcs_info
}

PROMPT="%B" # text style bold
PROMPT+="%(?:%F{${VSTELMAKH_THEME_COLOR_SUCCESS}}:%F{${VSTELMAKH_THEME_COLOR_ERROR}})${VSTELMAKH_THEME_PROMPT_SYMBOL} " # previous command status
PROMPT+="%F{${VSTELMAKH_THEME_COLOR_PATH}}%~ " # workdir
PROMPT+='${vcs_info_msg_0_}' # git reference (if git repo)
PROMPT+="%b%f%u" # reset all text styles
