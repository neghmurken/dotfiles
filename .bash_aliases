#!/bin/bash

alias less=bat
alias ll="ls -hail --color"
alias bye="shutdown now"

alias dc="docker-compose"
alias dcr="docker-compose run"
alias dce="docker-compose exec"

alias ds="docker service"

alias up="dc up -dV --remove-orphans"
alias down="dc down --remove-orphans"

alias gds="git diff --staged"
alias gap="git add -p"
alias gpr="hub pull-request --push -o"
alias glf="git log -n1"

alias spotimin="wmctrl -r Spotify -b toggle,fullscreen"
