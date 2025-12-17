-- mux-domain.lua - Multiplexer domain configuration
-- Enables WezTerm to use a persistent mux-server for session continuity
-- Sessions persist even when GUI closes, allowing reconnection to existing workspace
local wezterm = require("wezterm")

local module = {}

function module.apply_to_config(config)
	-- Configure unix domain for local multiplexer
	-- Default socket path is ~/.local/share/wezterm/sock (created by mux-server)
	config.unix_domains = config.unix_domains or {}
	table.insert(config.unix_domains, {
		name = "local",
		-- socket_path is optional - defaults to ~/.local/share/wezterm/sock
		-- skip_permissions_check = false,
	})

	-- Automatically connect GUI to multiplexer on startup
	-- This ensures that new windows/tabs use the multiplexer domain
	-- allowing sessions to persist across GUI restarts
	config.default_gui_startup_args = { "connect", "local" }

	-- Event handler for GUI startup
	-- Attempts to spawn window in mux domain if available
	wezterm.on("gui-startup", function()
		local mux = wezterm.mux
		local _, _, window = mux.spawn_window({
			domain = { DomainName = "local" },
		})
		if window then
			wezterm.log_info("Connected to local multiplexer domain")
		end
	end)
end

return module
