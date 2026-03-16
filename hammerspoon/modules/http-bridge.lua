-- ============================================================================
-- MODULE: HTTP Bridge
-- ============================================================================
-- Exposes Hammerspoon as a REST API so other machines can trigger actions.
-- Mac Mini runs this as the hub. MacBook calls it.
--
-- GET  /status          → system status JSON
-- POST /run             → execute a shell command, return output
-- POST /notify          → show a notification
-- GET  /clipboard       → get current clipboard
-- POST /clipboard       → set clipboard contents
-- GET  /audio           → audio device info
-- POST /audio/input     → set input device
-- POST /audio/output    → set output device
-- GET  /windows         → list all windows
-- POST /focus           → focus an app by name
-- POST /deploy          → trigger deploy pipeline
-- GET  /health          → service health checks

local bridge = {}
bridge.port = 17331
bridge.server = nil
bridge.authToken = nil

-- Load auth token from file (never hardcode)
local tokenFile = io.open(os.getenv("HOME") .. "/.hyperkey-token", "r")
if tokenFile then
  bridge.authToken = tokenFile:read("*l"):gsub("%s+", "")
  tokenFile:close()
end

function bridge.checkAuth(request)
  if not bridge.authToken then return true end -- no token = no auth required
  local header = request.headers and request.headers["Authorization"]
  if not header then return false end
  return header == "Bearer " .. bridge.authToken
end

function bridge.jsonResponse(code, data)
  local json = hs.json.encode(data)
  return json, code, {["Content-Type"] = "application/json"}
end

function bridge.start()
  bridge.server = hs.httpserver.new(false, false)
  bridge.server:setPort(bridge.port)
  bridge.server:setCallback(function(method, path, headers, body)
    local request = {method = method, path = path, headers = headers, body = body}

    if not bridge.checkAuth(request) then
      return bridge.jsonResponse(401, {error = "unauthorized"})
    end

    -- Route
    if path == "/status" and method == "GET" then
      return bridge.handleStatus()
    elseif path == "/run" and method == "POST" then
      return bridge.handleRun(body)
    elseif path == "/notify" and method == "POST" then
      return bridge.handleNotify(body)
    elseif path == "/clipboard" and method == "GET" then
      return bridge.handleGetClipboard()
    elseif path == "/clipboard" and method == "POST" then
      return bridge.handleSetClipboard(body)
    elseif path == "/audio" and method == "GET" then
      return bridge.handleAudio()
    elseif path == "/audio/input" and method == "POST" then
      return bridge.handleSetAudioInput(body)
    elseif path == "/audio/output" and method == "POST" then
      return bridge.handleSetAudioOutput(body)
    elseif path == "/windows" and method == "GET" then
      return bridge.handleWindows()
    elseif path == "/focus" and method == "POST" then
      return bridge.handleFocus(body)
    elseif path == "/deploy" and method == "POST" then
      return bridge.handleDeploy(body)
    elseif path == "/health" and method == "GET" then
      return bridge.handleHealth()
    else
      return bridge.jsonResponse(404, {error = "not found"})
    end
  end)

  bridge.server:start()
  print("HyperKey HTTP Bridge listening on port " .. bridge.port)
end

-- Handlers

function bridge.handleStatus()
  local info = hs.host.localizedName()
  local uptime = hs.execute("uptime -p 2>/dev/null || uptime")
  return bridge.jsonResponse(200, {
    machine = info,
    uptime = uptime:gsub("\n", ""),
    hammerspoon = hs.processInfo.bundleVersion,
    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
  })
end

function bridge.handleRun(body)
  local data = hs.json.decode(body)
  if not data or not data.command then
    return bridge.jsonResponse(400, {error = "missing 'command' field"})
  end
  -- Safety: block destructive commands unless explicitly allowed
  local dangerous = {"rm -rf /", "mkfs", "dd if=", "> /dev/sd"}
  for _, pattern in ipairs(dangerous) do
    if data.command:find(pattern, 1, true) then
      return bridge.jsonResponse(403, {error = "blocked: dangerous command"})
    end
  end
  local output, status, exitType, exitCode = hs.execute(data.command, true)
  return bridge.jsonResponse(200, {
    output = output or "",
    exitCode = exitCode or -1,
    success = (exitCode == 0)
  })
end

function bridge.handleNotify(body)
  local data = hs.json.decode(body)
  if not data then
    return bridge.jsonResponse(400, {error = "invalid JSON"})
  end
  hs.notify.show(
    data.title or "HyperKey",
    data.subtitle or "",
    data.message or ""
  )
  return bridge.jsonResponse(200, {sent = true})
