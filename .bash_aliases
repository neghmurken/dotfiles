#!/bin/bash

alias less=bat
alias ll="ls -hail --color"
alias bye="stahp && shutdown now"

alias dc="docker-compose"
alias dcr="docker-compose run"
alias dce="docker-compose exec"

alias ds="docker service"

alias go="dc up -dV --remove-orphans"
alias stahp="dc down --remove-orphans"

alias gds="git diff --staged"
alias gap="git add -p"
alias gpr="hub pull-request --push -o"
