import { execFileSync } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { setCapabilities } from "@earendil-works/pi-tui";

function tmuxClientSupportsHyperlinks(): boolean {
	if (!process.env.TMUX) return false;

	try {
		const output = execFileSync("tmux", ["display-message", "-p", "#{client_termname} #{client_termfeatures}"], {
			encoding: "utf8",
			timeout: 1000,
			stdio: ["ignore", "pipe", "ignore"],
		}).toLowerCase();

		return output.includes("hyperlinks") || output.includes("ghostty") || output.includes("wezterm");
	} catch {
		return false;
	}
}

export default function terminalHyperlinks(_pi: ExtensionAPI) {
	const term = (process.env.TERM || "").toLowerCase();
	const inTmuxOrScreen = Boolean(process.env.TMUX) || term.startsWith("tmux") || term.startsWith("screen");
	if (!inTmuxOrScreen) return;

	const termProgram = (process.env.TERM_PROGRAM || "").toLowerCase();
	const supportsHyperlinks =
		termProgram === "ghostty" ||
		termProgram === "wezterm" ||
		Boolean(process.env.GHOSTTY_RESOURCES_DIR) ||
		Boolean(process.env.WEZTERM_PANE) ||
		Boolean(process.env.ITERM_SESSION_ID) ||
		tmuxClientSupportsHyperlinks();

	if (!supportsHyperlinks) return;

	const colorTerm = (process.env.COLORTERM || "").toLowerCase();
	setCapabilities({
		images: null,
		trueColor: colorTerm === "truecolor" || colorTerm === "24bit",
		hyperlinks: true,
	});
}
