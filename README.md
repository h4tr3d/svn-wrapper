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

   ```sh
   alias svn="/path/to/svn-wrapper.sh $@"
   ```

2. Re-loging to system.

For deb-based distros (Debian, Ubuntu, Mint) you can edit `~/.bashrc_aliases` instead of
`~/.bashrc`.

To activate `svn stash` command you should put `svn-stash` script to the one of directory under
PATH, for example: link it to `/usr/local/bin`:

```sh
sudo ln -s /path/to/svn-stash /usr/local/bin
```

Dependency:

1. *colordiff* (optional) - if found, `svn diff` will be use it and colorize diff output.
2. *realpath* (optional/required) - optional for wrapper, if found, local ignores will be work more proper from any tree location. Required for `svn stash` for proper work with binary and untracked files.
3. *git* (optional) - can be used by `svn stash` for stash versioning.
4. *GNU awk* (required)
5. *GNU coreutils* (required)
6. *GNU grep* (required)
7. *sed* (required)
8. *file* (required for `svn stash`)

Most of required packages already presents on most Linux systems.

## Client-side hooks

Currently supported hooks:

* `pre-update`
* `post-update <svn_exit_status>`
* `pre-commit`
* `post-commit <svn_exit_status>`
* `pre-action <action>` - generic hook, does not applied for actions above.
* `post-action <action> <svn_exit_status>` - generic hook, does not applied for actions above.

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
ignores solves this problem for end-user.

Ignores descriptions location:
```
.svn/ignores.txt
```

It is file with Basic Regex (BRE, see `man 3 grep`) one-per-line, that describes ignoring pattern. Empty lines
and lines starts with hash (`#`) skipped.

See "samples/ignores.txt" for example.

See "Output filtering" section for more details.


## Output filtering

Allow to setup output filters for various svn commands. Uses for "Local ignores" feature 
(see above).

Currently filtering hard to customize, but customization is planed. 

Now next type of filters is supported:

* `status` - applied "Local ignores" feature
* `log` - bypass to `less -R`
* `diff` - bypass to `colordiff --color=auto` if found
* `other` - bypass to output without changes


## Stashing

Initially stashing command based on https://github.com/bapt/svnstash implementation.

Currently major changes:

- Do not revert *all* untracked files by default
- Checkout stash revision before stash apply and update it back after: this solution allows to solve merge conflicts in interactive way. See `svn help patch` for more info. Note: only stashed files chekouted, it allows speed up process.
- Support binary and untracked files for stashing.
- Use reference for access to the stashes in additional to name for some commands (`show`, `apply`, `pop`, `rm`): `@{#}`, where `#` - number beginning from 1
- Updating existing stashes
- More clean VCS versioning
- Automatically calculate value for `svn path --strip #` argument: LLVM requires value 2, some other distos - greater, but general - 1.
- Bash completion

In plans:

* None. Seems all works as expected. Only issues fixes.

### Bash Completion

To setup Bash completion for `svn stash`, just include `svn-stash.bash_completion` from your `~/.bashrc`:

```sh
. /path/to/svn-stash.bash_completion
```

or copy to the `/etc/bash_completion.d` and re-login.

## Command extending

## Other

### Arguments modifying/rewriting

TODO: currently implemented for `svn status` and `svn diff` and hard-coded :-(

