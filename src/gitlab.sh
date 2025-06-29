#!/usr/bin/env bash

# Map GitLab terminology to GitHub-compatible function names
gitlab::get_pr_url() {
  echo "$CI_MERGE_REQUEST_SOURCE_PROJECT_URL/-/merge_requests/$CI_MERGE_REQUEST_IID"
}

gitlab::get_pr_title() {
  echo "$CI_MERGE_REQUEST_TITLE"
}

gitlab::get_head_ref() {
  echo "$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME"
}

gitlab::get_base_ref() {
  echo "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME"
}

gitlab::get_sender_user() {
  echo "$GITLAB_USER_LOGIN"
}

gitlab::get_pr_body() {
  echo "$CI_MERGE_REQUEST_DESCRIPTION"
}

gitlab::get_pr_merged() {
  if [ "$CI_MERGE_REQUEST_STATE" == "merged" ]; then
    echo "true"
  else
    echo "false"
  fi
}

gitlab::get_action() {
  # Map GitLab MR states to GitHub-like actions
  case "$CI_MERGE_REQUEST_STATE" in
    "opened") echo "opened" ;;
    "merged"|"closed") echo "closed" ;;
    *) echo "unknown" ;;
  esac
}

gitlab::get_pr_patch_stats() {
  if [ "$ENV" == "test" ]; then
    echo "1 2 10 5" # commits files additions deletions
    return
  fi

  local mr_data
  mr_data=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    "$CI_API_V4_URL/projects/$CI_PROJECT_ID/merge_requests/$CI_MERGE_REQUEST_IID")

  local commits
  local changes
  local additions
  local deletions

  commits=$(echo "$mr_data" | jq -r '.commits_count // 0')
  changes=$(echo "$mr_data" | jq -r '.changes_count // 0')
  additions=$(echo "$mr_data" | jq -r '.additions // 0')
  deletions=$(echo "$mr_data" | jq -r '.deletions // 0')

  echo "$commits $changes $additions $deletions"
}

# For review functionality (if you want to support GitLab approval rules)
gitlab::get_review_state() {
  # This would need to be implemented based on your GitLab approval setup
  echo "approved"
}

gitlab::get_review_comment() {
  echo ""
}
