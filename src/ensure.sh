#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Ensures the specified environment variable exists.
#
# @param string Name of the environment variable to check.
# @exitcode 1 if the variable is not set.
# ------------------------------------------------------------------------------
ensure::env_variable_exist() {
  if [[ -z "${!1}" ]]; then
    echoerr "The env variable $1 is required."
    exit 1
  fi
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
    echoerr "Illegal number of parameters, $expected_args expected but $received_args found"
    exit 1
  fi
}
