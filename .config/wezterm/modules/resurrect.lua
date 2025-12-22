-- resurrect.lua - Session persistence with smart_workspace_switcher integration
-- Pinned versions: resurrect v1.0.0, smart_workspace_switcher 1.2.0
local wezterm = require("wezterm")

local module = {}

local RESURRECT_URL = "https://github.com/MLFlexer/resurrect.wezterm?tag=v1.0.0"
local WORKSPACE_SWITCHER_URL = "https://github.com/MLFlexer/smart_workspace_switcher.wezterm?tag=1.2.0"

function module.apply_to_config(config)
	local resurrect_ok, resurrect = pcall(function()
		return wezterm.plugin.require(RESURRECT_URL)
	end)

	if not resurrect_ok then
		wezterm.log_error("Failed to load resurrect.wezterm: " .. tostring(resurrect))
		return
	end

	local workspace_switcher_ok, workspace_switcher = pcall(function()
		return wezterm.plugin.require(WORKSPACE_SWITCHER_URL)
	end)

	if not workspace_switcher_ok then
		wezterm.log_error("Failed to load smart_workspace_switcher: " .. tostring(workspace_switcher))
	end

	resurrect.state_manager.periodic_save({
		interval_seconds = 900,
		save_workspaces = true,
		save_windows = true,
		save_tabs = false,
	})

	config.keys = config.keys or {}

	if workspace_switcher_ok then
		wezterm.on("smart_workspace_switcher.workspace_switcher.selected", function(window, path, label)
			resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
		end)

		wezterm.on("smart_workspace_switcher.workspace_switcher.created", function(window, path, label)
			local state = resurrect.state_manager.load_state(label, "workspace")
			if state then
				resurrect.workspace_state.restore_workspace(state, {
					window = window,
					relative = true,
					restore_text = true,
					on_pane_restore = resurrect.tab_state.default_on_pane_restore,
				})
			end
		end)

		table.insert(config.keys, {
			key = "s",
			mods = "LEADER",
			action = workspace_switcher.switch_workspace(),
		})

		table.insert(config.keys, {
			key = "a",
			mods = "LEADER",
			action = workspace_switcher.switch_to_prev_workspace(),
		})
	end

	table.insert(config.keys, {
		key = "s",
		mods = "LEADER|CTRL",
		action = wezterm.action_callback(function(win, pane)
			resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
			win:toast_notification("Resurrect", "Workspace state saved", nil, 2000)
		end),
	})

	table.insert(config.keys, {
		key = "r",
		mods = "LEADER",
		action = wezterm.action_callback(function(win, pane)
			resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id, label)
				local type = string.match(id, "^([^/]+)") -- extract type before '/'
				id = string.match(id, "([^/]+)$") -- extract filename after '/'
				id = string.match(id, "(.+)%..+$") -- remove file extension

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

	table.insert(config.keys, {
		key = "x",
		mods = "LEADER",
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
