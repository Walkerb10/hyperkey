-- ============================================================================
-- MODULE: Context-Aware Mode Switching
-- ============================================================================
-- Detects what you're doing and changes behavior automatically.
-- Meeting mode, coding mode, browsing mode — each with different hotkeys.

local ctx = {}
ctx.currentMode = "default"
ctx.callbacks = {}
ctx.appWatcher = nil

-- Mode definitions
ctx.modes = {
  meeting = {
    trigger = function()
      -- Active if Zoom, Meet, or FaceTime is running with audio
      local meetingApps = {"zoom.us", "Google Meet", "FaceTime", "Microsoft Teams", "Discord"}
      for _, appName in ipairs(meetingApps) do
        local app = hs.application.get(appName)
        if app and app:isRunning() then
          return true
        end
      end
      return false
    end,
    enter = function()
      -- Mute notifications
      hs.execute("defaults write com.apple.NotificationCenter doNotDisturb -bool true && killall NotificationCenter 2>/dev/null", true)
      hs.notify.show("HyperKey", "Meeting Mode", "Notifications muted")
    end,
    exit = function()
      hs.execute("defaults write com.apple.NotificationCenter doNotDisturb -bool false && killall NotificationCenter 2>/dev/null", true)
      hs.notify.show("HyperKey", "Meeting Mode Off", "Notifications restored")
    end
  },
  coding = {
    trigger = function()
      local app = hs.application.frontmostApplication()
      if app then
        local codingApps = {"Terminal", "Visual Studio Code", "Xcode", "iTerm2", "Cursor"}
        for _, name in ipairs(codingApps) do
          if app:name() == name then return true end
        end
      end
      return false
    end,
    enter = function() end,
    exit = function() end
  },
  browsing = {
    trigger = function()
      local app = hs.application.frontmostApplication()
      return app and (app:name() == "Google Chrome" or app:name() == "Safari" or app:name() == "Firefox")
    end,
    enter = function() end,
    exit = function() end
  }
}

function ctx.detectMode()
  -- Priority: meeting > coding > browsing > default
  for _, modeName in ipairs({"meeting", "coding", "browsing"}) do
    local mode = ctx.modes[modeName]
    if mode.trigger() then
      return modeName
    end
  end
  return "default"
end

function ctx.update()
  local newMode = ctx.detectMode()
  if newMode ~= ctx.currentMode then
    -- Exit old mode
    local oldMode = ctx.modes[ctx.currentMode]
    if oldMode and oldMode.exit then oldMode.exit() end

    -- Enter new mode
    local mode = ctx.modes[newMode]
    if mode and mode.enter then mode.enter() end

    ctx.currentMode = newMode

    -- Fire callbacks
    for _, cb in ipairs(ctx.callbacks) do
      cb(newMode)
    end
  end
end

-- Register a callback for mode changes
function ctx.onModeChange(callback)
  table.insert(ctx.callbacks, callback)
end

-- Get current mode
function ctx.getMode()
  return ctx.currentMode
end

-- Start watching
function ctx.start()
  -- Check every 5 seconds
  ctx.timer = hs.timer.doEvery(5, ctx.update)

  -- Also check on app activation
  ctx.appWatcher = hs.application.watcher.new(function(appName, eventType)
    if eventType == hs.application.watcher.activated or
       eventType == hs.application.watcher.launched or
       eventType == hs.application.watcher.terminated then
      ctx.update()
    end
  end)
  ctx.appWatcher:start()
end

function ctx.stop()
  if ctx.timer then ctx.timer:stop() end
  if ctx.appWatcher then ctx.appWatcher:stop() end
end

return ctx
