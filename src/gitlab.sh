#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Constructs the merge request URL from CI variables.
#
# @return string Merge request URL.
# ------------------------------------------------------------------------------
gitlab::get_pr_url() {
  echo "$CI_MERGE_REQUEST_SOURCE_PROJECT_URL/-/merge_requests/$CI_MERGE_REQUEST_IID"
}

# ------------------------------------------------------------------------------
# Retrieves the merge request title.
#
# @return string MR title.
# ------------------------------------------------------------------------------
gitlab::get_pr_title() {
  echo "$CI_MERGE_REQUEST_TITLE"
}

# ------------------------------------------------------------------------------
# Retrieves the source branch name of the merge request.
#
# @return string Source branch.
# ------------------------------------------------------------------------------
gitlab::get_head_ref() {
  echo "$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME"
}

# ------------------------------------------------------------------------------
# Retrieves the target branch name of the merge request.
#
# @return string Target branch.
# ------------------------------------------------------------------------------
gitlab::get_base_ref() {
  echo "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME"
}

# ------------------------------------------------------------------------------
# Retrieves the username of the merge request author.
#
# @return string Author login.
# ------------------------------------------------------------------------------
gitlab::get_sender_user() {
  echo "$GITLAB_USER_LOGIN"
}

# ------------------------------------------------------------------------------
# Retrieves the merge request description.
#
# @return string MR description.
# ------------------------------------------------------------------------------
gitlab::get_pr_body() {
  echo "$CI_MERGE_REQUEST_DESCRIPTION"
}

# ------------------------------------------------------------------------------
# Checks if the merge request state is merged.
#
# @return string "true" if merged, else "false".
# ------------------------------------------------------------------------------
gitlab::get_pr_merged() {
  if [ "$CI_MERGE_REQUEST_EVENT_TYPE" == "merged_result" ] || [ "$CI_MERGE_REQUEST_EVENT_TYPE" == "merge_train" ]; then
    echo "true"
  else
    echo "false"
  fi
}

# ------------------------------------------------------------------------------
# Maps GitLab merge request state to GitHub-like actions.
#
# @return string Action type.
# ------------------------------------------------------------------------------
gitlab::get_action() {
  # Map GitLab MR states to GitHub-like actions based on event type
  case "$CI_MERGE_REQUEST_EVENT_TYPE" in
    "detached")
      echo "opened"
      ;;
    "merged_result"|"merge_train")
      echo "closed"
      ;;
    "pull_request_review")
      echo "submitted"
      ;;
    *)
      # Fallback to checking project variables
      if [ -n "$CI_MERGE_REQUEST_IID" ]; then
        echo "opened"  # Default state when we have an MR ID but unknown event type
      else
        echo "unknown"
      fi
      ;;
  esac
}

# ------------------------------------------------------------------------------
# Retrieves commit and diff statistics from the GitLab API.
#
# @return string Stats in the format "commits changes additions deletions".
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Placeholder for retrieving review state in GitLab.
#
# @return string Review state.
# ------------------------------------------------------------------------------
gitlab::get_review_state() {
  # Handle webhook approval events
  if [ "$CI_MERGE_REQUEST_EVENT_TYPE" == "pull_request_review" ] && [ "$CI_MERGE_REQUEST_APPROVED" == "true" ]; then
    echo "APPROVED"
    return
  fi

  # get the approval state of the merge request
  if [ "$ENV" == "test" ]; then
    echo "APPROVED"
    return
  fi

  # First check the CI variable for approval status
  if [ "$CI_MERGE_REQUEST_APPROVED" == "true" ]; then
    echo "APPROVED"
    return
  fi

  # If not available, fetch from API
  local mr_data
  mr_data=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    "$CI_API_V4_URL/projects/$CI_PROJECT_ID/merge_requests/$CI_MERGE_REQUEST_IID")

  # Check merge request status from API
  if [ "$(echo "$mr_data" | jq -r '.state // "unknown"')" == "merged" ]; then
    echo "APPROVED"
  elif [ "$(echo "$mr_data" | jq -r '.state // "unknown"')" == "closed" ]; then
    echo "DISMISSED"
  elif [ "$(echo "$mr_data" | jq -r '.approved // false')" == "true" ]; then
    echo "APPROVED"
  else
    echo "PENDING"
  fi
}


# ------------------------------------------------------------------------------
# Placeholder for retrieving review comment in GitLab.
#
# @return string Review comment.
# ------------------------------------------------------------------------------
gitlab::get_review_comment() {
  echo ""
}
