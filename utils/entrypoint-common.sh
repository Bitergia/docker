# Common functions to use in docker-entrypoint.sh script inside containers.
#
# To use this functions, add the following line to the
# docker-entrypoint.sh script:
#
# source /entrypoint-common.sh
#
# And import the file into the docker image by adding this line to the
# Dockerfile:
#
# ADD https://raw.githubusercontent.com/Bitergia/docker/master/utils/entrypoint-common.sh /

function check_host_port () {

    local _timeout=10
    local _tries=0
    local _is_open=0

    if [ $# -lt 2 ] ; then
        echo "check_host_port: missing parameters."
        echo "Usage: check_host_port <host> <port> [max-tries]"
        exit 1
    fi

    local _host=$1
    local _port=$2
    local _max_tries=${3:-${DEFAULT_MAX_TRIES}}
    local NC=$( which nc )

    if [ ! -e "${NC}" ] ; then
        echo "Unable to find 'nc' command."
        exit 1
    fi

    echo "Testing if port '${_port}' is open at host '${_host}'."

    while [ ${_tries} -lt ${_max_tries} -a ${_is_open} -eq 0 ] ; do
        echo -n "Checking connection to '${_host}:${_port}' [try $(( ${_tries} + 1 ))/${_max_tries}] ... "
        if ${NC} -z -w ${_timeout} ${_host} ${_port} ; then
            echo "OK."
            _is_open=1
        else
            sleep 1
            _tries=$(( ${_tries} + 1 ))
            if [ ${_tries} -lt ${_max_tries} ] ; then
                echo "Retrying."
            else
                echo "Failed."
            fi
        fi
    done

    if [ ${_is_open} -eq 0 ] ; then
        echo "Failed to connect to port '${_port}' on host '${_host}' after ${_tries} tries."
        echo "Port is closed or host is unreachable."
        exit 1
    else
        echo "Port '${_port}' at host '${_host}' is open."
    fi
}

function check_url () {

    local _timeout=10
    local _tries=0
    local _ok=0

    if [ $# -lt 2 ] ; then
        echo "check_url: missing parameters."
        echo "Usage: check_url <url> <regex> [max-tries]"
        exit 1
    fi

    local _url=$1
    local _regex=$2
    local _max_tries=${3:-${DEFAULT_MAX_TRIES}}
    local CURL=$( which curl )

    if [ ! -e "${CURL}" ] ; then
        echo "Unable to find 'curl' command."
        exit 1
    fi

    while [ ${_tries} -lt ${_max_tries} -a ${_ok} -eq 0 ] ; do
        echo -n "Checking url '${_url}' [try $(( ${_tries} + 1 ))/${_max_tries}] ... "
        if ${CURL} -s ${_url} | grep -q "${_regex}" ; then
            echo "OK."
            _ok=1
        else
            sleep 1
            _tries=$(( ${_tries} + 1 ))
            if [ ${_tries} -lt ${_max_tries} ] ; then
                echo "Retrying."
            else
                echo "Failed."
            fi
        fi
    done

    if [ ${_ok} -eq 0 ] ; then
        echo "Url check failed after ${_tries} tries."
        exit 1
    else
        echo "Url check succeeded."
    fi
}

function check_var () {
    local var_name="$1"
    local default_value="$2"

    if [ -z "$( eval echo \$${var_name} )" ] ; then
        if [ -z "${default_value}" ] ; then
            echo "Missing required variable '${var_name}'"
            exit 1
        else
            echo "${var_name} is undefined. Using default value of '${default_value}'"
            export $( eval echo ${var_name} )=${default_value}
        fi
    fi
}

function check_file () {

    local _tries=0
    local _is_available=0

    local _file=$1
    local _max_tries=${2:-${DEFAULT_MAX_TRIES}}
    local ret=0

    echo "Testing if file '${_file}' is available."

    while [ ${_tries} -lt ${_max_tries} -a ${_is_available} -eq 0 ] ; do
        echo -n "Checking file '${_file}' [try $(( ${_tries} + 1 ))/${_max_tries}] ... "
        if [ -r ${_file} ] ; then
            echo "OK."
            _is_available=1
        else
            sleep 1
            _tries=$(( ${_tries} + 1 ))
            if [ ${_tries} -lt ${_max_tries} ] ; then
                echo "Retrying."
            else
                echo "Failed."
            fi
        fi
    done

    if [ ${_is_available} -eq 0 ] ; then
        echo "Failed to to retrieve '${_file}' after ${_tries} tries."
        echo "File is unavailable."
        ret=1
    else
        echo "File '${_file}' is available."
    fi
    return $ret
}

# set DEFAULT_MAX_TRIES
check_var DEFAULT_MAX_TRIES 60
