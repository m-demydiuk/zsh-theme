#!/usr/bin/env zsh
# Behaviour tests for the theme: zsh -f tests/test.zsh

setopt extended_glob
source "${${(%):-%x}:A:h}/../zsh-theme.zsh"

FAILED=0
PASSED=0

plain() {
    print -r -- "${1//\%[Ff](\{[^\}]#\})#/}"
}

assert_git_segment() {
    local DESCRIPTION=$1
    local EXPECTED=$2
    local ACTUAL

    theme_precmd
    ACTUAL=$(plain "${vcs_info_msg_0_}")
    if [[ $ACTUAL == "$EXPECTED" ]]; then
        (( PASSED++ ))
        print -r -- "ok   - ${DESCRIPTION}"
    else
        (( FAILED++ ))
        print -r -- "FAIL - ${DESCRIPTION}: expected [${EXPECTED}], got [${ACTUAL}]"
    fi
}

REPO=$(mktemp -d)
trap 'rm -rf "${REPO}"' EXIT

cd "${REPO}"
assert_git_segment "outside a repository" ""

git init -q -b main .
git config user.email test@example.com
git config user.name Test
git config commit.gpgsign false
echo one > file
git add file
git commit -q -m one

assert_git_segment "clean branch" "[main] "

echo change >> file
assert_git_segment "modified tracked file" "[main •] "
git checkout -q file

echo new > untracked
assert_git_segment "untracked file" "[main •] "
rm untracked

git checkout -q -b short-branch-15
assert_git_segment "branch name of exactly 15 characters" "[short-branch-15] "

git checkout -q -b this-is-a-very-long-branch-name
assert_git_segment "long branch name is truncated" "[this-is-a-very…] "

git checkout -q main
git tag v1.0
git checkout -q --detach v1.0
assert_git_segment "detached at a lightweight tag" "[v1.0] "

git checkout -q main
echo two > file
git commit -q -am two
git tag -a v2.0 -m "version 2"
git checkout -q --detach v2.0
assert_git_segment "detached at an annotated tag" "[v2.0] "

git checkout -q --detach HEAD~1
git tag -d v1.0 > /dev/null
assert_git_segment "detached commit without a tag" "[$(git rev-parse --short HEAD)] "

print -r -- ""
print -r -- "${PASSED} passed, ${FAILED} failed"
(( FAILED == 0 ))
