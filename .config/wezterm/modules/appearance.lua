-- appearance.lua - Visual configuration for WezTerm
-- Retained from original wezterm-config for consistency
local wezterm = require("wezterm")

local module = {}

function module.apply_to_config(config)
	-- Color scheme and visual appearance
	config.color_scheme = "Seoul256 (Gogh)"

	config.colors = {
		selection_fg = "none",
		selection_bg = "rgba(50% 50% 50% 50%)",
	}

	-- Font configuration
	config.font_size = 14
	config.font = wezterm.font("JetBrainsMono Nerd Font Mono", { weight = "Bold" })

	-- Window appearance
	config.window_background_opacity = 0.95
	config.window_decorations = "RESIZE"

	-- IME and cursor
	config.use_ime = true
	config.default_cursor_style = "BlinkingBlock"

	-- Inactive pane dimming
	config.inactive_pane_hsb = {
		saturation = 0.7,
		brightness = 0.4,
	}

	-- Status line: show active workspace on right
	wezterm.on("update-right-status", function(window)
		window:set_right_status(window:active_workspace())
	end)
end

return module
