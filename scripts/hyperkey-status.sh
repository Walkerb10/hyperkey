#!/bin/bash
# HyperKey Status Check — shows what's running and what's not

echo "=== HyperKey Status ==="
echo ""

# Hammerspoon
if pgrep -x "Hammerspoon" > /dev/null; then
  echo "[OK] Hammerspoon running"
else
  echo "[!!] Hammerspoon NOT running"
fi

# Karabiner
if pgrep -x "karabiner_grabber" > /dev/null; then
  echo "[OK] Karabiner-Elements running"
else
  echo "[!!] Karabiner-Elements NOT running"
fi

# Check Karabiner config
if [ -f ~/.config/karabiner/karabiner.json ]; then
  rules=$(grep -c '"description"' ~/.config/karabiner/karabiner.json 2>/dev/null || echo "0")
  echo "     $rules rules loaded"
else
  echo "     No config found"
fi

# Accessibility
echo ""
echo "=== Permissions ==="
# Can't programmatically check, but remind
echo "Verify in System Settings > Privacy & Security:"
echo "  - Accessibility: Hammerspoon, Karabiner"
echo "  - Input Monitoring: Karabiner"

echo ""
echo "=== Hotkey Map ==="
echo "Hyper = Caps Lock (held) | Tap = Escape"
echo ""
echo "WINDOWS"
echo "  Hyper + Arrow    Half-screen snap"
echo "  Hyper + Up       Maximize"
echo "  Hyper + Down     Center (80%)"
echo "  Hyper + 1/2/3    Thirds"
echo "  Hyper + 4/5/6    Two-thirds / center"
echo "  Hyper + Q/W      Top-left / top-right quarter"
echo "  Hyper + N        Next monitor"
echo ""
echo "APPS"
echo "  Hyper + T        Terminal"
echo "  Hyper + C        Chrome"
echo "  Hyper + F        Finder"
echo "  Hyper + M        Messages"
echo ""
echo "TOOLS"
echo "  Hyper + V        Clipboard history"
echo "  Hyper + X        Quick shell command"
echo "  Hyper + ;        Quick note"
echo "  Hyper + Z        Toggle caffeinate"
echo "  Hyper + Tab      Window hints"
echo "  Hyper + E        Emoji picker"
echo "  Hyper + P        Screenshot to clipboard"
echo "  Hyper + O        Screenshot to file"
echo "  Hyper + R        Hard refresh (Chrome)"
echo "  Hyper + \`        Toggle Focus/DND"
echo ""
echo "NAVIGATION (via Karabiner)"
echo "  Hyper + H/J/K/L  Arrow keys (vim)"
echo "  Hyper + U/D      Page up/down"
echo "  Hyper + A/E      Home/End"
