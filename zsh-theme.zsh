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

# Seasonal prompt symbol on special days (1 to enable)
: ${VSTELMAKH_THEME_SEASONAL:=0}
zmodload zsh/datetime

# Days between Easter Sunday and the date of the given epoch (Anonymous Gregorian algorithm)
_vstelmakh_theme_easter_offset() {
    local NOW=$1
    local YEAR TODAY EASTER
    strftime -s YEAR '%Y' $NOW

    local A=$(( YEAR % 19 )) B=$(( YEAR / 100 )) C=$(( YEAR % 100 ))
    local D=$(( B / 4 )) E=$(( B % 4 )) F=$(( (B + 8) / 25 ))
    local G=$(( (B - F + 1) / 3 ))
    local H=$(( (19 * A + B - D - G + 15) % 30 ))
    local I=$(( C / 4 )) K=$(( C % 4 ))
    local L=$(( (32 + 2 * E + 2 * I - H - K) % 7 ))
    local M=$(( (A + 11 * H + 22 * L) / 451 ))
    local MONTH=$(( (H + L - 7 * M + 114) / 31 ))
    local DAY=$(( (H + L - 7 * M + 114) % 31 + 1 ))

    strftime -r -s EASTER '%Y-%m-%d' "${YEAR}-${MONTH}-${DAY}"
    strftime -s TODAY '%Y-%m-%d' $NOW
    strftime -r -s TODAY '%Y-%m-%d' $TODAY

    local DIFF=$(( TODAY - EASTER ))
    if (( DIFF >= 0 )); then
        REPLY=$(( (DIFF + 43200) / 86400 ))
    else
        REPLY=$(( -((-DIFF + 43200) / 86400) ))
    fi
}

_vstelmakh_theme_seasonal_symbol() {
    local NOW=$1
    local MONTH_DAY
    strftime -s MONTH_DAY '%m%d' $NOW
    MONTH_DAY=$(( 10#$MONTH_DAY ))

    if (( MONTH_DAY == 1231 || MONTH_DAY == 101 )); then
        REPLY="🥂"
    elif (( MONTH_DAY == 214 )); then
        REPLY="❤️"
    elif (( MONTH_DAY >= 1025 && MONTH_DAY <= 1031 )); then
        REPLY="🎃"
    elif (( MONTH_DAY >= 1201 && MONTH_DAY <= 1226 )); then
        REPLY="🎄"
    else
        _vstelmakh_theme_easter_offset $NOW
        if (( REPLY >= -2 && REPLY <= 1 )); then
            REPLY="🐣"
        else
            REPLY="➜"
        fi
    fi
}

setopt prompt_subst
precmd_functions+=( theme_precmd )
theme_precmd () {
    _vstelmakh_theme_symbol="➜"
    if (( VSTELMAKH_THEME_SEASONAL )); then
        _vstelmakh_theme_seasonal_symbol $EPOCHSECONDS
        _vstelmakh_theme_symbol=$REPLY
    fi
    vcs_info
}

PROMPT="%B" # text style bold
PROMPT+='%(?:%F{green}${_vstelmakh_theme_symbol}:%F{red}➜) ' # previous command status
PROMPT+="%F{cyan}%~ " # workdir
PROMPT+='${vcs_info_msg_0_}' # git reference (if git repo)
PROMPT+="%b%f%u" # reset all text styles
