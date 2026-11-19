#!/usr/bin/env bash
# Fork-only, not part of the PR. Shows what main sends today when the file
# browser deletes a file named  x\'; touch pwned; #  and what each login shell
# does with that command line.
set -u
name="x\'; touch pwned; #"
old="rm -f 'x\'\''; touch pwned; #'"
printf 'file name: %s\ncommand  : %s\n\n' "$name" "$old"
for shell in "$@"; do
  command -v "$shell" >/dev/null 2>&1 || { echo "$shell: not installed"; continue; }
  d=$(mktemp -d) && cd "$d" || exit 2
  : > "$name"
  "$shell" -c "$old" >/dev/null 2>&1
  status=$?
  printf '%-5s exit=%s injected=%s file_deleted=%s\n' "$shell" "$status" \
    "$([ -e pwned ] && echo YES || echo no)" "$([ -e "$name" ] && echo no || echo yes)"
done
echo
echo "tcsh and an exclamation mark (rm -f 'a!b'):"
if command -v tcsh >/dev/null 2>&1; then
  d=$(mktemp -d) && cd "$d" || exit 2
  : > 'a!b'
  tcsh -c "rm -f 'a!b'"
  echo "tcsh  exit=$? file_deleted=$([ -e 'a!b' ] && echo no || echo yes)"
fi
echo
echo "old image preview command (base64 with a file operand), run by sh:"
d=$(mktemp -d) && cd "$d" || exit 2
printf 'hello' > plain.txt
sh -c "base64 -w0 'plain.txt' 2>/dev/null || base64 'plain.txt' | tr -d '\n'"
echo " exit=$?"
