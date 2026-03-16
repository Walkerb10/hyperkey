-- ============================================================================
-- MODULE: File Watcher
-- ============================================================================
-- Watch directories for changes and trigger actions.
-- Drop a file in a folder → auto-process it.

local fw = {}
fw.watchers = {}

-- Register a watch: fw.watch(path, callback)
-- callback receives (files, flagTables)
function fw.watch(path, callback, name)
  local watcher = hs.pathwatcher.new(path, function(files, flagTables)
    -- Filter out .DS_Store and hidden files
    local realFiles = {}
    for _, f in ipairs(files) do
      local basename = f:match("([^/]+)$")
      if basename and not basename:match("^%.") then
        table.insert(realFiles, f)
      end
    end
    if #realFiles > 0 then
      callback(realFiles, flagTables)
    end
  end)
  watcher:start()
  fw.watchers[name or path] = watcher
  return watcher
end

-- Pre-built watchers for common patterns

-- Watch a folder and run a shell command on new files
function fw.watchAndRun(path, command, name)
  return fw.watch(path, function(files)
    for _, file in ipairs(files) do
      local cmd = command:gsub("%%f", file)
      hs.task.new("/bin/bash", function(exitCode, stdOut, stdErr)
        if exitCode ~= 0 then
          hs.notify.show("HyperKey Watcher", name or "Error", (stdErr or ""):sub(1, 200))
        end
      end, {"-c", cmd}):start()
    end
  end, name)
end

-- Watch for new audio/video files and auto-transcribe
function fw.watchTranscribe(path, apiEndpoint)
  return fw.watch(path, function(files)
    for _, file in ipairs(files) do
      local ext = file:match("%.(%w+)$")
      if ext and (ext == "mp3" or ext == "m4a" or ext == "wav" or ext == "mp4" or ext == "mov" or ext == "webm") then
        hs.notify.show("HyperKey", "Transcribing", file:match("([^/]+)$"))
        local cmd = string.format("curl -s -X POST '%s' -F 'file=@%s'", apiEndpoint, file)
        hs.task.new("/bin/bash", function(exitCode, stdOut)
          if exitCode == 0 then
            hs.notify.show("HyperKey", "Transcription Done", (stdOut or ""):sub(1, 200))
          else
            hs.notify.show("HyperKey", "Transcription Failed", file:match("([^/]+)$"))
          end
        end, {"-c", cmd}):start()
      end
    end
  end, "transcribe-" .. path)
end

-- Stop all watchers
function fw.stopAll()
  for name, watcher in pairs(fw.watchers) do
    watcher:stop()
  end
  fw.watchers = {}
end

return fw
