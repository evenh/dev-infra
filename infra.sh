#!/bin/bash

# Compose settings
export COMPOSE_IGNORE_ORPHANS=true

function is_windows {
    case "$OSTYPE" in
        win*)
            return 0
        ;;
        msys*)
            return 0
        ;;
        cygwin*)
            return 0
        ;;
        *)
            return 1
        ;;
    esac
}

# From https://www.ostricher.com/2014/10/the-right-way-to-get-the-directory-of-a-bash-script/
get_script_dir () {
    SOURCE="${BASH_SOURCE[0]}"
    # While $SOURCE is a symlink, resolve it
    while [ -h "$SOURCE" ]; do
        DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
        SOURCE="$( readlink "$SOURCE" )"
        # If $SOURCE was a relative symlink (so no "/" as prefix, need to resolve it relative to the symlink base directory
        [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
    done
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    echo "$DIR"
}

function construct_arguments {
    check_argument "$1"

    local argument="-p infra -f $script_dir/tools/$1.yml"

    if is_windows; then
        local win_path="$script_dir/tools/$1.win.yml"

        if [ -r "${win_path}" ]; then
            argument+=" -f $win_path"
        fi
    fi

    echo "${argument}"
}

# Check that required tooling is installed
function check_prerequisites {
    # Check for docker
    if ! [ -x "$(command -v docker)" ]; then
        echo 'Error: docker is not installed.' >&2
        exit 1
    fi

    # Check for docker-compose
    if ! [ -x "$(command -v docker-compose)" ]; then
        echo 'Error: docker-compose is not installed.' >&2
        exit 1
    fi
}

# Check if argument is invalid
function check_argument {
    if [ -z "$1" ]; then
        echo "Missing argument!"
        exit 99
    fi
}

# Check if a tool with a given name exists
function check_exists {
    check_argument "$1"
    # shellcheck disable=SC2207
    tools=( $(get_tools) )

    if [[ ! ${tools[*]} =~ $1 ]]; then
        echo "No such tool: $1"
        exit 99
    fi
}

function get_tools {
    local names
    # shellcheck disable=SC2012
    names=$(ls "$script_dir"/tools | sed 's/\.[^.]*$//' | grep -v "\\.")
    echo "$names"
}

function list_tools {
    # shellcheck disable=SC2207
    tools=( $(get_tools) )

    echo -e "Available tools:\\n"

    for i in "${tools[@]}"
    do
        echo "  - $i"
    done
}

function tool_is_running {
    tool_name=$1
    check_exists "$tool_name"

    local compose_containers
    local containers_running
    local filters

    # shellcheck disable=SC2207 disable=SC2046
    compose_containers=( $(docker-compose $(construct_arguments "$tool_name") ps -q) )

    # If no containers were returned, we are definitely not running
    if [ ${#compose_containers[@]} -eq 0 ]; then
        return 1
    fi

    for i in "${compose_containers[@]}"
    do
        filters+="-f id=$i "
    done

    # shellcheck disable=SC2086
    containers_running=$(docker ps -q ${filters})

    if [[ "$containers_running" != "" ]]; then
        return 0
    else
        return 1
    fi
}

function pull_tools {
    # shellcheck disable=SC2207
    tools=( $(get_tools) )

    for i in "${tools[@]}"
    do
        eval "docker-compose $(construct_arguments "$i") pull"
    done
}

function start_tool {
    tool_name=$2
    check_exists "$tool_name"

    if tool_is_running "$tool_name"; then
        echo "$tool_name is already running, won't try to start.."
        return 0
    fi

    eval "docker-compose $(construct_arguments "$tool_name") up -d"
}

function stop_tool {
    tool_name=$2
    check_exists "$tool_name"

    if ! tool_is_running "$tool_name"; then
        echo "$tool_name is not running, won't try to stop.."
        return 0
    fi

    eval "docker-compose $(construct_arguments "$tool_name") down"
}

function restart_tool {
    tool_name=$2
    check_exists "$tool_name"

    if ! tool_is_running "$tool_name"; then
        echo "$tool_name is not running, will be started instead"
        start_tool ignored "$tool_name"
        return 0
    fi

    eval "docker-compose $(construct_arguments "$tool_name") restart"
}

function status_tool {
    tool_name=$2
    check_exists "$tool_name"

    if ! tool_is_running "$tool_name"; then
        echo "$tool_name is NOT running"
    else
        echo "$tool_name is running"
    fi
}

function tool_ps {
    eval " docker ps --filter 'name=infra_'"
}

function tail_tool_log {
    tool_name=$2
    check_exists "$tool_name"

    if ! tool_is_running "$tool_name"; then
        echo "$tool_name is not running, won't attempt to tail logs"
        return 0
    fi

    eval "docker-compose $(construct_arguments "$tool_name") logs --follow"
}

# -- Init section
check_prerequisites
script_dir=$(get_script_dir)

case "$1" in
    list)
        list_tools
    ;;
    pull)
        pull_tools
    ;;
    start)
        start_tool "$@"
    ;;
    stop)
        stop_tool "$@"
    ;;
    restart)
        restart_tool "$@"
    ;;
    status)
        status_tool "$@"
    ;;
    ps)
        tool_ps
    ;;
    tail|logs)
        tail_tool_log "$@"
    ;;
    *)
        echo -e "Development infrastructure tools"
        echo -e "<https://github.com/evenh/dev-infra>\\n"
        echo -e "  Usage:  $0 <goal> <service>\\n"
        echo -e "  Ignores services:"
        echo -e "    list          List available tools"
        echo -e "    pull          Pull associated containers for all tools"
        echo -e "    ps            List running containers"
        echo -e ""
        echo -e "  Requires a service to be specified:"
        echo -e "    start         Start a service"
        echo -e "    stop          Stop a service"
        echo -e "    restart       Restart a service"
        echo -e "    status        Outputs whether a service is running or not"
        echo -e "    tail          Tail log output from a service"

        exit 0
esac
