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
    #: prune the actual script name (first word)
    export QEMACS_NAME="${QEMACS_NAMES[0]}"
    QEMACS_NAMES=(${QEMACS_NAMES[@]:1})
    if [ ${#QEMACS_NAMES[@]} -eq 1 ]
    then
        #: one segment means qemacs--<server>
        export QEMACS_SERVER="${QEMACS_NAMES[0]}"
    elif [ ${#QEMACS_NAMES[@]} -ge 2 ]
    then
        #: two segments means qemacs--<profile>--<server>
        export QEMACS_PROFILE="${QEMACS_NAMES[0]}"
        export QEMACS_SERVER="${QEMACS_NAMES[1]}"
    fi
fi

#: path to qemacs installation
QEMACS_PATH=$(dirname $(dirname "${SCRIPT_PATH}"))
export QEMACS_PATH

#: debugging is not setup by default
export QEMACS_DEBUG=${QEMACS_DEBUG:=false}
export QEMACS_DEBUG_INIT=${QEMACS_DEBUG_INIT:false}

#: used with --init-directory when starting emacs
export QEMACS_PROFILE=${QEMACS_PROFILE:=qemacs}

#: configures the emacs server-name setting when running any of
#: the q<name> script variants
export QEMACS_SERVER=${QEMACS_SERVER:=${QEMACS_NAME}}

SCRIPT_VERBOSE=0

#: command line argument processing for this particular script
#: developers can pass -- and any arguments following that are
#: passed directly to the emacs or emacsclient binaries
while [ $# -gt 0 ]
do
    case "$1" in
        "-h")
            echo "usage: $(basename $0) [options]"
            echo
            echo "options:"
            echo
            echo "  -p | --profile=<name>      use ~/.<name>.d"
            echo "  -s | --server=<name>       specify server <name>"
            echo "  -d | --debug               debug-on-error t"
            echo "  -D | --debug-init          debug-on-error t, with --debug-init"
            echo "  -v | --verbose             display script settings"
            echo
            echo "Arguments after a -- flag are passed unmodified to emacs."
            echo
            exit 0
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
    echo "# QEMACS_NAME:    ${QEMACS_NAME}"
    echo "# QEMACS_DEBUG:   ${QEMACS_DEBUG}"
    echo "# QEMACS_SERVER:  ${QEMACS_SERVER}"
    echo "# QEMACS_PROFILE: ${QEMACS_PROFILE}"
    echo "#"
    read -n 1 -p "# Press <CTRL+c> to stop, any other key to continue" JUNK
fi

QEMACS_OPTIONS=("--init-directory=~/.${QEMACS_PROFILE}.d")
if [ "${QEMACS_DEBUG_INIT}" == "true" ]
then
    QEMACS_OPTIONS+=("--debug-init")
fi
