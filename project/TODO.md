# Ideas

- improve tab-awareness
- current method for jumping to Git buffers does not work for tabs
  * (DONE) open the buffer in a new window
  * optionally: jump across tab pages
- how about jumping to windows?
  * (DONE) open the buffer in a new window
  * optionally: jump across tab pages
- update buffer after executing a command: `:GitBranch,` `:GitRemote`, `:GitStash`, ...
- feed output of `git apply` into quickfix
- use modifiers to split the window or open on a new tab when running `:GitStatus` et al.
- make the plug-in aware of `netrw`

## Documentation

- add more suggestions for custom menu entries to `s:Git_CustomMenu`
- add current custom menu entries to documentation and/or `git-support/rc/`,
  as a starting point for customization
- document `g:Git_Editor`, and the use of `$GIT_EDITOR`, and add it to `:GitSupportSettings`

## Refactor

- make `:GitLog` paged
- do not use `sync fromstart` in syntax highlighting,
  is extremely slow for diff and log
- rename function `GitS_FoldLog` into `GitS_FoldLogTxt`
- set `foldmethod` individually and not in `s:OpenGitBuffer`
