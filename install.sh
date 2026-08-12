#!/bin/sh
# OptMem installer. Run it again to update: it only replaces the tool, and
# never touches memories that already exist.
#
# It installs the tool and prints the block to paste. It creates NO memory:
# memories are per project, made by running `memo init` inside a project, and
# the folder a `curl | sh` happens to run in is almost never that project.
#
# Two ways to run it:
#
#   sh install.sh          from a clone -- installs the `memo` sitting next to
#                          this script, so what you tested is what you get
#
#   curl -fsSL https://raw.githubusercontent.com/StockParrot/OptMem/main/install.sh | sh
#                          from the network -- downloads `memo` from the repo
#
# $OPTMEM_SRC names a local memo file outright. $OPTMEM_REPO and $OPTMEM_REF
# point the download at a fork or a branch.

set -e
DIR="$HOME/.optmem"
REPO="${OPTMEM_REPO:-StockParrot/OptMem}"
REF="${OPTMEM_REF:-main}"

command -v python3 >/dev/null || {
  echo "OptMem is one Python file, and this machine has no python3." >&2
  echo "Install python3, then run this line again." >&2
  exit 1
}

# Where does the tool come from? A clone first, the network second.
#
# This matters more than it looks: installing from a clone is the ONLY way to
# get a version you have edited or a fork. Downloading unconditionally means
# the installer silently overwrites your work with whatever upstream ships,
# and then runs commands that version may not have.
SRC="$OPTMEM_SRC"
if [ -z "$SRC" ]; then
  # The folder this script was read from. Piped through `curl | sh` there is
  # no path in $0 at all, so this falls back to the working directory.
  case "$0" in
    */*) HERE="${0%/*}" ;;
    *)   HERE="." ;;
  esac
  # The grep is the safety catch: it accepts a sibling file only if it really
  # is the OptMem tool. Without it, a stray file named `memo` in whatever
  # folder a `curl | sh` ran in would be installed as the tool.
  if [ -f "$HERE/memo" ] && grep -q "^\"\"\"OptMem:" "$HERE/memo" 2>/dev/null; then
    SRC="$HERE/memo"
  fi
fi

mkdir -p "$DIR"
# Write to a temporary name and move it into place, so an interrupted install
# leaves the previous working tool untouched instead of half a file.
if [ -n "$SRC" ]; then
  echo "Installing from $SRC"
  cp "$SRC" "$DIR/memo.new"
else
  echo "Downloading $REPO@$REF"
  curl -fsSL "https://raw.githubusercontent.com/$REPO/$REF/memo" -o "$DIR/memo.new"
fi
mv "$DIR/memo.new" "$DIR/memo"
chmod +x "$DIR/memo"

# A tool that cannot answer `prompt` is an old or broken copy, and the only
# useful moment to say so is now -- not in the middle of a session.
"$DIR/memo" prompt >/dev/null 2>&1 || {
  echo "Installed $DIR/memo, but it does not answer 'prompt'." >&2
  echo "That copy predates per-project memory. Install from a clone with:" >&2
  echo "  sh install.sh" >&2
  exit 1
}

echo
exec "$DIR/memo" prompt
