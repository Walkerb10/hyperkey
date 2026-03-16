# HyperKey

Your Caps Lock key is wasted. HyperKey turns it into a universal shortcut layer for macOS.

Hold Caps Lock + any key to control windows, launch apps, manage clipboard, run shell commands, and more. Tap Caps Lock alone for Escape.

## Install

```bash
git clone https://github.com/Walkerb10/hyperkey.git
cd hyperkey
bash install/install.sh
```

Grant permissions when prompted (Accessibility + Input Monitoring).

Open Karabiner-Elements > Complex Modifications > Add Rule > enable all HyperKey rules.

Done. Hold Caps Lock and try it.

## What You Get

### Window Management
| Shortcut | Action |
|----------|--------|
| Hyper + Arrow Keys | Snap to halves |
| Hyper + Up | Maximize |
| Hyper + Down | Center (80%) |
| Hyper + 1/2/3 | Snap to thirds |
| Hyper + 4/5/6 | Two-thirds / center |
| Hyper + Q/W | Quarter: top-left / top-right |
| Hyper + N | Move to next monitor |
| Hyper + Tab | Window hints (visual switcher) |

### App Launcher
| Shortcut | App |
|----------|-----|
| Hyper + T | Terminal |
| Hyper + C | Chrome |
| Hyper + F | Finder |
| Hyper + M | Messages |

### Tools
| Shortcut | Action |
|----------|--------|
| Hyper + V | Clipboard history (100 items, auto-filters secrets) |
| Hyper + X | Quick shell command |
| Hyper + ; | Quick note with timestamp |
| Hyper + Z | Toggle caffeinate (prevent sleep) |
| Hyper + E | Emoji picker |
| Hyper + P | Screenshot selection to clipboard |
| Hyper + O | Screenshot selection to file |
| Hyper + R | Hard refresh (Chrome) / Refresh (other apps) |
| Hyper + ` | Toggle Focus / Do Not Disturb |

### Vim Navigation (everywhere, not just your editor)
| Shortcut | Action |
|----------|--------|
| Hyper + H/J/K/L | Arrow keys |
| Hyper + U/D | Page up / Page down |
| Hyper + A/E | Home / End |

### Passive Watchers
- WiFi change notifications
- USB device connect/disconnect alerts
- Audio device routing changes
- Menu bar caffeinate status indicator

## Customize

Edit `~/.hammerspoon/init.lua` to add your own hotkeys. Config auto-reloads on save.

Add app launchers:
```lua
-- in the apps table
apps = {
  t = "Terminal",
  c = "Google Chrome",
  s = "Slack",        -- add your apps
  d = "Discord",
}
```

Add window positions:
```lua
-- in wm.positions
myLayout = {0.1, 0.1, 0.8, 0.8},  -- {x, y, width, height} as fractions
```

## How It Works

Two open-source tools working together:

- **Karabiner-Elements** remaps Caps Lock at the kernel level into a "Hyper" modifier (Cmd+Alt+Ctrl+Shift). This modifier doesn't conflict with any existing shortcuts in any app.
- **Hammerspoon** listens for Hyper + key combinations and executes Lua scripts: moving windows, launching apps, managing clipboard, etc.

Both are well-maintained, trusted by hundreds of thousands of macOS users, and require no background processes beyond what's already running.

## Security

- Clipboard manager auto-filters API keys, tokens, passwords, SSH keys, and JWTs
- No data leaves your machine. Ever. Everything is local.
- No analytics, no telemetry, no network calls
- Full source code included. Read every line.

## Uninstall

```bash
bash install/uninstall.sh
```

Removes configs only. Apps stay installed unless you also run:
```bash
brew uninstall --cask hammerspoon karabiner-elements
```

## Requirements

- macOS 13+ (Ventura or later)
- Homebrew

## License

MIT. Do whatever you want with it.

---

Built by [Meop](https://meop.live)
