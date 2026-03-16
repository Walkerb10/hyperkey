-- ============================================================================
-- MODULE: Remote Control (Client)
-- ============================================================================
-- Call another machine's HTTP Bridge from this machine.
-- MacBook → Mac Mini commands over Tailscale.

local remote = {}

-- Machine registry
remote.machines = {
  mini = {host = "100.69.104.99", port = 17331},
  walker = {host = "100.106.26.102", port = 17331},
  griffin = {host = "100.90.86.74", port = 17331},
}

remote.token = nil

-- Load token
local tokenFile = io.open(os.getenv("HOME") .. "/.hyperkey-token", "r")
if tokenFile then
  remote.token = tokenFile:read("*l"):gsub("%s+", "")
  tokenFile:close()
end

function remote.call(machine, method, path, body, callback)
  local target = remote.machines[machine]
  if not target then
    if callback then callback(nil, "unknown machine: " .. machine) end
    return
  end

  local url = string.format("http://%s:%d%s", target.host, target.port, path)
  local headers = {["Content-Type"] = "application/json"}
  if remote.token then
    headers["Authorization"] = "Bearer " .. remote.token
  end

  hs.http.asyncPost(url, body or "", headers, function(status, responseBody)
    if callback then
      if status >= 200 and status < 300 then
        local data = hs.json.decode(responseBody)
        callback(data, nil)
      else
        callback(nil, "HTTP " .. status .. ": " .. (responseBody or ""))
      end
    end
  end)
end

-- Convenience methods

function remote.status(machine, callback)
  remote.call(machine, "GET", "/status", nil, callback)
end

function remote.run(machine, command, callback)
  local body = hs.json.encode({command = command})
  remote.call(machine, "POST", "/run", body, callback)
end

function remote.notify(machine, title, message, callback)
  local body = hs.json.encode({title = title, message = message})
  remote.call(machine, "POST", "/notify", body, callback)
end

function remote.deploy(machine, callback)
  remote.call(machine, "POST", "/deploy", "{}", callback)
end

function remote.health(machine, callback)
  remote.call(machine, "GET", "/health", nil, callback)
end

function remote.getClipboard(machine, callback)
  remote.call(machine, "GET", "/clipboard", nil, callback)
end

function remote.setClipboard(machine, content, callback)
  local body = hs.json.encode({content = content})
  remote.call(machine, "POST", "/clipboard", body, callback)
end

function remote.audio(machine, callback)
  remote.call(machine, "GET", "/audio", nil, callback)
end

return remote
