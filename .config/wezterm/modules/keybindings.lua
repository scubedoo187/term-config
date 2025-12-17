-- keybindings.lua - Key mappings and shortcuts for WezTerm
-- Retained from original wezterm-config for consistency
local wezterm = require("wezterm")

local module = {}

function module.apply_to_config(config)
	local act = wezterm.action

	-- Leader key configuration
	config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }

	config.keys = {
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

		-- Launchers
		{ key = "l", mods = "ALT", action = act.ShowLauncher },
		{ key = "s", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
		{ key = "t", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|TABS" }) },

		-- Multiplexer domain management
		{
			key = "d",
			mods = "LEADER",
			action = act.AttachDomain("local"),
		},
		{
			key = "D",
			mods = "LEADER|SHIFT",
			action = act.DetachDomain("CurrentPaneDomain"),
		},
		{
			key = "m",
			mods = "LEADER",
			action = act.ShowLauncherArgs({ flags = "FUZZY|DOMAINS", title = "Select Domain" }),
		},

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

		-- Tab renaming
		{
			key = ",",
			mods = "LEADER",
			action = act.PromptInputLine({
				description = "Enter new name for tab",
				action = wezterm.action_callback(function(window, _, line)
					if line then
						window:active_tab():set_title(line)
					end
				end),
			}),
		},

		-- Workspace renaming
		{
			key = ".",
			mods = "LEADER",
			action = act.PromptInputLine({
				description = "Enter new name for workspace",
				action = wezterm.action_callback(function(window, _, line)
					if line then
						local current_workspace = window:active_workspace()
						local home = wezterm.home_dir
						-- Use mux-server socket for workspace rename
						-- This ensures workspace rename works through multiplexer
						local socket_path = home .. "/.local/share/wezterm/sock"

						-- Use full path that works on both Intel and Apple Silicon Macs
						-- Falls back to 'wezterm' in PATH if neither common location exists
						local cmd = string.format(
							'export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"; WEZTERM_UNIX_SOCKET="%s" wezterm cli rename-workspace --workspace "%s" "%s" 2>&1',
							socket_path,
							current_workspace,
							line
						)
						local handle = io.popen(cmd)
						if handle then
							local result = handle:read("*a")
							handle:close()
							if result and result ~= "" then
								wezterm.log_info("Rename result: " .. tostring(result))
							end
						end
					end
				end),
			}),
		},
	}
end

return module
