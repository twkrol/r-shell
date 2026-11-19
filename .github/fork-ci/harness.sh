#!/usr/bin/env bash
# Fork-only check, not part of the PR. Runs the remote commands the fix builds
# (commands.txt, generated from src-tauri/src/commands.rs) the way sshd does,
# `$SHELL -c <command>`, against a hostile file name, in every shell given.
# Kept bash 3.2 compatible so it also runs on macOS.
set -u
here=$(cd "$(dirname "$0")" && pwd)
i=0
while IFS= read -r line; do cmds[$i]=$line; i=$((i + 1)); done < "$here/commands.txt"
name="x\'; touch pwned; #!"
content=$'alpha\nneedle one\nNEEDLE two\n'
fail=0
check() { # label expected actual
  if [ "$2" = "$3" ]; then echo "  ok   $1"; else echo "  FAIL $1: expected [$2] got [$3]"; fail=1; fi
}
uname -a
for shell in "$@"; do
  command -v "$shell" >/dev/null 2>&1 || { echo "== $shell: not installed, skipped"; continue; }
  echo "== $shell ($(command -v "$shell"))"
  rm -rf /tmp/rshell-qt && mkdir -p /tmp/rshell-qt && cd /tmp/rshell-qt || exit 2
  dir="/tmp/rshell-qt/$name"; file="$dir/$name"
  run() { "$shell" -c "$1"; }
  run "${cmds[0]}"; check "mkdir status" 0 $?
  [ -d "$dir" ]; check "mkdir made the literal directory" 0 $?
  printf '%s' "$content" > "$file"
  check "cat" "alpha|needle one|NEEDLE two|" "$(run "${cmds[1]}" | tr '\n' '|')"
  check "tail -n 1" "NEEDLE two|" "$(run "${cmds[2]}" | tr '\n' '|')"
  check "size" "28" "$(run "${cmds[3]}" | tr -d ' ')"
  check "base64" "YWxwaGEKbmVlZGxlIG9uZQpORUVETEUgdHdvCg==" "$(run "${cmds[4]}")"
  check "du path" "$file" "$(run "${cmds[5]}" | cut -f2-)"
  check "read_log" "needle one|NEEDLE two|" "$(run "${cmds[6]}" | tr '\n' '|')"
  check "search fixed string" "2:needle one|3:NEEDLE two|" "$(run "${cmds[7]}" | tr '\n' '|')"
  check "search regex starting with a dash" "3:NEEDLE two|" "$(run "${cmds[8]}" | tr '\n' '|')"
  run "${cmds[9]}"; check "rm -f status" 0 $?
  [ ! -e "$file" ]; check "file removed" 0 $?
  run "${cmds[10]}"; check "rm -rf status" 0 $?
  [ ! -e "$dir" ]; check "directory removed" 0 $?
  [ ! -e /tmp/rshell-qt/pwned ]; check "no injected command ran" 0 $?
done
exit $fail
