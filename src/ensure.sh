#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Ensures the specified environment variable exists.
#
# @param string Name of the environment variable to check.
# @exitcode 1 if the variable is not set.
# ------------------------------------------------------------------------------
ensure::env_variable_exist() {
  if [ -z "$1" ]; then
    log::error "No variable name provided to ensure::env_variable_exist"
    return 1
  fi

  # Use eval for better compatibility across shells
  eval value=\$"$1"
  if [ -z "$value" ]; then
    log::error "The env variable \"$1\" is required."
    return 1  # Return error code instead of exiting
  fi
  return 0
}


# ------------------------------------------------------------------------------
# Validates that the total number of arguments matches the expected count.
#
# @param int Expected number of arguments.
# @exitcode 1 if the number of provided arguments is incorrect.
# ------------------------------------------------------------------------------
ensure::total_args() {
  local -r received_args=$(( $# - 1 ))
  local -r expected_args=$1

  if ((received_args != expected_args)); then
    log::error "Illegal number of parameters, $expected_args expected but $received_args found"
    exit 1
  fi
}
