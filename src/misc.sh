#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Logs an error message to stderr.
#
# @param string Message to log.
# @return void
# ------------------------------------------------------------------------------
log::error() {
  echo "$@" 1>&2
}

# ------------------------------------------------------------------------------
# Logs a standard message to stdout with separators.
#
# @param string Message to log.
# @return void
# ------------------------------------------------------------------------------
log::message() {
  echo "--------------"
  echo "$@"
}

# ------------------------------------------------------------------------------
# Sets the ENV variable based on TEAMWORK_URI and TEAMWORK_API_TOKEN.
#
# @return void
# ------------------------------------------------------------------------------
env::set_environment() {
  if [ "$TEAMWORK_URI" == "localhost" ] && [ "$TEAMWORK_API_TOKEN" == "test_api_token" ]; then
    export ENV="test"
  else
    export ENV="prod"
  fi
}

# ------------------------------------------------------------------------------
# Checks if a value exists in a bash array.
#
# @param string Value to search for.
# @param array Array to search.
# @return int 0 if found, 1 if not found.
# ------------------------------------------------------------------------------
utils::in_array() {
  ARRAY=$2
  for e in ${ARRAY[*]}
  do
    if [[ "$e" == "$1" ]]
    then
      return 0
    fi
  done
  return 1
}
