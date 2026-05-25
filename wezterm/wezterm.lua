local wezterm = require 'wezterm'
local config = wezterm.config_builder()

require('picosh').apply(config)

return config
