-- ============================================================================
-- HyperKey by Meop — macOS Automation Suite
-- ============================================================================
-- Caps Lock becomes your superpower key. One key unlocks everything below.
-- Works with Karabiner-Elements (Caps Lock → Hyper modifier)
--
-- Hyper = Caps Lock (held) = cmd+alt+ctrl+shift
-- ============================================================================

local hyper = {"cmd", "alt", "ctrl", "shift"}

-- Load user config (if exists)
local configFile = os.getenv("HOME") .. "/.hammerspoon/config.lua"
local userConfig = {}
if hs.fs.attributes(configFile) then
  userConfig = dofile(configFile) or {}
end

-- Auto-reload on config change
hs.loadSpoon("ReloadConfiguration")
spoon.ReloadConfiguration:start()

-- ============================================================================
-- MODULE: Window Management
-- ============================================================================
-- Hyper + arrows/numbers for instant window positioning
-- No mouse needed, no dragging, no thinking

local wm = {}

-- Grid positions
wm.positions = {
  left50    = {0, 0, 0.5, 1},
  right50   = {0.5, 0, 0.5, 1},
  top50     = {0, 0, 1, 0.5},
  bottom50  = {0, 0.5, 1, 0.5},
  topLeft   = {0, 0, 0.5, 0.5},
  topRight  = {0.5, 0, 0.5, 0.5},
  botLeft   = {0, 0.5, 0.5, 0.5},
  botRight  = {0.5, 0.5, 0.5, 0.5},
  center60  = {0.2, 0.1, 0.6, 0.8},
  center80  = {0.1, 0.05, 0.8, 0.9},
  max       = {0, 0, 1, 1},
  -- Thirds
  left33    = {0, 0, 0.333, 1},
  center33  = {0.333, 0, 0.334, 1},
  right33   = {0.666, 0, 0.334, 1},
  left66    = {0, 0, 0.666, 1},
  right66   = {0.334, 0, 0.666, 1},
}

function wm.move(pos)
  local win = hs.window.focusedWindow()
  if win then win:moveToUnit(pos) end
end

-- Arrow keys: halves
hs.hotkey.bind(hyper, "left",  function() wm.move(wm.positions.left50) end)
hs.hotkey.bind(hyper, "right", function() wm.move(wm.positions.right50) end)
hs.hotkey.bind(hyper, "up",    function() wm.move(wm.positions.max) end)
hs.hotkey.bind(hyper, "down",  function() wm.move(wm.positions.center80) end)

-- Number keys: thirds
hs.hotkey.bind(hyper, "1", function() wm.move(wm.positions.left33) end)
hs.hotkey.bind(hyper, "2", function() wm.move(wm.positions.center33) end)
hs.hotkey.bind(hyper, "3", function() wm.move(wm.positions.right33) end)
hs.hotkey.bind(hyper, "4", function() wm.move(wm.positions.left66) end)
hs.hotkey.bind(hyper, "5", function() wm.move(wm.positions.center60) end)
hs.hotkey.bind(hyper, "6", function() wm.move(wm.positions.right66) end)

-- Quarters (Q, W, A, S corners)
hs.hotkey.bind(hyper, "q", function() wm.move(wm.positions.topLeft) end)
hs.hotkey.bind(hyper, "w", function() wm.move(wm.positions.topRight) end)

-- Move window to next/previous screen
hs.hotkey.bind(hyper, "n", function()
  local win = hs.window.focusedWindow()
  if win then
    local screen = win:screen():next()
    win:moveToScreen(screen)
  end
end)

-- ============================================================================
-- MODULE: App Launcher
-- ============================================================================
-- Hyper + letter = instant app switch. No Cmd+Tab hunting.

local apps = userConfig.apps or {
  t = "Terminal",
  c = "Google Chrome",
  f = "Finder",
  m = "Messages",
  p = "System Preferences",
}

for key, app in pairs(apps) do
  hs.hotkey.bind(hyper, key, function()
    hs.application.launchOrFocus(app)
  end)
end

-- ============================================================================
-- MODULE: Clipboard Manager
-- ============================================================================
-- Hyper + V = clipboard history. Filters out API keys and passwords.

local clip = {
  history = {},
  max = userConfig.clipboardMax or 100,
  secretPatterns = {
    "^sk%-",         -- Stripe/OpenAI keys
    "^ghp_",         -- GitHub PATs
    "^ghs_",         -- GitHub secrets
    "^eyJ",          -- JWTs
    "^xoxb%-",       -- Slack bot tokens
    "^xoxp%-",       -- Slack user tokens
    "^AKIA",         -- AWS access keys
    "^AIza",         -- Google API keys
    "^sb%-",         -- Supabase keys
    "password",      -- Anything with password
    "secret",        -- Anything with secret
    "^ssh%-rsa",     -- SSH keys
    "^-----BEGIN",   -- PEM certificates
  }
}

