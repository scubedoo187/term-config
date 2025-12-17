-- resurrect.lua - Session persistence using resurrect.wezterm plugin
-- Inspired by tmux-resurrect and tmux-continuum
-- Automatically saves and restores terminal state at configurable intervals
local wezterm = require("wezterm")

local module = {}

function module.apply_to_config(config)
	-- Load resurrect plugin from GitHub
	-- This will be automatically downloaded to ~/.local/share/wezterm/plugins/
	local resurrect_ok, resurrect = pcall(function()
		return wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")
	end)

	if not resurrect_ok then
		wezterm.log_error("Failed to load resurrect.wezterm plugin: " .. tostring(resurrect))
		return
	end

	-- Configure state save directory (optional, default is ~/.local/share/wezterm/resurrect/)
	-- resurrect.state_manager.change_state_save_dir(os.getenv("HOME") .. "/.local/share/wezterm/resurrect")

	-- Setup periodic saving of workspace state every 15 minutes
	-- This ensures that if WezTerm crashes or is closed, we can restore recent state
	resurrect.state_manager.periodic_save({
		interval_seconds = 900, -- 15 minutes
		save_workspaces = true,
		save_windows = true,
		save_tabs = false, -- tabs are saved with windows
	})

	-- Restore the most recent workspace state on GUI startup
	-- This allows session recovery after system reboot or WezTerm crash
	wezterm.on("gui-startup", function()
		resurrect.state_manager.resurrect_on_gui_startup()
	end)

	-- === Keybindings for manual session management ===

	-- Save current workspace state manually
	table.insert(config.keys, {
		key = "S",
		mods = "LEADER",
		action = wezterm.action_callback(function(win, pane)
			resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
			win:toast_notification("Resurrect", "Workspace state saved", nil, 2000)
		end),
	})

	-- Load workspace/window/tab state via fuzzy finder
	table.insert(config.keys, {
		key = "R",
		mods = "LEADER",
		action = wezterm.action_callback(function(win)
			resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id, label)
				local type = string.match(id, "^([^/]+)") -- extract type before '/'
				id = string.match(id, "([^/]+)$") -- extract filename after '/'
				id = string.match(id, "(.+)%.%..+$") -- remove file extension

				local opts = {
					relative = true,
					restore_text = true,
					on_pane_restore = resurrect.tab_state.default_on_pane_restore,
				}

				if type == "workspace" then
					local state = resurrect.state_manager.load_state(id, "workspace")
					resurrect.workspace_state.restore_workspace(state, opts)
				elseif type == "window" then
					local state = resurrect.state_manager.load_state(id, "window")
					resurrect.window_state.restore_window(pane:window(), state, opts)
				elseif type == "tab" then
					local state = resurrect.state_manager.load_state(id, "tab")
					resurrect.tab_state.restore_tab(pane:tab(), state, opts)
				end

				win:toast_notification("Resurrect", "State restored: " .. label, nil, 2000)
			end)
		end),
	})

	-- Delete a saved state via fuzzy finder
	table.insert(config.keys, {
		key = "d",
		mods = "ALT",
		action = wezterm.action_callback(function(win, pane)
			resurrect.fuzzy_loader.fuzzy_load(
				win,
				pane,
				function(id)
					resurrect.state_manager.delete_state(id)
					win:toast_notification("Resurrect", "State deleted", nil, 2000)
				end,
				{
					title = "Delete State",
					description = "Select state to delete",
					fuzzy_description = "Search for state to delete: ",
					is_fuzzy = true,
				}
			)
		end),
	})

	wezterm.log_info("✓ Resurrect.wezterm loaded successfully")
end

return module
