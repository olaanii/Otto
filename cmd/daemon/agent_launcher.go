package main

import (
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
)

// hasShellMetacharacters checks for characters that could lead to command injection in shell commands.
func hasShellMetacharacters(s string) bool {
	return strings.ContainsAny(s, "&|;`\"'<>^%!\r\n$")
}

// launchAgentHandshake dispatches the IDE URI and opens the authorization confirmation page.
func launchAgentHandshake(agentID string, targetDir string, token string) string {
	cleanDir := filepath.Clean(targetDir)
	authUrl := "http://localhost:3000/agents/authorize?agentId=" + agentID + "&token=" + token + "&workspace=" + url.QueryEscape(cleanDir)

	go func() {
		if cleanDir != "" && cleanDir != "." && !hasShellMetacharacters(cleanDir) {
			if fi, err := os.Stat(cleanDir); err == nil && fi.IsDir() {
				if runtime.GOOS == "windows" {
					switch agentID {
					case "vscode":
						_ = exec.Command("cmd", "/c", "code", cleanDir).Start()
					case "cursor":
						_ = exec.Command("cmd", "/c", "cursor", cleanDir).Start()
					}
				}
			}
		}

		if runtime.GOOS == "windows" {
			_ = exec.Command("cmd", "/c", "start", "", authUrl).Start()
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
		cleanDir := filepath.Clean(targetDir)
		if !hasShellMetacharacters(cleanDir) {
			if fi, err := os.Stat(cleanDir); err == nil && fi.IsDir() {
				rulesDir := filepath.Join(cleanDir, ".agents", "rules")
				_ = os.MkdirAll(rulesDir, 0755)
				_ = os.WriteFile(filepath.Join(rulesDir, "otto.md"), []byte(ruleContent), 0644)
			}
		}
	}

	if home, err := os.UserHomeDir(); err == nil {
		globalRulesDir := filepath.Join(home, ".gemini", "config", "rules")
		_ = os.MkdirAll(globalRulesDir, 0755)
		_ = os.WriteFile(filepath.Join(globalRulesDir, "otto.md"), []byte(ruleContent), 0644)
	}
}
