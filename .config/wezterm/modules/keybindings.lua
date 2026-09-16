-- keybindings.lua - Minimal GUI key mappings for WezTerm
local wezterm = require("wezterm")

local module = {}

function module.apply_to_config(config)
	local act = wezterm.action

	-- WezTerm intentionally does not define a Ctrl+a leader anymore.
	-- tmux owns prefix/key handling so WezTerm remains a lightweight renderer.
	config.keys = {
		{ key = "Copy", mods = "NONE", action = act.CopyTo("Clipboard") },
		{ key = "Paste", mods = "NONE", action = act.PasteFrom("Clipboard") },
		{ key = "c", mods = "CMD|SHIFT", action = act.CopyTo("Clipboard") },
		{ key = "v", mods = "CMD|SHIFT", action = act.PasteFrom("Clipboard") },
		{ key = "l", mods = "ALT", action = act.ShowLauncher },
	}
end

return module
