#!/bin/bash

work() {
    local project="$1"
    local project_dir="/home/pib/projects/$project"

    if [ -z "$project" ]; then
        echo "Usage: work <project>"
        return 1
    fi

    if [ ! -d "$project_dir" ]; then
        echo "Error: '$project_dir' does not exist"
        return 1
    fi

    cd "$project_dir" || return 1

    if tmux has-session -t "$project" 2>/dev/null; then
        tmux attach-session -t "$project"
        return 0
    fi

    tmux new-session -s "$project" \; \
        split-window -h \; \
        send-keys "startclaude" Enter \; \
        select-pane -t 0
}

startclaude() {
  local session_file=".claude/last_session_id"
  if [[ -f "$session_file" ]]; then
    local session_id
    session_id=$(cat "$session_file")
    if [[ -n "$session_id" ]]; then
      claude --resume "$session_id" "$@"
      return
    fi
  fi
  claude "$@"
}
