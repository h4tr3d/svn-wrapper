# svn-wrapper
Wrapper for command-line Subversion (svn) client with additional features

Some of initials ideas:

1. Suppor for client-side pre- and post-operation hooks (pre-update, post-update and so on)
2. Wrap some commands and add new abilities: 
   * Automatically use `colordiff` for `svn diff` if found
   * Client-side ignores for `svn status` command
3. Add "new" commands, like `svn stash` for client-side stashing changes and switches between them.

## Installation

1. Edit `~/.bashrc` and add new alias:

```
alias svn="/path/to/svn-wrapper.sh $@"
```

2. Re-loging to system.

For deb-based distros (Debian, Ubuntu, Mint) you can edit `~/.bashrc_aliases` instead of
`~/.bashrc`.

To activate `svn stash` command you should put `svn-stash` script to the one of directory under
PATH, for example: link it to `/usr/local/bin`:

```
sudo ln -s /path/to/svn-stash /usr/local/bin
```

You can also install some useful programms:

 1. *colordiff* - if found, `svn diff` will be use it and colorize output.
 2. *realpath* (coreutils) - if found, local ignores with `svn st` will be work more proper from any directory.

## Client-side hooks

Currently supported hooks:

* pre-update
* post-update <svn_exit_status>
* pre-commit
* post-commit <svn_exit_status>
* pre-action <action> - generic hook, does not applied for actions above.
* post-action <action> <svn_exit_status> - generic hook, does not applied for actions above.

Hooks should be placed to the directory:
```
.svn/hooks
```

Hooks behaviour:

1. If pre-hooks returns non-zero status, all operations aborts and `svn` command will not be called.
2. Post-hooks runs in any case, but arrives `svn` return status as a first argument.

All hooks can see next env variables, setted by the parent script:

* *$SVN* - real subversion command
* *$SVN_ROOT* - root directory of the repository
* *$HOOK_DIR* - hooks directory


For additional info, see "samples/hooks" directory.


## Local ignores

In some cases it is impossible to add new ignores to repository (I known, it is ugly!), local
ignores solves this problem for end-user: you can describe you own ignores.

Ignores location:

```
.svn/ignores.txt
```

It is files with Basic Regexp (BRE, see `man 3 grep`) lines, that describes ingnores. Empty lines
and lines begins from hash (`#`) ignores.

See "samples/ignores.txt" for sample.

See "Output filtering" section for more details.


## Output filtering

Allow to setup output filters for various svn commands. Uses for "Local ignores" feature 
(see above)

Currently filtering hard to customize, but it in planes. Now next type of filters is supported:

* status - applied "Local ignores" feature
* log - bypass to `less -R`
* diff - bypass to `colordiff --color=auto` if present
* other - bypass to output without changes


## Stashing
Initially stashing command based on https://github.com/bapt/svnstash implementation.
Currently major changes:
- Do not revert untracked files by default
- More clean patch applaing to allow interactive conflict resolving
- Script renaming :-)

Planes: 
- Rework commands
- Use git for patch versioning
- Update existing stashes
- ???

## Command extending

## Other

### Arguments modifying

TODO: currently implemented for `svn status` and `svn diff` and hard-coded :-(

