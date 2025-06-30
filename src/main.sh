#!/usr/bin/env bash

set -e

# Source all modules
# shellcheck disable=SC1091
source "$(dirname "$0")/src/ensure.sh"
# shellcheck disable=SC1091
source "$(dirname "$0")/src/misc.sh"
# shellcheck disable=SC1091
source "$(dirname "$0")/src/teamwork.sh"

# Modified platform detection
if [ -n "$GITHUB_EVENT_NAME" ]; then
  # GitHub Actions
  # shellcheck disable=SC1091
  source "$(dirname "$0")/src/github.sh"
  PLATFORM="github"
  EVENT_NAME="$GITHUB_EVENT_NAME"
  ACTION=$(github::get_action)

  export GITHUB_TOKEN="$1"
  export TEAMWORK_URI="$2"
  export TEAMWORK_API_TOKEN="$3"
  export AUTOMATIC_TAGGING="$4"
  export MAKE_COMMENTS_PRIVATE="$5"
  export BOARD_COLUMN_OPENED="$6"
  export BOARD_COLUMN_MERGED="$7"
  export BOARD_COLUMN_CLOSED="$8"
elif [ -n "$CI_MERGE_REQUEST_IID" ]; then
  # GitLab CI/CD
  # shellcheck disable=SC1091
  source "$(dirname "$0")/src/gitlab.sh"
  PLATFORM="gitlab"
  EVENT_NAME="pull_request"
  ACTION=$(gitlab::get_action)
else
  log::message "Unknown CI platform"
  exit 1
fi

env::set_environment

# Ensure all required environment variables are set
ensure::env_variable_exist "TEAMWORK_URI"
ensure::env_variable_exist "TEAMWORK_API_TOKEN"

# Extract task IDs from PR/MR body (using same function name)
if [ "$PLATFORM" == "gitlab" ]; then
  export TEAMWORK_TASK_IDS
  TEAMWORK_TASK_IDS=$(teamwork::get_task_id_from_body "$(gitlab::get_pr_body)")
else
  export TEAMWORK_TASK_IDS
  TEAMWORK_TASK_IDS=$(teamwork::get_task_id_from_body "$(github::get_pr_body)")
fi

if [ -z "$TEAMWORK_TASK_IDS" ]; then
  log::message "No task IDs found in description/body"
  exit 0
fi

# Process each task using existing teamwork functions
IFS=',' read -ra TASK_ID_ARRAY <<< "$TEAMWORK_TASK_IDS"
for task_id in "${TASK_ID_ARRAY[@]}"; do
  export TEAMWORK_TASK_ID="$task_id"
  export TEAMWORK_PROJECT_ID
  TEAMWORK_PROJECT_ID=$(teamwork::get_project_id_from_task "$task_id")

  # Use existing event handling logic - works for both platforms!
  case "$EVENT_NAME" in
    "pull_request")
      case "$ACTION" in
        "opened") teamwork::pull_request_opened ;;
        "closed") teamwork::pull_request_closed ;;
      esac
      ;;
    "pull_request_review")
      case "$ACTION" in
        "submitted") teamwork::pull_request_review_submitted ;;
        "dismissed") teamwork::pull_request_review_dismissed ;;
      esac
      ;;
  esac
done

exit $?
