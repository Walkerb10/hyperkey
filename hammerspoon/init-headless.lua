-- ============================================================================
-- HyperKey Headless Mode — For always-on servers (Mac Mini)
-- ============================================================================
-- No window management, no keyboard shortcuts.
-- Pure automation: HTTP bridge, file watchers, health monitoring.

-- Auto-reload on config change
hs.loadSpoon("ReloadConfiguration")
spoon.ReloadConfiguration:start()

-- ============================================================================
-- HTTP BRIDGE (core of headless mode)
-- ============================================================================
local bridge = dofile(hs.configdir .. "/modules/http-bridge.lua")
bridge.start()

-- ============================================================================
-- FILE WATCHERS
-- ============================================================================
local fw = dofile(hs.configdir .. "/modules/file-watcher.lua")

-- Watch for new recordings to transcribe
local recordingsPath = os.getenv("HOME") .. "/meop-brain/recordings"
local recordingsDir = hs.fs.attributes(recordingsPath)
if recordingsDir then
  fw.watch(recordingsPath, function(files)
    for _, file in ipairs(files) do
      local ext = file:match("%.(%w+)$")
      if ext and (ext == "mp3" or ext == "m4a" or ext == "wav" or ext == "mp4" or ext == "mov") then
        hs.notify.show("HyperKey", "New Recording", file:match("([^/]+)$"))
      end
    end
  end, "recordings")
end

-- Watch for deploy triggers
local deployTrigger = os.getenv("HOME") .. "/meop-brain/.deploy-trigger"
hs.pathwatcher.new(os.getenv("HOME") .. "/meop-brain/", function(files)
  for _, file in ipairs(files) do
    if file:match("%.deploy%-trigger$") then
      hs.notify.show("HyperKey", "Deploy Triggered", "Starting deploy pipeline...")
      hs.task.new("/bin/bash", function(exitCode, stdOut, stdErr)
        if exitCode == 0 then
          hs.notify.show("HyperKey", "Deploy Complete", "")
        else
          hs.notify.show("HyperKey", "Deploy Failed", (stdErr or ""):sub(1, 200))
        end
        -- Clean up trigger file
        os.remove(deployTrigger)
      end, {os.getenv("HOME") .. "/meop-brain/ops/deploy-live.sh"}):start()
    end
  end
end):start()

-- ============================================================================
-- SERVICE HEALTH MONITOR
-- ============================================================================
local healthCheckInterval = 60 -- seconds

hs.timer.doEvery(healthCheckInterval, function()
  -- Check critical services
  local services = {
    {name = "node", cmd = "pgrep -x node"},
    {name = "ollama", cmd = "pgrep -x ollama"},
  }

  for _, svc in ipairs(services) do
    local output = hs.execute(svc.cmd)
    if not output or #output == 0 then
      -- Service is down — could auto-restart or notify
      hs.notify.show("HyperKey Health", "Service Down", svc.name .. " is not running")
    end
  end

  -- Check disk space
  local df = hs.execute("df -h / | tail -1 | awk '{print $5}' | tr -d '%'")
  local usage = tonumber(df)
  if usage and usage > 90 then
    hs.notify.show("HyperKey Health", "Disk Warning", "Root disk at " .. usage .. "%")
  end
end)

-- ============================================================================
-- AUDIO ROUTING MONITOR (for call recorder)
-- ============================================================================
hs.audiodevice.watcher.setCallback(function(event)
  if event == "dIn " or event == "dOut" then
    local input = hs.audiodevice.defaultInputDevice()
    local output = hs.audiodevice.defaultOutputDevice()
    -- Log audio changes for debugging call recorder issues
    local logFile = io.open(os.getenv("HOME") .. "/meop-brain/logs/audio-routing.log", "a")
    if logFile then
      logFile:write(string.format("[%s] Input: %s | Output: %s\n",
        os.date("%Y-%m-%d %H:%M:%S"),
        input and input:name() or "none",
        output and output:name() or "none"))
      logFile:close()
    end
  end
end)
hs.audiodevice.watcher.start()

-- ============================================================================
-- GIT SYNC WATCHER
-- ============================================================================
-- Auto-pull when remote changes detected (supplements cron)
hs.timer.doEvery(120, function()
  hs.task.new("/bin/bash", function(exitCode, stdOut)
    if stdOut and stdOut:find("Already up to date") == nil and #stdOut > 0 then
      hs.notify.show("HyperKey", "Brain Synced", "New changes pulled")
    end
  end, {"-c", "cd ~/meop-brain && git pull --rebase 2>&1"}):start()
end)

-- ============================================================================
-- STARTUP
-- ============================================================================
hs.notify.show("HyperKey Headless", "by Meop", "HTTP Bridge on port " .. bridge.port)
print("HyperKey Headless started. Bridge: http://localhost:" .. bridge.port)
