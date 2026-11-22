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

# Hook to set Git reference to misc (%m) content
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' formats "%%F{blue}[%m%%F{blue}]%%f "
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

    REF=$(string_truncate 15 "…" "${REF}")
    hook_com[misc]+="%F{red}${REF}"

    local STATUS
    STATUS=$(git status --porcelain 2> /dev/null | tail -n 1)
    if [[ -n $STATUS ]]; then
        hook_com[misc]+=" %F{yellow}•" # repository has changes
    fi
}

# Friday evening nudge (1 to enable) and the hour it starts
: ${VSTELMAKH_THEME_FRIDAY:=0}
: ${VSTELMAKH_THEME_FRIDAY_HOUR:=18}
zmodload zsh/datetime

_vstelmakh_theme_is_friday_evening() {
    local NOW=$1
    local WEEKDAY HOUR
    strftime -s WEEKDAY '%u' $NOW
    strftime -s HOUR '%H' $NOW
    (( WEEKDAY == 5 && 10#$HOUR >= VSTELMAKH_THEME_FRIDAY_HOUR ))
}

setopt prompt_subst
precmd_functions+=( theme_precmd )
theme_precmd () {
    _vstelmakh_theme_symbol="➜"
    _vstelmakh_theme_path_color="cyan"
    if (( VSTELMAKH_THEME_FRIDAY )) && _vstelmakh_theme_is_friday_evening $EPOCHSECONDS; then
        _vstelmakh_theme_symbol="🍺"
        _vstelmakh_theme_path_color="208"
    fi
    vcs_info
}

PROMPT="%B" # text style bold
PROMPT+='%(?:%F{green}${_vstelmakh_theme_symbol}:%F{red}➜) ' # previous command status
PROMPT+='%F{${_vstelmakh_theme_path_color}}%~ ' # workdir
PROMPT+='${vcs_info_msg_0_}' # git reference (if git repo)
PROMPT+="%b%f%u" # reset all text styles
