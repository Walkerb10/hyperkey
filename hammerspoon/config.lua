-- HyperKey User Configuration
-- Edit this file to customize your setup. Changes auto-reload.
--
-- This file is loaded by init.lua. Override any defaults here.

local config = {}

-- Your app launcher bindings (Hyper + key = app)
-- Comment out or change any of these
config.apps = {
  t = "Terminal",
  c = "Google Chrome",
  f = "Finder",
  m = "Messages",
  -- s = "Slack",
  -- d = "Discord",
  -- i = "iTerm",
  -- v = "Visual Studio Code",
}

-- Clipboard history size
config.clipboardMax = 100

-- Quick notes file location
config.notesPath = os.getenv("HOME") .. "/Desktop/hyperkey-notes.md"

-- Screenshot save location
config.screenshotDir = os.getenv("HOME") .. "/Desktop"

-- Show notifications for system events
config.notify = {
  wifi = true,
  usb = true,
  audio = true,
}

return config
