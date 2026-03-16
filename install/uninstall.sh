#!/bin/bash
# HyperKey Uninstaller — Clean removal

set -e

echo "Uninstalling HyperKey..."

# Remove Hammerspoon config (keep app)
if [ -f ~/.hammerspoon/init.lua ] && grep -q "HyperKey by Meop" ~/.hammerspoon/init.lua 2>/dev/null; then
  rm ~/.hammerspoon/init.lua
  echo "[OK] Removed Hammerspoon config"
  # Restore backup if exists
  backup=$(ls -t ~/.hammerspoon/init.lua.backup.* 2>/dev/null | head -1)
  if [ -n "$backup" ]; then
    mv "$backup" ~/.hammerspoon/init.lua
    echo "[OK] Restored previous config"
  fi
fi

# Remove Karabiner rules
for rule in hyper-key.json vim-arrows.json text-manipulation.json; do
  rm -f ~/.config/karabiner/assets/complex_modifications/"$rule"
done
echo "[OK] Removed Karabiner rules"

echo ""
echo "HyperKey removed. Apps (Hammerspoon, Karabiner) left installed."
echo "To fully remove: brew uninstall --cask hammerspoon karabiner-elements"