function clip.isSecret(text)
  for _, pattern in ipairs(clip.secretPatterns) do
    if text:match(pattern) then return true end
  end
  return false
end

local clipWatcher = hs.pasteboard.watcher.new(function(content)
  if content and #content > 0 and not clip.isSecret(content) then
    -- Remove duplicates
    for i, item in ipairs(clip.history) do
      if item == content then
        table.remove(clip.history, i)
        break
      end
    end
    table.insert(clip.history, 1, content)
    if #clip.history > clip.max then
      table.remove(clip.history)
    end
  end
end)
clipWatcher:start()

hs.hotkey.bind(hyper, "v", function()
  local choices = {}
  for i, item in ipairs(clip.history) do
    local preview = item:gsub("\n", " "):sub(1, 100)
    if #item > 100 then preview = preview .. "..." end
    local age = ""
    table.insert(choices, {
      text = preview,
      subText = "#" .. i .. " | " .. #item .. " chars",
      item = item
    })
  end
  local chooser = hs.chooser.new(function(choice)
    if choice then
      hs.pasteboard.setContents(choice.item)
      hs.eventtap.keyStroke({"cmd"}, "v")
    end
  end)
  chooser:choices(choices)
  chooser:placeholderText("Search clipboard history...")
  chooser:show()
end)

-- ============================================================================
-- MODULE: Quick Shell
-- ============================================================================
-- Hyper + X = run any shell command, get notification with result

hs.hotkey.bind(hyper, "x", function()
  local button, cmd = hs.dialog.textPrompt("HyperKey Shell", "Command:", "", "Run", "Cancel")
  if button == "Run" and cmd and #cmd > 0 then
    hs.task.new("/bin/bash", function(exitCode, stdOut, stdErr)
      local output = (stdOut or "") .. (stdErr or "")
      if #output > 500 then output = output:sub(1, 500) .. "..." end
      if exitCode == 0 then
        hs.notify.show("HyperKey", "Success", output)
      else
        hs.notify.show("HyperKey", "Failed (exit " .. exitCode .. ")", output)
      end
    end, {"-c", cmd}):start()
  end
end)

-- ============================================================================
-- MODULE: System Watchers
-- ============================================================================
-- Passive intelligence: know when things change without checking

-- WiFi
local lastSSID = hs.wifi.currentNetwork()
hs.wifi.watcher.new(function()
  local newSSID = hs.wifi.currentNetwork()
  if newSSID ~= lastSSID then
    hs.notify.show("HyperKey", "WiFi Changed", newSSID or "Disconnected")
    lastSSID = newSSID
  end
end):start()

-- USB devices
hs.usb.watcher.new(function(data)
  local action = data.eventType == "added" and "Connected" or "Removed"
  hs.notify.show("HyperKey", "USB " .. action, data.productName or "Unknown")
end):start()

-- Audio routing
hs.audiodevice.watcher.setCallback(function(event)
  if event == "dIn " or event == "dOut" then
    local input = hs.audiodevice.defaultInputDevice()
    local output = hs.audiodevice.defaultOutputDevice()
    hs.notify.show("HyperKey", "Audio Changed",
      "In: " .. (input and input:name() or "?") ..
      "\nOut: " .. (output and output:name() or "?"))
  end
end)
hs.audiodevice.watcher.start()

-- ============================================================================
-- MODULE: Caffeinate (Prevent Sleep)
-- ============================================================================
-- Hyper + Z = toggle. Menu bar icon shows status.

local caffeineMenu = hs.menubar.new()
local caffeineActive = false

function updateCaffeineIcon()
  if caffeineActive then
    caffeineMenu:setTitle("☕")
    caffeineMenu:setTooltip("HyperKey: Sleep prevented")
  else
    caffeineMenu:setTitle("💤")
    caffeineMenu:setTooltip("HyperKey: Sleep allowed")
  end
end

function toggleCaffeine()
  caffeineActive = not caffeineActive
  if caffeineActive then
    hs.caffeinate.set("displayIdle", true)
    hs.caffeinate.set("systemIdle", true)
    hs.notify.show("HyperKey", "", "Keeping awake")
  else
    hs.caffeinate.set("displayIdle", false)
    hs.caffeinate.set("systemIdle", false)
    hs.notify.show("HyperKey", "", "Sleep allowed")
  end
  updateCaffeineIcon()
end

caffeineMenu:setClickCallback(toggleCaffeine)
updateCaffeineIcon()
hs.hotkey.bind(hyper, "z", toggleCaffeine)

-- ============================================================================
-- MODULE: Quick Notes (Hyper + ;)
-- ============================================================================
-- Instant note capture. Saves to ~/Desktop/hyperkey-notes.md with timestamp.

