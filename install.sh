#!/bin/sh
# Install SnapNuts into Hammerspoon.
#
#   ./install.sh          symlink the Spoon (git pull updates it in place)
#   ./install.sh --copy   copy the Spoon instead (no link back to this checkout)
#
# Then reload Hammerspoon: menu bar icon -> Reload Config.
set -e

HERE="$(cd "$(dirname "$0")" && pwd)"
HS_DIR="$HOME/.hammerspoon"
SPOONS="$HS_DIR/Spoons"
TARGET="$SPOONS/SnapNuts.spoon"
INIT="$HS_DIR/init.lua"

if [ ! -d /Applications/Hammerspoon.app ]; then
  echo "Hammerspoon is not installed. Run:  brew install --cask hammerspoon"
  exit 1
fi

mkdir -p "$SPOONS"
rm -rf "$TARGET"
if [ "$1" = "--copy" ]; then
  cp -R "$HERE/SnapNuts.spoon" "$TARGET"
  echo "Copied SnapNuts.spoon to $SPOONS"
else
  ln -s "$HERE/SnapNuts.spoon" "$TARGET"
  echo "Linked $TARGET -> $HERE/SnapNuts.spoon"
fi

if ! grep -q 'loadSpoon("SnapNuts")' "$INIT" 2>/dev/null; then
  printf '\nhs.loadSpoon("SnapNuts")\nspoon.SnapNuts:start()\n' >> "$INIT"
  echo "Added SnapNuts to $INIT"
else
  echo "$INIT already loads SnapNuts"
fi

echo "Done. Reload Hammerspoon (menu bar icon -> Reload Config)."
