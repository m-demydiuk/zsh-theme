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

# Prompt pet that reacts to the previous command (1 to enable)
: ${VSTELMAKH_THEME_PET:=0}
zmodload zsh/datetime
autoload -Uz add-zsh-hook

_vstelmakh_theme_pet_preexec() {
    _vstelmakh_theme_pet_command=$1
    _vstelmakh_theme_pet_start=$EPOCHSECONDS
}
add-zsh-hook preexec _vstelmakh_theme_pet_preexec

_vstelmakh_theme_pet_mood() {
    local LAST_STATUS=$1
    if [[ -z $_vstelmakh_theme_pet_command ]]; then
        REPLY="(o_o)" # nothing ran
    elif (( LAST_STATUS != 0 )); then
        REPLY="(>_<)" # command failed
    elif [[ $_vstelmakh_theme_pet_command == git\ push* ]]; then
        REPLY='\(^o^)/' # pushed
    elif (( EPOCHSECONDS - _vstelmakh_theme_pet_start >= 60 )); then
        REPLY="(-_-)zzz" # long wait
    else
        REPLY="(^_^)" # command succeeded
    fi
}

setopt prompt_subst
precmd_functions+=( theme_precmd )
theme_precmd () {
    local LAST_STATUS=$?
    _vstelmakh_theme_pet=""
    if (( VSTELMAKH_THEME_PET )); then
        _vstelmakh_theme_pet_mood $LAST_STATUS
        _vstelmakh_theme_pet="%F{white}${REPLY} "
    fi
    unset _vstelmakh_theme_pet_command _vstelmakh_theme_pet_start
    vcs_info
}

PROMPT="%B" # text style bold
PROMPT+='${_vstelmakh_theme_pet}' # prompt pet (if enabled)
PROMPT+="%(?:%F{green}:%F{red})➜ " # previous command status
PROMPT+="%F{cyan}%~ " # workdir
PROMPT+='${vcs_info_msg_0_}' # git reference (if git repo)
PROMPT+="%b%f%u" # reset all text styles
