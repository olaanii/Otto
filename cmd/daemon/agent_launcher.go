package main

import (
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
)

// launchAgentHandshake dispatches the IDE URI and opens the authorization confirmation page.
func launchAgentHandshake(agentID string, targetDir string, token string) string {
	authUrl := "http://localhost:3000/agents/authorize?agentId=" + agentID + "&token=" + token + "&workspace=" + url.QueryEscape(targetDir)

	go func() {
		if runtime.GOOS == "windows" {
			_ = exec.Command("cmd", "/c", "start", "", authUrl).Start()
			switch agentID {
			case "vscode":
				_ = exec.Command("cmd", "/c", "code", targetDir).Start()
			case "cursor":
				_ = exec.Command("cmd", "/c", "cursor", targetDir).Start()
			}
		} else if runtime.GOOS == "darwin" {
			_ = exec.Command("open", authUrl).Start()
		} else {
			_ = exec.Command("xdg-open", authUrl).Start()
		}
	}()
	return authUrl
}

// provisionOttoBridge ensures the authentic agent rules exist in the workspace and global config.
func provisionOttoBridge(targetDir string) {
	ruleContent := "# Otto Atomic Git & Workflow Rules for Antigravity\n\n" +
		"Daemon Address: http://localhost:3000\n" +
		"Events: POST /api/antigravity/events\n" +
		"LOC Limit: <= 80 LOC per commit unit\n" +
		"Plans: isolate in docs(plans) before implementation\n"

	if targetDir != "" {
		rulesDir := filepath.Join(targetDir, ".agents", "rules")
		_ = os.MkdirAll(rulesDir, 0755)
		_ = os.WriteFile(filepath.Join(rulesDir, "otto.md"), []byte(ruleContent), 0644)
	}

	if home, err := os.UserHomeDir(); err == nil {
		globalRulesDir := filepath.Join(home, ".gemini", "config", "rules")
		_ = os.MkdirAll(globalRulesDir, 0755)
		_ = os.WriteFile(filepath.Join(globalRulesDir, "otto.md"), []byte(ruleContent), 0644)
	}
}
