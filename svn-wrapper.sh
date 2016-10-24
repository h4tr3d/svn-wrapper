#!/usr/bin/env bash

set -e
#set -x

#
# Install:
# 1. edit the ~/.bashrc file and add a new alias:
#    alias svn="/path/to/this/file $@"
#
# Alt, for deb-based (at least Ubuntu, Mint):
# 1. edit ~/.bash_aliases instead of ~/.bashrc
#
# Supported hooks:
# * pre-update
# * post-update <svn_exit_status>
# * pre-commit
# * post-commit <svn_exit_status>
#
# Hooks directory:
# .svn/hooks
#
# - If pre-hooks returns non-zero status operations will terminates
# - Post-hooks runs in any case, but first argument is a real SVN return status
#
# Env variables:
#  SVN      - real svn command
#  SVN_ROOT - root directory of the repository
#  HOOK_DIR - hook dirs

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
    esac
}

modify_args()
{
    local action=$1
    shift

    case "$action" in
        st|stat|status)
            ACT_ARGS="--ignore-externals"
        ;;
        diff)
            ACT_ARGS="-x -bpu"
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
                #if false ; then
                #awk '
                #    NR==FNR { pats[$0]=1; next }
                #    {
                #        found = 0
                #        for(p in pats) {
                #            if($2 ~ p) {
                #                found=1
                #                break
                #            }
                #        }
                #        if (found == 0)
                #            print $0
                #    }
                #    ' "$IGNORES" -
                #fi

                while read line;
                do
                    fn=`echo $line | tr -s ' ' | cut -d ' ' -f 2-`
                    fn=`realpath -m --relative-to=$SVN_ROOT -s -q $fn`
                    echo $fn | grep -f "$IGNORES" > /dev/null || echo "$line"
                done

                rm -f "$IGNORES"
            else
                cat
            fi
        ;;
        log)
            less -R
        ;;
        diff)
            (which colordiff > /dev/null 2>&1 && colordiff --color=auto || cat)
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
set +e
shift
ACT_ARGS=""
modify_args "$action" "$@"

#
# Real SVN call
#
case "$action" in
    stash)
        svn-stash "$@" $ACT_ARGS
        svn_status=$?
    ;;
    *)
        $SVN $action $ACT_ARGS "$@" | svn_output_filter "$action"
        svn_status=$?
    ;;
esac
set -e

#
# Post-hooks
#
run_hooks post "$action" $svn_status

exit $svn_status
