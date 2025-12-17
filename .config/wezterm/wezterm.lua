-- Main WezTerm configuration file
-- Coordinates all modular components for Nushell-first terminal setup
local wezterm = require("wezterm")

local config = wezterm.config_builder()

-- Get the directory where this config file is located
local home = os.getenv("HOME")
local config_dir = home .. "/.config/wezterm"

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
	"keybindings",
}

for _, module_name in ipairs(modules) do
	local module = safe_require(module_name)
	if module and module.apply_to_config then
		module.apply_to_config(config)
	end
end

-- Default shell: Nushell (cross-platform)
-- Try nix-profile path first, then fall back to system nu
local nix_nu = home .. "/.nix-profile/bin/nu"
local f = io.open(nix_nu, "r")
if f then
	f:close()
	config.default_prog = { nix_nu }
else
	config.default_prog = { "nu" }
end

-- Hide tab bar when only one tab
config.hide_tab_bar_if_only_one_tab = true

-- Disable fancy tab bar (minimal UI)
config.use_fancy_tab_bar = false

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
