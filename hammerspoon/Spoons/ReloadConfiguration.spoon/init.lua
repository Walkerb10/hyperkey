--- === ReloadConfiguration ===
--- Auto-reload Hammerspoon config when any .lua file changes

local obj = {}
obj.__index = obj
obj.name = "ReloadConfiguration"

function obj:start()
  self.watcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", function(files)
    for _, file in pairs(files) do
      if file:sub(-4) == ".lua" then
        hs.reload()
        return
      end
    end
  end)
  self.watcher:start()
  return self
end

function obj:stop()
  if self.watcher then self.watcher:stop() end
  return self
end

return obj
