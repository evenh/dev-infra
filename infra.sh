#!/bin/bash

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
    check_argument $1
    tools=( $(get_tools) )

    if [[ ! " ${tools[@]} " =~ " $1 " ]]; then
        echo "No such tool: $1"
        exit 99
    fi
}

function get_tools {
    local names=`ls $script_dir/infra | sed 's/\.[^.]*$//'`
    echo "$names"
}

function list_tools {
    echo "Available tools:"
    echo "$(get_tools)"
}

function tool_is_running {
    tool_name=$1
    check_exists $tool_name

    containers_running=`docker-compose -f $script_dir/infra/$tool_name.yml ps -q`

    if [[ "$containers_running" != "" ]]; then
        return 0
    else
        return 1
    fi
}

function pull_tools {
    tools=( $(get_tools) )

    for i in "${tools[@]}"
    do
        eval "docker-compose -f $script_dir/infra/$i.yml pull"
    done
}

function start_tool {
    tool_name=$2
    check_exists $tool_name

    if tool_is_running $tool_name; then
        echo "$tool_name is already running, won't try to start.."
        return 0
    fi

    eval "docker-compose -f $script_dir/infra/$tool_name.yml up -d"
}

function stop_tool {
    tool_name=$2
    check_exists $tool_name

    if ! tool_is_running $tool_name; then
        echo "$tool_name is not running, won't try to stop.."
        return 0
    fi

    eval "docker-compose -f $script_dir/infra/$tool_name.yml down"
}

function restart_tool {
    tool_name=$2
    check_exists $tool_name

    if ! tool_is_running $tool_name; then
        echo "$tool_name is not running, will be started instead"
        start_tool ignored $tool_name
        return 0
    fi

    eval "docker-compose -f $script_dir/infra/$tool_name.yml restart"
}

function status_tool {
    tool_name=$2
    check_exists $tool_name

    if ! tool_is_running $tool_name; then
        echo "$tool_name is NOT running"
    else
        echo "$tool_name is running"
    fi
}

function tail_tool_log {
    tool_name=$2
    check_exists $tool_name

    if ! tool_is_running $tool_name; then
        echo "$tool_name is not running, won't attempt to tail logs"
        return 0
    fi

    eval "docker-compose -f $script_dir/infra/$tool_name.yml logs --follow"
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
        start_tool $@
    ;;
    stop)
        stop_tool $@
    ;;
    restart)
        restart_tool $@
    ;;
    status)
        status_tool $@
    ;;
    tail)
        tail_tool_log $@
    ;;
    *)
        echo "Development infrastructure tools. Usage:"
        echo "  $0 <list|pull|start|stop|restart|status|tail>"
        exit 9
esac
