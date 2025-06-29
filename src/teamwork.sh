#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Extracts task IDs from a text body using regex.
#
# @param string Body text to parse.
# @return string Comma-separated task IDs.
# ------------------------------------------------------------------------------
teamwork::get_task_id_from_body() {
  local body=$1
  local task_ids=()

  pat='tasks\/([0-9]{1,})'
  while [[ $body =~ $pat ]]; do
    task_ids+=( "${BASH_REMATCH[1]}" )
    body=${body#*"${BASH_REMATCH[0]}"}
  done

  local task_ids_str
  task_ids_str=$(printf ",%s" "${task_ids[@]}")
  task_ids_str=${task_ids_str:1} # remove initial comma
  echo "$task_ids_str"
}

# ------------------------------------------------------------------------------
# Retrieves the project ID associated with a given task via the Teamwork API.
#
# @param string Task ID to lookup.
# @return string Project ID.
# ------------------------------------------------------------------------------
teamwork::get_project_id_from_task() {
  local -r task_id=$1

  if [ "$ENV" == "test" ]; then
    echo "$task_id"
    return
  fi

  response=$(
    curl "$TEAMWORK_URI/projects/api/v1/tasks/$task_id.json" -u "$TEAMWORK_API_TOKEN"':' |\
      jq -r '.["todo-item"]["project-id"]'
  )
  echo "$response"
}

# ------------------------------------------------------------------------------
# Finds a board column ID by name.
#
# @param string Column name to match.
# @return string Column ID.
# ------------------------------------------------------------------------------
teamwork::get_matching_board_column_id() {
  local -r column_name=$1

  if [ -z "$column_name" ]; then
    return
  fi

  if [ "$ENV" == "test" ]; then
    echo "$TEAMWORK_PROJECT_ID"
    return
  fi

  response=$(
    curl "$TEAMWORK_URI/projects/$TEAMWORK_PROJECT_ID/boards/columns.json" -u "$TEAMWORK_API_TOKEN"':' |\
      jq -r --arg column_name "$column_name" '[.columns[] | select(.name | contains($column_name))] | map(.id)[0]'
  )

  if [ "$response" = "null" ]; then
    return
  fi

  echo "$response"
}

# ------------------------------------------------------------------------------
# Moves a task to a specified board column.
#
# @param string Column name to move the task into.
# @return void
# ------------------------------------------------------------------------------
teamwork::move_task_to_column() {
  local -r task_id=$TEAMWORK_TASK_ID
  local -r column_name=$1

  if [ -z "$column_name" ]; then
    log::message "No column name provided"
    return
  fi

  local -r column_id=$(teamwork::get_matching_board_column_id "$column_name")
  if [ -z "$column_id" ]; then
    log::message "Failed to find a matching board column for '$column_name'"
    return
  fi

  if [ "$ENV" == "test" ]; then
    log::message "Test - Simulate request. Task ID: $TEAMWORK_TASK_ID - Project ID: $TEAMWORK_PROJECT_ID - Column ID: $column_id"
    return
  fi

  response=$(curl -X "PUT" "$TEAMWORK_URI/tasks/$TEAMWORK_TASK_ID.json" \
      -u "$TEAMWORK_API_TOKEN"':' \
      -H 'Content-Type: application/json; charset=utf-8' \
      -d "{ \"todo-item\": { \"columnId\": $column_id } }" )

  log::message "$response"
}

# ------------------------------------------------------------------------------
# Adds a comment to a task via the Teamwork API.
#
# @param string Comment body.
# @return void
# ------------------------------------------------------------------------------
teamwork::add_comment() {
  local -r body=$1

  if [ "$ENV" == "test" ]; then
    log::message "Test - Simulate request. Task ID: $TEAMWORK_TASK_ID - Comment: ${body//\"/}"
    return
  fi

  # Use jq to properly construct the JSON payload
  local json_payload
  json_payload=$(jq -n \
    --arg body "$body" \
    --argjson isprivate "$([ "$MAKE_COMMENTS_PRIVATE" == true ] && echo true || echo false)" \
    '{
      comment: {
        body: $body,
        notify: true,
        "content-type": "text",
        isprivate: $isprivate
      }
    }')

  response=$(curl -X "POST" "$TEAMWORK_URI/tasks/$TEAMWORK_TASK_ID/comments.json" \
       -u "$TEAMWORK_API_TOKEN"':' \
       -H 'Content-Type: application/json; charset=utf-8' \
       -d "$json_payload")

  log::message "$response"
}

# ------------------------------------------------------------------------------
# Adds a tag to a task if automatic tagging is enabled.
#
# @param string Tag name to add.
# @return void
# ------------------------------------------------------------------------------
teamwork::add_tag() {
  local -r tag_name=$1

  if [ "$ENV" == "test" ]; then
    log::message "Test - Simulate request. Task ID: $TEAMWORK_TASK_ID - Tag Added: ${tag_name//\"/}"
    return
  fi

  if [ "$AUTOMATIC_TAGGING" == true ]; then
    response=$(curl -X "PUT" "$TEAMWORK_URI/tasks/$TEAMWORK_TASK_ID/tags.json" \
       -u "$TEAMWORK_API_TOKEN"':' \
       -H 'Content-Type: application/json; charset=utf-8' \
       -d "{ \"tags\": { \"content\": \"${tag_name//\"/}\" } }" )

    log::message "$response"
  fi
}

# ------------------------------------------------------------------------------
# Removes a tag from a task if automatic tagging is enabled.
#
# @param string Tag name to remove.
# @return void
# ------------------------------------------------------------------------------
teamwork::remove_tag() {
  local -r tag_name=$1

  if [ "$ENV" == "test" ]; then
    log::message "Test - Simulate request. Task ID: $TEAMWORK_TASK_ID - Tag Removed: ${tag_name//\"/}"
    return
  fi

  if [ "$AUTOMATIC_TAGGING" == true ]; then
    response=$(curl -X "PUT" "$TEAMWORK_URI/tasks/$TEAMWORK_TASK_ID/tags.json" \
         -u "$TEAMWORK_API_TOKEN"':' \
         -H 'Content-Type: application/json; charset=utf-8' \
         -d "{ \"tags\": { \"content\": \"${tag_name//\"/}\" },\"removeProvidedTags\":\"true\" }" )

    log::message "$response"
  fi
}

# ------------------------------------------------------------------------------
# Handles actions when a pull request is opened: comments, tagging, and column movement.
#
# @return void
# ------------------------------------------------------------------------------
teamwork::pull_request_opened() {
  # Use platform-agnostic function calls
  local -r pr_url=$("${PLATFORM}"::get_pr_url)
  local -r pr_title=$("${PLATFORM}"::get_pr_title)
  local -r head_ref=$("${PLATFORM}"::get_head_ref)
  local -r base_ref=$("${PLATFORM}"::get_base_ref)
  local -r user=$("${PLATFORM}"::get_sender_user)
  local -r pr_stats=$("${PLATFORM}"::get_pr_patch_stats)
  IFS=" " read -r -a pr_stats_array <<< "$pr_stats"

  teamwork::add_comment "
**$user** opened a new PR: **[$pr_title]($pr_url)**
\`$base_ref\` ⬅️ \`$head_ref\`

---

🔢 ${pr_stats_array[0]} commits / 📝 ${pr_stats_array[1]} files updated / ➕ ${pr_stats_array[2]} additions / ➖ ${pr_stats_array[3]} deletions"

  teamwork::add_tag "PR Open"
  teamwork::move_task_to_column "$BOARD_COLUMN_OPENED"
}

# ------------------------------------------------------------------------------
# Handles cleanup and tagging when a pull request is closed or merged.
#
# @return void
# ------------------------------------------------------------------------------
teamwork::pull_request_closed() {
  local -r user=$("${PLATFORM}"::get_sender_user)
  local -r pr_url=$("${PLATFORM}"::get_pr_url)
  local -r pr_title=$("${PLATFORM}"::get_pr_title)
  local -r pr_merged=$("${PLATFORM}"::get_pr_merged)

  if [ "$pr_merged" == "true" ]; then
    teamwork::add_comment "**$user** merged a the PR \"[$pr_title]($pr_url)\""
    teamwork::add_tag "PR Merged"
    teamwork::remove_tag "PR Open"
    teamwork::remove_tag "PR Approved"
    teamwork::remove_tag "PR Changes Requested"
    teamwork::move_task_to_column "$BOARD_COLUMN_MERGED"
  else
    teamwork::add_comment "**$user** closed the PR \"[$pr_title]($pr_url)\"without merging."
    teamwork::remove_tag "PR Open"
    teamwork::remove_tag "PR Approved"
    teamwork::remove_tag "PR Changes Requested"
    teamwork::move_task_to_column "$BOARD_COLUMN_CLOSED"
  fi
}

# ------------------------------------------------------------------------------
# Processes pull request review submissions, adding comments and tags for approvals or change requests.
#
# @return void
# ------------------------------------------------------------------------------
teamwork::pull_request_review_submitted() {
  local -r user=$("${PLATFORM}"::get_sender_user)
  local -r pr_url=$("${PLATFORM}"::get_pr_url)
  local -r pr_title=$("${PLATFORM}"::get_pr_title)
  local -r review_state=$("${PLATFORM}"::get_review_state)

  # Only add a message if the PR has been approved
  if [ "$review_state" == "approved" ]; then
    teamwork::add_comment "PR \"[$pr_title]($pr_url)\" approved by **$user**"

    teamwork::add_tag "PR Approved"
    teamwork::remove_tag "PR Changes Requested"
  fi

  ## Add a message if the PR has change requested, include body message
  if [ "$review_state" == "changes_requested" ]; then
      teamwork::add_comment "**$user** requested a change to the PR: [$pr_title]($pr_url)"

      teamwork::add_tag "PR Changes Requested"
      teamwork::remove_tag "PR Approved"
      teamwork::move_task_to_column "$BOARD_COLUMN_REVIEWED"
    fi
}

# ------------------------------------------------------------------------------
# Adds a comment when a pull request review is dismissed.
#
# @return void
# ------------------------------------------------------------------------------
teamwork::pull_request_review_dismissed() {
  local -r user=$("${PLATFORM}"::get_sender_user)
  teamwork::add_comment "Review dismissed by $user"
}