hs.hotkey.bind(hyper, ";", function()
  local button, note = hs.dialog.textPrompt("HyperKey Note", "Quick note:", "", "Save", "Cancel")
  if button == "Save" and note and #note > 0 then
    local timestamp = os.date("%Y-%m-%d %H:%M")
    local notesPath = userConfig.notesPath or (os.getenv("HOME") .. "/Desktop/hyperkey-notes.md")
    local file = io.open(notesPath, "a")
    if file then
      file:write("- **" .. timestamp .. "** " .. note .. "\n")
      file:close()
      hs.notify.show("HyperKey", "", "Note saved")
    end
  end
end)

-- ============================================================================
-- MODULE: Window Hints
-- ============================================================================
-- Hyper + Tab = show all windows with letter labels, press letter to switch

hs.hotkey.bind(hyper, "tab", function()
  hs.hints.windowHints()
end)

-- ============================================================================
-- MODULE: Emoji Picker (Hyper + E)
-- ============================================================================

hs.hotkey.bind(hyper, "e", function()
  hs.eventtap.keyStroke({"cmd", "ctrl"}, "space")
end)

-- ============================================================================
-- MODULE: Screen Capture Shortcuts
-- ============================================================================
-- Hyper + P = screenshot to clipboard (selection)
-- Hyper + O = screenshot to file (selection)

hs.hotkey.bind(hyper, "p", function()
  hs.task.new("/usr/sbin/screencapture", nil, {"-c", "-s"}):start()
end)

hs.hotkey.bind(hyper, "o", function()
  local filename = os.getenv("HOME") .. "/Desktop/screenshot-" .. os.date("%Y%m%d-%H%M%S") .. ".png"
  hs.task.new("/usr/sbin/screencapture", function()
    hs.notify.show("HyperKey", "", "Screenshot saved")
  end, {"-s", filename}):start()
end)

-- ============================================================================
-- MODULE: App-Specific Quick Actions
-- ============================================================================

-- Chrome: Hyper + R = hard refresh
-- (Karabiner sends the hyper mod, Hammerspoon intercepts before Chrome)
hs.hotkey.bind(hyper, "r", function()
  local app = hs.application.frontmostApplication()
  if app and app:name() == "Google Chrome" then
    hs.eventtap.keyStroke({"cmd", "shift"}, "r")
  else
    -- For other apps, generic refresh/reload behavior
    hs.eventtap.keyStroke({"cmd"}, "r")
  end
end)

-- ============================================================================
-- MODULE: Do Not Disturb Toggle (Hyper + `)
-- ============================================================================

hs.hotkey.bind(hyper, "`", function()
  hs.execute("shortcuts run 'Toggle Focus'", true)
  hs.notify.show("HyperKey", "", "Focus mode toggled")
end)

-- ============================================================================
-- MODULE: HTTP Bridge (run locally too for cross-machine calls)
-- ============================================================================
local bridge = dofile(hs.configdir .. "/modules/http-bridge.lua")
bridge.start()

-- ============================================================================
-- MODULE: Remote Control (call Mac Mini from here)
-- ============================================================================
local remote = dofile(hs.configdir .. "/modules/remote.lua")

-- Hyper + B = brain sync + deploy on Mac Mini
hs.hotkey.bind(hyper, "b", function()
  hs.notify.show("HyperKey", "", "Syncing brain on Mini...")
  remote.run("mini", "cd ~/meop-brain && git pull --rebase && git push", function(data, err)
    if err then
      hs.notify.show("HyperKey", "Sync Failed", err)
    else
      hs.notify.show("HyperKey", "Brain Synced", (data.output or ""):sub(1, 100))
    end
  end)
end)

-- Hyper + G = Mac Mini health check
hs.hotkey.bind(hyper, "g", function()
  remote.health("mini", function(data, err)
    if err then
      hs.notify.show("HyperKey", "Mini Offline", err)
    else
      local h = data.health or {}
      local msg = string.format("node:%s ollama:%s disk:%s",
        h.node or "?", h.ollama or "?", h.diskUsage or "?")
      hs.notify.show("HyperKey", "Mac Mini Health", msg)
    end
  end)
end)

-- Hyper + I = Mac Mini status
hs.hotkey.bind(hyper, "i", function()
  remote.status("mini", function(data, err)
    if err then
      hs.notify.show("HyperKey", "Mini Offline", tostring(err))
    else
      hs.notify.show("HyperKey", "Mac Mini", data.uptime or "unknown")
    end
  end)
end)

-- ============================================================================
-- MODULE: Context-Aware Modes
-- ============================================================================
local ctx = dofile(hs.configdir .. "/modules/context-aware.lua")
ctx.onModeChange(function(mode)
  hs.notify.show("HyperKey", "Mode: " .. mode, "")
end)
ctx.start()

-- ============================================================================
-- STARTUP
-- ============================================================================

hs.notify.show("HyperKey", "by Meop", "Ready. Hold Caps Lock + any key.")
