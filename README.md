# svn-wrapper
Wrapper for command-line Subversion (svn) client with additional features

Some of initials ideas:
- Suppor for client-side pre- and post-operation hooks (pre-update, post-update and so on)
- Wrap some commands and add new abilities: 
 - Automatically use `colordiff` for `svn diff` if found
 - Client-side ignores for `svn status` command
- Add "new" commands, like `svn stash` for client-side stashing changes and switches between them.


## Client-side hooks

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

