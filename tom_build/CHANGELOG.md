## 1.0.1

- **`TomShell.pipe` now actually feeds `input` to the command's stdin.** The
  previous implementation called `Process.runSync`, which offers no stdin
  channel, so the `input` argument was silently discarded — `pipe('cat',
  'hello')` returned `''` instead of `'hello'`. `input` is now written to a
  temp file and redirected into the command's stdin inside the shell, with the
  command wrapped in a subshell so the redirection binds to the whole command
  (including the head of a pipeline, e.g. `pipe('cat | tr a-z A-Z', 'hello')`
  → `'HELLO'`). Delivering `input` as file data (never on the command line)
  keeps shell metacharacters in it inert.

## 1.0.0

- Initial version.
