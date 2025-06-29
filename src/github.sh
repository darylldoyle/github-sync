#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Retrieves the name of the GitHub event from the environment.
#
# @return string GITHUB_EVENT_NAME.
# ------------------------------------------------------------------------------
github::get_event_name() {
  echo "$GITHUB_EVENT_NAME"
}

# ------------------------------------------------------------------------------
# Extracts the 'action' field from the GitHub event JSON payload.
#
# @return string Action triggered.
# ------------------------------------------------------------------------------
github::get_action() {
  jq --raw-output .action "$GITHUB_EVENT_PATH"
}


# ------------------------------------------------------------------------------
# Retrieves the pull request number from the event payload.
#
# @return string Pull request number.
# ------------------------------------------------------------------------------
github::get_pr_number() {
  jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH"
}

# ------------------------------------------------------------------------------
# Retrieves and formats the pull request body from the event JSON.
#
# @return string Formatted PR body.
# ------------------------------------------------------------------------------
github::get_pr_body() {
  jq --raw-output .pull_request.body "$GITHUB_EVENT_PATH" | sed -r 's/^#{1,3}\ /#### /g'
}

# ------------------------------------------------------------------------------
# Retrieves the head branch reference of the pull request.
#
# @return string Head branch name.
# ------------------------------------------------------------------------------
github::get_head_ref() {
  jq --raw-output .pull_request.head.ref "$GITHUB_EVENT_PATH"
}

# ------------------------------------------------------------------------------
# Retrieves the base branch reference of the pull request.
#
# @return string Base branch name.
# ------------------------------------------------------------------------------
github::get_base_ref() {
  jq --raw-output .pull_request.base.ref "$GITHUB_EVENT_PATH"
}

# ------------------------------------------------------------------------------
# Retrieves the full repository name (owner/repo) from the pull request.
#
# @return string Full repository name.
# ------------------------------------------------------------------------------
github::get_repository_full_name() {
  jq --raw-output .pull_request.head.repo.full_name "$GITHUB_EVENT_PATH"
}

# ------------------------------------------------------------------------------
# Retrieves the HTML URL of the pull request.
#
# @return string Pull request URL.
# ------------------------------------------------------------------------------
github::get_pr_url() {
  jq --raw-output .pull_request.html_url "$GITHUB_EVENT_PATH"
}

# ------------------------------------------------------------------------------
# Retrieves the title of the pull request.
#
# @return string Pull request title.
# ------------------------------------------------------------------------------
github::get_pr_title() {
  jq --raw-output .pull_request.title "$GITHUB_EVENT_PATH"
}

# ------------------------------------------------------------------------------
# Retrieves statistics for commits, changed files, additions, and deletions.
#
# @return string Stats in the format "commits files additions deletions".
# ------------------------------------------------------------------------------
github::get_pr_patch_stats() {
  jq --raw-output '.pull_request | "\(.commits) \(.changed_files) \(.additions) \(.deletions)"'  "$GITHUB_EVENT_PATH"
}

# ------------------------------------------------------------------------------
# Determines whether the pull request was merged.
#
# @return string "true" if merged, otherwise "false".
# ------------------------------------------------------------------------------
github::get_pr_merged() {
  jq --raw-output .pull_request.merged "$GITHUB_EVENT_PATH"
}

# ------------------------------------------------------------------------------
# Retrieves the username of the event sender.
#
# @return string Sender login.
# ------------------------------------------------------------------------------
github::get_sender_user() {
  jq --raw-output .sender.login "$GITHUB_EVENT_PATH"
}

# ------------------------------------------------------------------------------
# Retrieves the state of a pull request review.
#
# @return string Review state.
# ------------------------------------------------------------------------------
github::get_review_state() {
  jq --raw-output .review.state "$GITHUB_EVENT_PATH"
}

# ------------------------------------------------------------------------------
# Retrieves the body of a pull request review comment.
#
# @return string Review comment.
# ------------------------------------------------------------------------------
github::get_review_comment() {
  jq --raw-output .review.body "$GITHUB_EVENT_PATH"
}

# ------------------------------------------------------------------------------
# Outputs the raw JSON payload of the GitHub event.
#
# @return void
# ------------------------------------------------------------------------------
github::print_all_data() {
  cat "$GITHUB_EVENT_PATH"
}
