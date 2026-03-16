#!/bin/bash
# HyperKey Installer — One command to supercharge your Mac
# Usage: bash install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo "  ╦ ╦╦ ╦╔═╗╔═╗╦═╗╦╔═╔═╗╦ ╦"
echo "  ╠═╣╚╦╝╠═╝║╣ ╠╦╝╠╩╗║╣ ╚╦╝"
echo "  ╩ ╩ ╩ ╩  ╚═╝╩╚═╩ ╩╚═╝ ╩ "
echo ""
echo "  macOS automation suite"
echo "  Caps Lock becomes your superpower."
echo ""

# Step 1: Check/install Homebrew
if ! command -v brew &> /dev/null; then
  echo -e "${YELLOW}Installing Homebrew...${NC}"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
echo -e "${GREEN}[OK]${NC} Homebrew"

# Step 2: Install Hammerspoon
if [ ! -d "/Applications/Hammerspoon.app" ]; then
  echo -e "${YELLOW}Installing Hammerspoon...${NC}"
  brew install --cask hammerspoon
fi
echo -e "${GREEN}[OK]${NC} Hammerspoon"

# Step 3: Install Karabiner-Elements
if [ ! -d "/Applications/Karabiner-Elements.app" ]; then
  echo -e "${YELLOW}Installing Karabiner-Elements...${NC}"
  brew install --cask karabiner-elements
fi
echo -e "${GREEN}[OK]${NC} Karabiner-Elements"

# Step 4: Deploy Hammerspoon config
echo -e "${YELLOW}Setting up Hammerspoon config...${NC}"
mkdir -p ~/.hammerspoon/Spoons/ReloadConfiguration.spoon

# Backup existing config if present
if [ -f ~/.hammerspoon/init.lua ] && ! grep -q "HyperKey by Meop" ~/.hammerspoon/init.lua 2>/dev/null; then
  cp ~/.hammerspoon/init.lua ~/.hammerspoon/init.lua.backup.$(date +%s)
  echo -e "${YELLOW}  Backed up existing init.lua${NC}"
fi

cp "$SCRIPT_DIR/hammerspoon/init.lua" ~/.hammerspoon/init.lua
cp "$SCRIPT_DIR/hammerspoon/Spoons/ReloadConfiguration.spoon/init.lua" \
   ~/.hammerspoon/Spoons/ReloadConfiguration.spoon/init.lua

echo -e "${GREEN}[OK]${NC} Hammerspoon config deployed"

# Step 5: Deploy Karabiner rules
echo -e "${YELLOW}Setting up Karabiner rules...${NC}"
mkdir -p ~/.config/karabiner/assets/complex_modifications

for rule in "$SCRIPT_DIR"/karabiner/*.json; do
  cp "$rule" ~/.config/karabiner/assets/complex_modifications/
done

echo -e "${GREEN}[OK]${NC} Karabiner rules deployed"
echo ""
echo -e "${YELLOW}IMPORTANT — Manual steps required:${NC}"
echo ""
echo "  1. Open System Settings > Privacy & Security > Accessibility"
echo "     Add: Hammerspoon, Karabiner-Elements"
echo ""
echo "  2. Open System Settings > Privacy & Security > Input Monitoring"
echo "     Add: Karabiner-Elements, karabiner_grabber"
echo ""
echo "  3. Open Karabiner-Elements > Complex Modifications > Add Rule"
echo "     Enable all HyperKey rules"
echo ""
echo "  4. Launch Hammerspoon (it should auto-start, or open from /Applications)"
echo ""
echo -e "${GREEN}Done! Hold Caps Lock + any key to start.${NC}"
echo "Run 'bash $SCRIPT_DIR/scripts/hyperkey-status.sh' to check status."
