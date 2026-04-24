-- keybindings.lua - Key mappings and shortcuts for WezTerm
local wezterm = require("wezterm")

local module = {}

function module.apply_to_config(config)
	local act = wezterm.action

	-- Leader key configuration
	config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }

	-- Preserve any existing keys (e.g., from resurrect module)
	local existing_keys = config.keys or {}

	local keys = {
		-- Copy mode
		{ key = "[", mods = "LEADER", action = act.ActivateCopyMode },

		-- Pane navigation
		{
			key = "h",
			mods = "LEADER",
			action = act.ActivatePaneDirection("Left"),
		},
		{
			key = "l",
			mods = "LEADER",
			action = act.ActivatePaneDirection("Right"),
		},
		{
			key = "k",
			mods = "LEADER",
			action = act.ActivatePaneDirection("Up"),
		},
		{
			key = "j",
			mods = "LEADER",
			action = act.ActivatePaneDirection("Down"),
		},

		-- Pane resizing with CTRL+CMD+HJKL
		{
			key = "h",
			mods = "CTRL|CMD",
			action = act.AdjustPaneSize({ "Left", 5 }),
		},
		{
			key = "l",
			mods = "CTRL|CMD",
			action = act.AdjustPaneSize({ "Right", 5 }),
		},
		{
			key = "j",
			mods = "CTRL|CMD",
			action = act.AdjustPaneSize({ "Down", 5 }),
		},
		{
			key = "k",
			mods = "CTRL|CMD",
			action = act.AdjustPaneSize({ "Up", 5 }),
		},

		-- Pane splitting
		{
			key = "\\",
			mods = "LEADER",
			action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
		},
		{
			key = "-",
			mods = "LEADER",
			action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
		},

		-- Tab management
		{
			key = "c",
			mods = "LEADER",
			action = act.SpawnTab("CurrentPaneDomain"),
		},
		{
			key = "p",
			mods = "LEADER",
			action = act.ActivateTabRelative(-1),
		},
		{
			key = "n",
			mods = "LEADER",
			action = act.ActivateTabRelative(1),
		},

		-- Send leader key through
		{
			key = "a",
			mods = "LEADER|CTRL",
			action = act.SendKey({ key = "a", mods = "CTRL" }),
		},

		{ key = "Copy", mods = "NONE", action = act.CopyTo("Clipboard") },
		{ key = "Paste", mods = "NONE", action = act.PasteFrom("Clipboard") },
		{ key = "c", mods = "CMD|SHIFT", action = act.CopyTo("Clipboard") },
		{ key = "v", mods = "CMD|SHIFT", action = act.PasteFrom("Clipboard") },
		{ key = "l", mods = "ALT", action = act.ShowLauncher },
		{ key = "t", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|TABS" }) },

		-- Workspace management
		{
			key = "w",
			mods = "LEADER",
			action = act.PromptInputLine({
				description = wezterm.format({
					{ Attribute = { Intensity = "Bold" } },
					{ Foreground = { AnsiColor = "Fuchsia" } },
					{ Text = "Enter name for new workspace" },
				}),
				action = wezterm.action_callback(function(window, pane, line)
					if line then
						window:perform_action(
							act.SwitchToWorkspace({
								name = line,
							}),
							pane
						)
					end
				end),
			}),
		},
		{
			key = "a",
			mods = "LEADER",
			action = act.EmitEvent("workspace-prev"),
		},
		{
			key = "s",
			mods = "LEADER",
			action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }),
		},

		-- Window management
		{
			key = "w",
			mods = "CMD",
			action = act.CloseCurrentPane({ confirm = true }),
		},
		{
			key = "z",
			mods = "LEADER",
			action = act.TogglePaneZoomState,
		},
	}

	for _, key in ipairs(existing_keys) do
		table.insert(keys, key)
	end
	config.keys = keys
end

return module
