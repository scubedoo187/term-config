local wezterm = require("wezterm")

local module = {}

local workspace_history = {
	last = nil,
	current = nil,
}

local function update_workspace(window)
	if not window then
		return
	end

	local ok, name = pcall(function()
		return window:active_workspace()
	end)

	if not ok or not name or name == "" then
		return
	end

	if workspace_history.current == nil then
		workspace_history.current = name
		return
	end

	if workspace_history.current ~= name then
		workspace_history.last = workspace_history.current
		workspace_history.current = name
	end
end

function module.apply_to_config(_config)
	wezterm.on("update-status", function(window, _pane)
		update_workspace(window)
	end)

	wezterm.on("workspace-prev", function(window, pane)
		update_workspace(window)

		local target = workspace_history.last
		if not target or target == "" then
			window:toast_notification("Workspace", "No previous workspace recorded", nil, 2000)
			return
		end

		if target == workspace_history.current then
			window:toast_notification("Workspace", "Already on previous workspace", nil, 2000)
			return
		end

		window:perform_action(
			wezterm.action.SwitchToWorkspace({
				name = target,
			}),
			pane
		)
	end)
end

return module
