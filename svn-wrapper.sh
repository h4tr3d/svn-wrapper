#!/usr/bin/env bash

set -e
#set -x

#
# Global check to terminal or file operation
#
if [ -t 1 ]; then
    export IS_TERMINAL=1
else
    export IS_TERMINAL=0
fi

#
# Setup real svn
#
ME=$(realpath -sm $0)
export SVN=$(which -a svn | grep -v "\\$ME" | head -n1)

#
# Setup SVN root directory
#
export SVN_ROOT=$(env LANG=C $SVN info | grep 'Root Path:' | awk -F: '{print $2}' | xargs)

#
# Hook dirs
#
export HOOK_DIR="$SVN_ROOT/.svn/hooks"

#
# Helpers
#
run_hook()
{
    local hook=$1
    shift
    test -x "$HOOK_DIR/$hook" && "$HOOK_DIR/$hook" "$@" || true
}

run_hooks()
{
    local hook_type=$1
    local action=$2
    shift 2

    case "$action" in
    up|update)
        run_hook $hook_type-update "$@"
    ;;
    ci|commit)
        run_hook $hook_type-commit "$@"
    ;;
    *)
        run_hook $hook_type-action $action "$@"
    ;;
    esac
}

modify_args()
{
    local action=$1
    shift

    local help_mode=0
    local arg
    for arg in "$@"
    do
        case "$arg" in
            --help)
                return 0
            ;;
        esac
    done

    case "$action" in
        st|stat|status)
            ACT_ARGS="--ignore-externals"
        ;;
        diff)
            local ext
            # Skip spaces changes only for terminal output
            [ $IS_TERMINAL -eq 1 ] && ext="bpu" || ext="pu"
            ACT_ARGS="-x -$ext --internal-diff"
        ;;
    esac
}

# Filter SVN output. Helps to implement "local ignores"
svn_output_filter()
{
    local action=$1
    shift

    case "$action" in
        st|stat|status)
            local IGNORES_IN="$SVN_ROOT/.svn/ignores.txt"
            local IGNORES=`mktemp /tmp/XXXXXXXX`

            if [ -f "$IGNORES_IN" ]; then
                cat "$IGNORES_IN" | grep -v '^$' | grep -v '^#' > "$IGNORES"

                REAL_PATH="n"
                if which realpath > /dev/null; then
                    REAL_PATH="y"
                fi

                while read line;
                do
                    # First 8 columns uses for svn status info: 7 info + 1 for space
                    # see `svn help st`
                    type=`echo $line | cut -c 1`
                    fn=`echo $line | cut -c 9-`
                    # Process only untracked files
                    if [ "$type" = "?" ]; then
                        if [ "$REAL_PATH" = "y" ]; then
                            #set -x
                            fn=`realpath -m --relative-to="$SVN_ROOT" -s -q "$fn"`
                            #set +x
                        fi
                        echo $fn | grep -f "$IGNORES" > /dev/null || echo "$line"
                    else
                        echo "$line"
                    fi
                done
            else
                cat
            fi

            rm -f "$IGNORES"
        ;;
        diff)
            if [ -t 1 ]; then
                (which colordiff > /dev/null 2>&1 && colordiff --color=auto || cat) | less -r
            else
                cat
            fi
        ;;
        log)
            [ -t 1 ] && less -r || cat
        ;;
        *)
            # Default bypass filter
            cat
        ;;
    esac
}

#
# SVN action
#
action=$1

#
# Pre-hooks
#
run_hooks pre "$action"

#
# Modifty command line
#
# disable halting on error
set +e

[ -n "$1" ] && shift
ACT_ARGS=""
modify_args "$action" "$@"

#
# Real SVN call
#

# detects svn-internal commands
internal=`LANG=C $SVN help "$action" 2>&1 | grep ': unknown command'`
external=`which "svn-$action" 2>/dev/null`
if [ -z "$internal" -o -z "$external" ]; then
    [ -z "$internal" ] && $SVN $action $ACT_ARGS "$@" | svn_output_filter "$action" || $SVN $action $ACT_ARGS "$@"
    svn_status=$?
else
    "svn-$action" "$@" $ACT_ARGS
    svn_status=$?
fi

# enable halting on error
set -e

#
# Post-hooks
#
run_hooks post "$action" $svn_status

exit $svn_status
