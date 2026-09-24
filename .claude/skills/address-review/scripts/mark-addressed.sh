#!/usr/bin/env bash
# Add a +1 reaction to a conversation or inline PR comment, marking it addressed.
# Review-body comments have no reaction endpoint and cannot be marked.
#
# Usage: mark-addressed.sh <owner> <repo> <conversation|inline> <comment_id>
set -euo pipefail

owner="$1" repo="$2" type="$3" id="$4"

case "$type" in
  conversation) endpoint="repos/$owner/$repo/issues/comments/$id/reactions" ;;
  inline)       endpoint="repos/$owner/$repo/pulls/comments/$id/reactions" ;;
  *) echo "type must be 'conversation' or 'inline'" >&2; exit 1 ;;
esac

gh api "$endpoint" -f content='+1' >/dev/null
echo "Marked $type comment $id as addressed."