end

function bridge.handleGetClipboard()
  local content = hs.pasteboard.getContents() or ""
  return bridge.jsonResponse(200, {content = content, length = #content})
end

function bridge.handleSetClipboard(body)
  local data = hs.json.decode(body)
  if not data or not data.content then
    return bridge.jsonResponse(400, {error = "missing 'content' field"})
  end
  hs.pasteboard.setContents(data.content)
  return bridge.jsonResponse(200, {set = true})
end

function bridge.handleAudio()
  local input = hs.audiodevice.defaultInputDevice()
  local output = hs.audiodevice.defaultOutputDevice()
  local allInputs = {}
  local allOutputs = {}
  for _, dev in ipairs(hs.audiodevice.allInputDevices()) do
    table.insert(allInputs, {name = dev:name(), uid = dev:uid(), volume = dev:inputVolume()})
  end
  for _, dev in ipairs(hs.audiodevice.allOutputDevices()) do
    table.insert(allOutputs, {name = dev:name(), uid = dev:uid(), volume = dev:outputVolume()})
  end
  return bridge.jsonResponse(200, {
    input = input and {name = input:name(), uid = input:uid()} or nil,
    output = output and {name = output:name(), uid = output:uid()} or nil,
    allInputs = allInputs,
    allOutputs = allOutputs
  })
end

function bridge.handleSetAudioInput(body)
  local data = hs.json.decode(body)
  if not data or not data.name then
    return bridge.jsonResponse(400, {error = "missing 'name' field"})
  end
  for _, dev in ipairs(hs.audiodevice.allInputDevices()) do
    if dev:name() == data.name then
      dev:setDefaultInputDevice()
      return bridge.jsonResponse(200, {set = data.name})
    end
  end
  return bridge.jsonResponse(404, {error = "device not found: " .. data.name})
end

function bridge.handleSetAudioOutput(body)
  local data = hs.json.decode(body)
  if not data or not data.name then
    return bridge.jsonResponse(400, {error = "missing 'name' field"})
  end
  for _, dev in ipairs(hs.audiodevice.allOutputDevices()) do
    if dev:name() == data.name then
      dev:setDefaultOutputDevice()
      return bridge.jsonResponse(200, {set = data.name})
    end
  end
  return bridge.jsonResponse(404, {error = "device not found: " .. data.name})
end

function bridge.handleWindows()
  local windows = {}
  for _, win in ipairs(hs.window.allWindows()) do
    local app = win:application()
    table.insert(windows, {
      title = win:title(),
      app = app and app:name() or "unknown",
      id = win:id(),
      visible = win:isVisible(),
      frame = win:frame()
    })
  end
  return bridge.jsonResponse(200, {windows = windows, count = #windows})
end

function bridge.handleFocus(body)
  local data = hs.json.decode(body)
  if not data or not data.app then
    return bridge.jsonResponse(400, {error = "missing 'app' field"})
  end
  local result = hs.application.launchOrFocus(data.app)
  return bridge.jsonResponse(200, {focused = data.app, success = result})
end

function bridge.handleDeploy(body)
  local data = hs.json.decode(body) or {}
  local script = data.script or os.getenv("HOME") .. "/meop-brain/ops/deploy-live.sh"
  -- Run async so we don't block the HTTP response
  hs.task.new("/bin/bash", function(exitCode, stdOut, stdErr)
    hs.notify.show("HyperKey Deploy",
      exitCode == 0 and "Success" or "Failed",
      (stdOut or ""):sub(1, 200))
  end, {script}):start()
  return bridge.jsonResponse(202, {queued = true, script = script})
end

function bridge.handleHealth()
  local checks = {}

  -- Check key processes
  local services = {"node", "nginx", "ollama"}
  for _, svc in ipairs(services) do
    local output = hs.execute("pgrep -x " .. svc .. " 2>/dev/null")
    checks[svc] = output and #output > 0 and "running" or "stopped"
  end

  -- Disk space
  local df = hs.execute("df -h / | tail -1 | awk '{print $5}'")
  checks.diskUsage = df and df:gsub("%s+", "") or "unknown"

  -- Memory
  local mem = hs.execute("vm_stat | head -5")
  checks.memory = mem or "unknown"

  -- Load average
  local load = hs.execute("sysctl -n vm.loadavg")
  checks.loadAvg = load and load:gsub("%s+", " "):gsub("^%s+", "") or "unknown"

  return bridge.jsonResponse(200, {health = checks, timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")})
end

function bridge.stop()
  if bridge.server then
    bridge.server:stop()
    bridge.server = nil
  end
end

return bridge
