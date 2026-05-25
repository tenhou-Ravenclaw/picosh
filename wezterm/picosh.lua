local wezterm = require 'wezterm'
local M = {}

-- ─── AI waiting indicator ─────────────────────────────────────────────────

local waiting_panes = {}
local prev_waiting = {}
local tick = 0
local NOTIFY_LOG = (os.getenv('TEMP') or os.getenv('TMP') or '') .. '\\picosh\\notifications.log'

-- Primary: Claude Code Stop hook sends OSC SetUserVar → fires this event
wezterm.on('user-var-changed', function(window, pane, name, value)
  if name == 'picosh_waiting' then
    waiting_panes[pane:pane_id()] = true
  end
end)

-- ─── status bar ──────────────────────────────────────────────────────────

local branch_cache = {}   -- keyed by cwd
local BRANCH_REFRESH = 20  -- ticks (~3 seconds)

local function get_cwd(pane)
  local uri = pane:get_current_working_dir()
  if not uri then return nil end
  local p = uri.file_path or tostring(uri)
  p = p:gsub('^/', ''):gsub('[/\\]+$', '')  -- strip leading / and trailing slash
  return p ~= '' and p or nil
end

local function get_branch(cwd)
  local c = branch_cache[cwd] or {value = nil, at = -999}
  if tick - c.at < BRANCH_REFRESH then return c.value end
  local ok, stdout, _ = wezterm.run_child_process({'git', '-C', cwd, 'branch', '--show-current'})
  c.value = (ok and stdout and stdout:gsub('%s', '') ~= '') and stdout:gsub('%s+$', '') or nil
  c.at = tick
  branch_cache[cwd] = c
  return c.value
end

local function get_cwd(text)
  -- Parse PowerShell prompt: "PS C:\path\to\dir>"
  -- Match the LAST occurrence so we get the most recent prompt
  local path = nil
  for p in text:gmatch('PS ([A-Za-z]:[^\r\n>]+)>') do path = p end
  return path and path:gsub('%s+$', '') or nil
end

-- Always poll: handles both on/off detection as before
-- hook-based detection above is additive (fires before text is visible)
wezterm.on('update-status', function(window, pane)
  tick = tick + 1
  local pane_id = pane:pane_id()
  local text5 = pane:get_lines_as_text(5)
  local is_waiting = text5:match('%? for shortcuts') ~= nil

  if is_waiting and not prev_waiting[pane_id] then
    if wezterm.toast_notification then
      wezterm.toast_notification('picosh', 'Claude Code is waiting for input', nil, 4000)
    end
  end
  prev_waiting[pane_id] = is_waiting
  waiting_panes[pane_id] = is_waiting

  local parts = {}

  -- Use more lines for cwd so the prompt is found even near top of screen
  local text50 = pane:get_lines_as_text(50)
  local cwd = get_cwd(text50)
  if cwd then
    local branch = get_branch(cwd)
    if branch then
      local dir = cwd:match('[^\\/]+$') or cwd
      table.insert(parts, dir)
      table.insert(parts, ' ' .. branch)
    end
  end

  local status_text = #parts > 0 and (' ' .. table.concat(parts, '  ') .. ' ') or ''

  if is_waiting then
    -- Include animated value in right_status to force format-tab-title repaint every tick
    local phase = (tick * 0.35) % (2 * math.pi)
    local v = math.floor(158 + 80 * math.sin(phase))
    window:set_right_status(wezterm.format({
      { Text = status_text },
      { Foreground = { Color = string.format('#%02x%02x%02x', 74, v, 255) } },
      { Text = ' ●' },
    }))
  else
    window:set_right_status(status_text)
  end
end)

wezterm.on('format-tab-title', function(tab, tabs, panes, cfg, hover, max_width)
  local pane_id = tab.active_pane.pane_id
  local is_waiting = waiting_panes[pane_id]
  local title = ' ' .. tab.active_pane.title .. ' '

  if is_waiting then
    local phase = (tick * 0.35) % (2 * math.pi)
    local v = math.floor(158 + 80 * math.sin(phase))
    return {
      { Background = { Color = string.format('#%02x%02x%02x', 74, v, 255) } },
      { Foreground = { Color = '#ffffff' } },
      { Text = title },
    }
  end
end)

-- ─── apply ───────────────────────────────────────────────────────────────

function M.apply(config)
  config.status_update_interval = 150

  local ps1 = wezterm.config_dir .. '\\clipboard_image.ps1'
  local keys = config.keys or {}

  -- Ctrl+T: new tab
  table.insert(keys, {
    key = 't',
    mods = 'CTRL',
    action = wezterm.action.SpawnTab 'CurrentPaneDomain',
  })

  -- Ctrl+W: close active pane (tab closes automatically when last pane is removed)
  table.insert(keys, {
    key = 'w',
    mods = 'CTRL',
    action = wezterm.action.CloseCurrentPane { confirm = false },
  })

  -- Ctrl+Tab / Ctrl+Shift+Tab: next/prev tab
  table.insert(keys, {
    key = 'Tab',
    mods = 'CTRL',
    action = wezterm.action.ActivateTabRelative(1),
  })
  table.insert(keys, {
    key = 'Tab',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.ActivateTabRelative(-1),
  })

  -- Ctrl+1~9: jump to tab by index
  for i = 1, 9 do
    table.insert(keys, {
      key = tostring(i),
      mods = 'CTRL',
      action = wezterm.action.ActivateTab(i - 1),
    })
  end

  -- Ctrl+D: split right, Ctrl+Shift+D: split down
  table.insert(keys, {
    key = 'd',
    mods = 'CTRL',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  })
  table.insert(keys, {
    key = 'd',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
  })

  -- Alt+arrows: move between panes
  table.insert(keys, { key = 'UpArrow',    mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Up' })
  table.insert(keys, { key = 'DownArrow',  mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Down' })
  table.insert(keys, { key = 'LeftArrow',  mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Left' })
  table.insert(keys, { key = 'RightArrow', mods = 'ALT', action = wezterm.action.ActivatePaneDirection 'Right' })

  -- Ctrl+Shift+N: show notification log in a new pane
  table.insert(keys, {
    key = 'n',
    mods = 'CTRL|SHIFT',
    action = wezterm.action_callback(function(window, pane)
      window:perform_action(
        wezterm.action.SpawnCommandInNewTab {
          args = {
            'pwsh.exe', '-NoProfile', '-Command',
            'if (Test-Path "' .. NOTIFY_LOG .. '") { Get-Content "' .. NOTIFY_LOG .. '" -Wait } else { Write-Host "No notifications yet."; Start-Sleep 60 }',
          },
        },
        pane
      )
    end),
  })

  table.insert(keys, {
    key = 'v',
    mods = 'CTRL',
    action = wezterm.action_callback(function(window, pane)
      local ok, stdout, stderr = wezterm.run_child_process({
        'powershell.exe', '-NoProfile', '-NonInteractive', '-STA', '-File', ps1,
      })
      local path = stdout and stdout:match('[^\r\n]+')
      if path and path ~= '' then
        pane:send_text(path)
      else
        window:perform_action(wezterm.action.PasteFrom 'Clipboard', pane)
      end
    end),
  })
  config.keys = keys

  return config
end

return M
