#!/bin/bash
# Build "Tears of the Kingdom.app" (or Breath of the Wild) on this Mac with MacNativeGames
# (https://github.com/ly05010419/MacNativeGames) from YOUR OWN game dump and prod.keys.
#
# There is no downloadable installer for this one: the app is generated from the game file itself, so it has to be
# built on your Mac. This script checks the machine, installs the build tools, clones (or updates) MacNativeGames into
# ~/MacNativeGames, and forwards every argument to its build_app.py.
#
# Usage (same arguments as build_app.py):
#   ./build-totk.sh ~/Games/totk.xci -k ~/keys/prod.keys
#   ./build-totk.sh ~/Games/totk.xci -k ~/keys/prod.keys --update ~/Games/1.4.3.nsp -o "/Applications/Tears of the Kingdom.app"
#   ./build-totk.sh ~/Games/totk.nsp -k ~/keys/prod.keys --firmware ~/Games/firmware
#
# Requirements: Apple silicon, macOS 26 or later, ~25 GB free (40 GB with an update), internet for the tools.
# Set MNG_DIR to clone somewhere other than ~/MacNativeGames. Set MNG_SKIP_UPDATE=1 to build with the clone as is.
set -euo pipefail

MNG_DIR="${MNG_DIR:-$HOME/MacNativeGames}"
MNG_REPO="https://github.com/ly05010419/MacNativeGames.git"
PYTHON=python3.14

fail() { printf '\033[31m%s\033[0m\n' "$*" >&2; exit 1; }
step() { printf '\n\033[1m== %s\033[0m\n' "$*"; }

if [ $# -eq 0 ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
fi

step "Checking this Mac"
[ "$(uname -s)" = Darwin ] || fail "This script only runs on macOS."
[ "$(uname -m)" = arm64 ] || fail "MacNativeGames needs an Apple silicon Mac (this one is $(uname -m))."
OS_MAJOR=$(sw_vers -productVersion | cut -d. -f1)
[ "$OS_MAJOR" -ge 26 ] || fail "MacNativeGames needs macOS 26 or later (this Mac runs $(sw_vers -productVersion))."
FREE_GB=$(df -g "$HOME" | awk 'NR==2 {print $4}')
[ "${FREE_GB:-0}" -ge 25 ] || echo "Warning: only ${FREE_GB} GB free in your home volume; a base build needs about 25 GB, an update build about 40 GB."

# The game file and the keys are the first positional argument and the value after -k; make sure both exist early
GAME=""; KEYS=""; prev=""
for a in "$@"; do
  if [ "$prev" = "-k" ] || [ "$prev" = "--keys" ]; then KEYS="$a"; fi
  if [ -z "$GAME" ] && [ "${a#-}" = "$a" ] && [ -z "$prev" -o "${prev#-}" = "$prev" ]; then GAME="$a"; fi
  prev="$a"
done
[ -n "$GAME" ] && [ -f "$GAME" ] || fail "Game file not found: '${GAME:-<none>}'. Pass your .xci or .nsp as the first argument."
[ -n "$KEYS" ] && [ -f "$KEYS" ] || fail "prod.keys not found: '${KEYS:-<none>}'. Pass it with -k /path/to/prod.keys."

step "Xcode command line tools"
if ! xcode-select -p >/dev/null 2>&1; then
  echo "Installing the Xcode command line tools. Finish the dialog that appears, then run this script again."
  xcode-select --install || true
  exit 1
fi

step "Homebrew and build dependencies"
if ! command -v brew >/dev/null 2>&1; then
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    fail "Homebrew is not installed. Install it from https://brew.sh and run this script again."
  fi
fi
brew install opus libvpx python@3.14
command -v "$PYTHON" >/dev/null 2>&1 || PYTHON="$(brew --prefix python@3.14)/bin/python3.14"
[ -x "$PYTHON" ] || fail "python3.14 is not on PATH after 'brew install python@3.14'. Open a new terminal and retry."

step "MacNativeGames source in $MNG_DIR"
if [ -d "$MNG_DIR/.git" ]; then
  if [ "${MNG_SKIP_UPDATE:-0}" != 1 ]; then
    git -C "$MNG_DIR" pull --ff-only || echo "Warning: could not fast-forward $MNG_DIR; building with what is there."
  fi
else
  [ -e "$MNG_DIR" ] && fail "$MNG_DIR exists but is not a git checkout. Move it or set MNG_DIR to another path."
  git clone "$MNG_REPO" "$MNG_DIR"
fi
[ -f "$MNG_DIR/build_app.py" ] || fail "build_app.py not found in $MNG_DIR."

step "Building the app (this takes a while: decrypting ~17 GB of game data and preparing shaders)"
cd "$MNG_DIR"
exec "$PYTHON" build_app.py "$@"
