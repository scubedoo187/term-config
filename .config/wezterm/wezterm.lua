-- Main WezTerm configuration file
-- Coordinates all modular components for Fish shell terminal setup
local wezterm = require("wezterm")

local config = wezterm.config_builder()
local act = wezterm.action

-- Get the directory where this config file is located
local home = os.getenv("HOME")
local config_dir = home .. "/.config/wezterm"
local xdg_data_home = os.getenv("XDG_DATA_HOME") or (home .. "/.local/share")
local wezterm_data_dir = xdg_data_home .. "/wezterm"

-- Add modules directory to Lua path (handle dotfiles repo symlink case)
-- First try the standard location, then fall back to the dotfiles structure
local modules_path = config_dir .. "/modules/?.lua"
package.path = package.path .. ";" .. modules_path

-- Function to safely load modules
local function safe_require(module_name)
	local ok, module = pcall(require, module_name)
	if ok and module then
		return module
	else
		wezterm.log_error("Failed to load module: " .. module_name .. " - " .. tostring(module))
		return nil
	end
end

-- Load and apply modular configurations
local modules = {
	"appearance",
	"mux-domain",
	"resurrect",
	"workspace-history",
	"keybindings",
}

for _, module_name in ipairs(modules) do
	local module = safe_require(module_name)
	if module and module.apply_to_config then
		module.apply_to_config(config)
	end
end

-- Default shell: Fish (cross-platform)
local fish_paths = {
	home .. "/.nix-profile/bin/fish",
	"/opt/homebrew/bin/fish",
	"/usr/local/bin/fish",
	"/usr/bin/fish",
}
for _, fish_path in ipairs(fish_paths) do
	local f = io.open(fish_path, "r")
	if f then
		f:close()
		config.default_prog = { fish_path }
		break
	end
end

-- Hide tab bar when only one tab
config.hide_tab_bar_if_only_one_tab = true

-- Disable fancy tab bar (minimal UI)
config.use_fancy_tab_bar = false

-- Make mux daemon state/log locations explicit so they are easier to inspect
-- and keep aligned with the launchd/systemd helpers in scripts/.
config.daemon_options = {
	pid_file = wezterm_data_dir .. "/pid",
	stdout = wezterm_data_dir .. "/mux-server.log",
	stderr = wezterm_data_dir .. "/mux-server-error.log",
}

config.hyperlink_rules = wezterm.default_hyperlink_rules()
table.insert(config.hyperlink_rules, {
	regex = [[((/Users|/private|/tmp)/[^\s<>"'`|:]+):([0-9]+)]],
	format = "file://$1#$3",
})
table.insert(config.hyperlink_rules, {
	regex = [[((/Users|/private|/tmp)/[^\s<>"'`|]+)]],
	format = "file://$1",
})

wezterm.on("open-uri", function(window, pane, uri)
	if uri:find("^file://") == 1 then
		local target = uri:gsub("^file://", "")
		local path, line = target:match("^(.-)#([0-9]+)$")
		if not path then
			path = target
		end

		local open_cmd
		if line then
			open_cmd = string.format(
				'open -a MacVim --args +%s %q 2>/dev/null || open %q',
				line,
				path,
				path
			)
		else
			open_cmd = string.format('open -a MacVim %q 2>/dev/null || open %q', path, path)
		end

		window:perform_action(
			act.SpawnCommandInNewWindow({
				args = {
					"sh",
					"-lc",
					open_cmd,
				},
			}),
			pane
		)
		return false
	end
end)

-- In tmux, use Cmd+Click rather than Shift+Click to bypass mouse reporting
-- and open hyperlinks under the cursor.
config.bypass_mouse_reporting_modifiers = "CMD"
config.mouse_bindings = {
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "CMD",
		action = act.OpenLinkAtMouseCursor,
	},
	{
		event = { Down = { streak = 1, button = "Left" } },
		mods = "CMD",
		action = act.Nop,
	},
}

-- Exit behavior: close window on last tab close
config.exit_behavior = "Close"

-- Tab appearance (minimal)
config.tab_bar_at_bottom = false
config.status_update_interval = 1000

-- Scrollback lines
config.scrollback_lines = 3500

-- Window management
config.initial_cols = 240
config.initial_rows = 50

return config
