
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
# PAGER like git
#
SVN_PAGER="less -FRSX"

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
#set -x
svn_output_colorer()
{
    local CMD=$1
    if [ -t 1 ]; then
        (
            case $CMD in
                diff|di)
                    (which colordiff > /dev/null 2>&1 && colordiff --color=auto || cat)
                ;;
                log)
                    sed -e 's/^\(.*\)|\(.*\)| \(.*\) \(.*\):[0-9]\{2\} \(.*\) (\(...\).*) |\(.*\)$/\o33\[1;32m\1\o33[0m|\o33\[1;34m\2\o33[0m| \o33\[1;35m\3 \4 (\6, \5)\o33[0m |\7/'
                ;;
                *)
                    (which svn-color-filter.py > /dev/null 2>&1 && svn-color-filter.py $CMD || cat)
                ;;
            esac
        ) | $SVN_PAGER
    else
        cat
    fi
}

svn_output_filter()
{
    local action=$1
    shift

    case "$action" in
        st|stat|status)
            local IGNORES_IN="$SVN_ROOT/.svn/ignores.txt"
            local IGNORES=`mktemp /tmp/XXXXXXXX`

            (
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
            ) | svn_output_colorer status

            rm -f "$IGNORES"
        ;;
        diff|log|remove|add|help)
            svn_output_colorer $action
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
non_internal=`LANG=C $SVN help "$action" 2>&1 | grep ': unknown command'`
non_external=`which "svn-$action" 2>/dev/null`
if [ -z "$non_internal" -o -z "$non_external" ]; then
    if [ -z "$non_internal" ]; then
        case "$action" in
            merge|co|checkout|cp|copy|ci|commit|switch|info|propedit|cleanup)
                $SVN $action $ACT_ARGS "$@"
                svn_status=$?
            ;;
            *)
                $SVN $action $ACT_ARGS "$@" | svn_output_filter "$action"
                svn_status=$?
            ;;
        esac
    else
        $SVN $action $ACT_ARGS "$@"
        svn_status=$?
    fi
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
