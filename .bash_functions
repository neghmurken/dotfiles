#!/bin/bash

cd() {
  builtin cd "$@"

  if [[ "$?" -gt 0 ]]; then
    return "$?"
  fi

  if [[ -f .aliases && -z "$(cat .aliases | grep -v '^alias ')" ]]; then
    base_aliases="$(alias)"
    . .aliases
  fi

  if [[ ! -f .aliases && ! -z "$base_aliases" ]]; then
    unalias -a
    eval "$base_aliases"
  fi

  return 0
}

base_aliases=''
