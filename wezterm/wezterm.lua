local wezterm = require 'wezterm'
local config = wezterm.config_builder()
local act = wezterm.action

-- ─── 基本設定 ─────────────────────────────────────────────────────────────

config.default_prog = { 'pwsh.exe' }
config.window_decorations = 'RESIZE'
config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = false
config.status_update_interval = 150

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

-- ─── 画像ペースト ────────────────────────────────────────────────────────

local ps1 = wezterm.config_dir .. '\\clipboard_image.ps1'

config.keys = {
  {
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
        window:perform_action(act.PasteFrom 'Clipboard', pane)
      end
    end),
  },
}

return config
