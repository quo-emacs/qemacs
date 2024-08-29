#!/bin/bash

# Copyright (C) 2024 The Quo-Emacs Authors
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; version 2.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 51 Franklin
# Street, Fifth Floor, Boston, MA 02110-1301, USA.

SCRIPT_NAME="$(basename "$0")"
SCRIPT_PATH=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
export SCRIPT_NAME SCRIPT_PATH

export USR_PATH="{{USR_PATH}}"
export PREFIX="${USR_PATH}"
export CFLAGS="${CFLAGS} ${EMACS_CFLAGS} -I${USR_PATH}/include"
export LDFLAGS="${LDFLAGS} -L${USR_PATH}/lib"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${USR_PATH}/lib"
export PKG_CONFIG_PATH="${PKG_CONFIG_PATH}:${USR_PATH}/lib/pkgconfig"

#: default server name based on script name
export QEMACS_NAME=${SCRIPT_NAME}

#: check the script name to determine if there is a default profile
#: and server name present
QEMACS_NAMES=($(echo "${SCRIPT_NAME}" | perl -pe 's!\-\-! !g;s!\n! !g;s!\s+! !g;'))

if [ ${#QEMACS_NAMES[@]} -gt 1 ]
then
    #: correct the actual script name (is the first word)
    export QEMACS_NAME="${QEMACS_NAMES[0]}"
    #: prune the actual script name (not the first word)
    QEMACS_NAMES=(${QEMACS_NAMES[@]:1})
    #: check for optional settings
    if echo "${QEMACS_NAMES[@]}" | grep -q -E '[psw]\-[a-zA-Z0-9][_a-zA-Z]*'
    then
        for NAME in "${QEMACS_NAMES[@]}"
        do
            KEY=$(echo "${NAME}" | perl -pe 's!^([psw])\-.+?$!${1}!')
            VALUE=$(echo "${NAME}" | perl -pe 's!^[psw]\-(.+?)$!${1}!')
            case "${KEY}" in
                "p") export QEMACS_PROFILE="${VALUE}";;
                "s") export QEMACS_SERVER="${VALUE}";;
                "w") export QEMACS_WORKSPACE="${VALUE}";;
                *)
                    echo "unsupported option: ${NAME}" 1>&2
                    exit 1
                    ;;
            esac
        done
    else
        #: check for positional settings
        if [ ${#QEMACS_NAMES[@]} -eq 1 ]
        then
            #: one segment means qide--<workspace>
            export QEMACS_WORKSPACE="${QEMACS_NAMES[0]}"
        elif [ ${#QEMACS_NAMES[@]} -ge 2 ]
        then
            #: two segments means qide--<workspace>--<profile>
            export QEMACS_WORKSPACE="${QEMACS_NAMES[0]}"
            export QEMACS_PROFILE="${QEMACS_NAMES[1]}"
        elif [ ${#QEMACS_NAMES[@]} -ge 3 ]
        then
            #: two segments means qide--<workspace>--<profile>--<server>
            export QEMACS_WORKSPACE="${QEMACS_NAMES[0]}"
            export QEMACS_PROFILE="${QEMACS_NAMES[1]}"
            export QEMACS_SERVER="${QEMACS_NAMES[2]}"
        fi
    fi
fi

#: path to qemacs installation
QEMACS_PATH=$(dirname "$(dirname "${SCRIPT_PATH}")")
export QEMACS_PATH

#: debugging is not setup by default
export QEMACS_DEBUG=${QEMACS_DEBUG:=false}
export QEMACS_DEBUG_INIT=${QEMACS_DEBUG_INIT:false}

#: used with --init-directory when starting emacs
export QEMACS_PROFILE=${QEMACS_PROFILE:=qemacs}

#: configures the emacs server-name setting when running any of
#: the q<name> script variants
export QEMACS_SERVER=${QEMACS_SERVER:=${QEMACS_NAME}}

#: startup with named workspace
export QEMACS_WORKSPACE=${QEMACS_WORKSPACE:=default}

SCRIPT_VERBOSE=0

#: command line argument processing for this particular script
#: developers can pass -- and any arguments following that are
#: passed directly to the emacs or emacsclient binaries
while [ $# -gt 0 ]
do
    case "$1" in
        "-h"|"--help")
            NAME=$(basename "$0")
            echo "usage: ${NAME} [options]"
            echo
            echo "options:"
            echo
            echo "  -w | --workspace=<name>    startup with workspace <name>"
            echo "  -p | --profile=<name>      use ~/.<name>.d"
            echo "  -s | --server=<name>       specify server <name>"
            echo "  -d | --debug               set debug-on-error t"
            echo "  -D | --debug-init          use --debug-init (implies --debug)"
            echo "  -v | --verbose             display script settings"
            echo
            echo "  Use \"${NAME} -- --help\" for actual emacs command line help"
            echo
            echo "shortcuts:"
            echo
            echo "  ln -sv ${NAME} qide--<workspace>"
            echo "  ln -sv ${NAME} qide--<workspace>--<profile>"
            echo "  ln -sv ${NAME} qide--<workspace>--<profile>--<server>"
            echo
            echo "  where:"
            echo "    <workspace>  is an emacs workspace"
            echo "    <profile>    is an emacs ~/.<name>.d profile"
            echo "    <server>     is a custom server name to use"
            echo "    values       must satisfy: [a-zA-Z0-9][_a-zA-Z0-9]*"
            echo
            exit 0
            ;;

        "-w"|"--workspace")
            if [ -n "$2" ]
            then
                export QEMACS_WORKSPACE="$2"
                shift
            fi
            shift
            ;;

        "-s"|"--server")
            if [ -n "$2" ]
            then
                export QEMACS_SERVER="$2"
                shift
            fi
            shift
            ;;

        "-p"|"--profile")
            if [ -n "$2" ]
            then
                export QEMACS_PROFILE="$2"
                shift
            fi
            shift
            ;;

        "-d"|"--debug")
            export QEMACS_DEBUG=true
            shift
            ;;

        "-D"|"--debug-init")
            export QEMACS_DEBUG=true
            export QEMACS_DEBUG_INIT=true
            shift
            ;;

        "-v"|"--verbose")
            SCRIPT_VERBOSE=1
            shift
            ;;

        "-nw") shift;;
        "--")  shift; break;;
        *)     break;;
    esac
done

if [ "${SCRIPT_VERBOSE}" == "1" ]
then
    echo "# QEMACS_NAME:      ${QEMACS_NAME}"
    echo "# QEMACS_DEBUG:     ${QEMACS_DEBUG}"
    echo "# QEMACS_SERVER:    ${QEMACS_SERVER}"
    echo "# QEMACS_PROFILE:   ${QEMACS_PROFILE}"
    echo "# QEMACS_WORKSPACE: ${QEMACS_WORKSPACE}"
    echo "#"
    read -r -n 1 -p "# Press <CTRL+c> to stop, any other key to continue" JUNK
fi

QEMACS_OPTIONS=("--init-directory=~/.${QEMACS_PROFILE}.d")
if [ "${QEMACS_DEBUG_INIT}" == "true" ]
then
    QEMACS_OPTIONS+=("--debug-init")
fi
