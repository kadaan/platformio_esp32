#!/usr/bin/env bash

function notice() { echo -e "$*"; }
function error() {
  local message="$*"
  if [[ "$message" != ERROR:* ]]; then
    message="ERROR: $message"
  fi
  echo -e "$message" 1>&2;
}
function invalid_argument() {
  error "$1 [$2]"
  echo ""
  usage
  exit $E_WARG
}

function usage() {
  echo "Runs PlatformIO checks, tests, and builds."
  echo "Usage: platformio.sh [--check=ENV] [--test=ENV] [--build=ENV] [--verbose]"
  echo ""
  printf "    %-24s enables checks for all or specified environment\n" "--check, --check=ENVIRONMENT"
  printf "    %-24s enables tests for all or specified environment\n" "--test, --test=ENVIRONMENT"
  printf "    %-24s enables builds for all or specified environment\n" "--check, --check=ENVIRONMENT"
  printf "    %-24s enables verbose logging\n" "-v, --verbose"
  printf "    %-24s display this help message\n" "-h, --help"
}

function run() {
  local verbose_flag=""
  local check_all=false
  local test_all=false
  local build_all=false
  local check=()
  local test=()
  local build=()
  for var in "${@}"; do
    case "$var" in
      -h | --help)
        usage
        return 0
      ;;
      -v | --verbose)
        verbose_flag=" --verbose"
      ;;
      --check)
        check_all=true
        check=()
      ;;
      --check=*)
        if [[ "$check_all" != "true" ]]; then
          local environment="${var##*=}"
          if [[ "$environment" == "" ]]; then
              invalid_argument "check parameter missing environment" $var
          fi
          check+=("$environment")
        fi
      ;;
      --test)
        test_all=true
        test=()
      ;;
      --test=*)
        if [[ "$test_all" != "true" ]]; then
          local environment="${var##*=}"
          if [[ "$environment" == "" ]]; then
              invalid_argument "test parameter missing environment" $var
          fi
          test+=("$environment")
        fi
      ;;
      --build)
        build_all=true
        build=()
      ;;
      --build=*)
        if [[ "$build_all" != "true" ]]; then
          local environment="${var##*=}"
          if [[ "$environment" == "" ]]; then
              invalid_argument "build parameter missing environment" $var
          fi
          build+=("$environment")
        fi
      ;;
      *)
        invalid_argument "unsupported input parameter $var"
      ;;
    esac
  done

  local result=0
  if [[ "$check_all" == "false" && "${#check}" -eq 0 ]]; then
    notice "--> Checks disabled"
  else
    local environment_flags=""
    for environment in "${check[@]}"; do
      environment_flags="${environment_flags} --environment=${environment}"
    done
    notice "--> Running checks"
    local platformio_result
    platformio check${environment_flags}${verbose_flag}
    platformio_result="$?"
    result=$((result+$platformio_result))
  fi

  if [[ "$test_all" == "false" && "${#test}" -eq 0 ]]; then
    notice "--> Tests disabled"
  else
    local environment_flags=""
    for environment in "${test[@]}"; do
      environment_flags="${environment_flags} --environment=${environment}"
    done
    notice "--> Running tests"
    local platformio_result
    platformio test${environment_flags}${verbose_flag}
    platformio_result="$?"
    result=$((result+$platformio_result))
  fi

  if [[ "$build_all" == "false" && "${#build}" -eq 0 ]]; then
    notice "--> Builds disabled"
  else
    local environment_flags=""
    for environment in "${build[@]}"; do
      environment_flags="${environment_flags} --environment=${environment}"
    done
    notice "--> Running builds"
    local platformio_result
    platformio run${environment_flags}${verbose_flag}
    platformio_result="$?"
    result=$((result+$platformio_result))
  fi

  if [[ "$result" -gt 0 ]]; then
    return 1
  fi
  return 0
}

run "$@"
