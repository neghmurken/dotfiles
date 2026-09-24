#!/usr/bin/env bash
# Fetch PR review-body, conversation, and inline comments as unified JSON.
# Marks conversation/inline entries as `addressed: true` if the given user
# already left a +1 reaction on them, OR (inline only) if GitHub's native
# "Resolve conversation" was used on their review thread (review bodies
# can't carry reactions or belong to a thread, so they always report
# addressed: false).
#
# Usage: fetch-comments.sh <owner> <repo> <pr_number> <github_login>
set -euo pipefail

owner="$1" repo="$2" pr="$3" me="$4"

is_addressed() {
  local url="$1" count="$2"
  [ "$count" -eq 0 ] && { echo false; return; }
  if gh api "$url" -q ".[] | select(.user.login==\"$me\" and .content==\"+1\")" | grep -q .; then
    echo true
  else
    echo false
  fi
}

# databaseIds of inline comments whose review thread is natively resolved on GitHub.
resolved_ids=$(gh api graphql --paginate -F owner="$owner" -F repo="$repo" -F pr="$pr" -f query='
  query($owner: String!, $repo: String!, $pr: Int!, $endCursor: String) {
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $pr) {
        reviewThreads(first: 100, after: $endCursor) {
          pageInfo { hasNextPage endCursor }
          nodes {
            isResolved
            comments(first: 100) { nodes { databaseId } }
          }
        }
      }
    }
  }' -q '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved) | .comments.nodes[].databaseId' \
  | jq -s '.')

is_resolved() {
  jq --argjson id "$1" 'any(. == $id)' <<<"$resolved_ids"
}

reviews=$(gh api "repos/$owner/$repo/pulls/$pr/reviews" --paginate \
  | jq '[.[] | select(.body != "") | {type:"review_body", id, author:.user.login, body, url:.html_url, addressed:false}]')

issue_comments="[]"
while IFS= read -r c; do
  plus1=$(jq -r '.reactions["+1"]' <<<"$c")
  rurl=$(jq -r '.reactions.url' <<<"$c")
  addressed=$(is_addressed "$rurl" "$plus1")
  entry=$(jq -c --argjson addressed "$addressed" \
    '{type:"conversation", id, author:.user.login, body, url:.html_url, addressed:$addressed}' <<<"$c")
  issue_comments=$(jq -c ". + [$entry]" <<<"$issue_comments")
done < <(gh api "repos/$owner/$repo/issues/$pr/comments" --paginate | jq -c '.[]')

inline_comments="[]"
while IFS= read -r c; do
  plus1=$(jq -r '.reactions["+1"]' <<<"$c")
  rurl=$(jq -r '.reactions.url' <<<"$c")
  id=$(jq -r '.id' <<<"$c")
  addressed=false
  [ "$(is_addressed "$rurl" "$plus1")" = true ] && addressed=true
  [ "$(is_resolved "$id")" = true ] && addressed=true
  entry=$(jq -c --argjson addressed "$addressed" \
    '{type:"inline", id, author:.user.login, body, path, line:(.line // .original_line), diff_hunk, url:.html_url, addressed:$addressed}' <<<"$c")
  inline_comments=$(jq -c ". + [$entry]" <<<"$inline_comments")
done < <(gh api "repos/$owner/$repo/pulls/$pr/comments" --paginate | jq -c '.[]')

jq -n --argjson r "$reviews" --argjson i "$issue_comments" --argjson n "$inline_comments" \
  '{review_bodies:$r, conversation:$i, inline:$n}'
