local wezterm = require 'wezterm'
local M = {}

-- ─── AI waiting indicator ─────────────────────────────────────────────────

local waiting_panes = {}
local tick = 0

wezterm.on('update-status', function(window, pane)
  tick = tick + 1
  local text = pane:get_lines_as_text(5)
  waiting_panes[pane:pane_id()] = text:match('%? for shortcuts') ~= nil
  window:set_right_status('')
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
