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
	uri, cli := "", ""
	switch agentID {
	case "antigravity":
		uri, cli = "antigravity://open?workspace="+targetDir, "agy"
	case "cursor":
		uri, cli = "cursor://file/"+filepath.ToSlash(targetDir), "cursor"
	case "vscode":
		uri, cli = "vscode://file/"+filepath.ToSlash(targetDir), "code"
	case "windsurf":
		uri, cli = "windsurf://file/"+filepath.ToSlash(targetDir), "windsurf"
	default:
		uri, cli = "antigravity://open?workspace="+targetDir, "agy"
	}

	go func() {
		if runtime.GOOS == "windows" {
			_ = exec.Command("cmd", "/c", "start", "", uri).Run()
			if cli != "" {
				_ = exec.Command("cmd", "/c", cli, targetDir).Run()
			}
			_ = exec.Command("cmd", "/c", "start", "", authUrl).Run()
		} else if runtime.GOOS == "darwin" {
			_ = exec.Command("open", authUrl).Run()
		} else {
			_ = exec.Command("xdg-open", authUrl).Run()
		}
	}()
	return authUrl
}

// provisionOttoBridge ensures the agent rules file exists in the active workspace.
func provisionOttoBridge(targetDir string) {
	if targetDir == "" {
		return
	}
	rulesDir := filepath.Join(targetDir, ".agents", "rules")
	_ = os.MkdirAll(rulesDir, 0755)
	rulePath := filepath.Join(rulesDir, "otto.md")
	if _, err := os.Stat(rulePath); os.IsNotExist(err) {
		_ = os.WriteFile(rulePath, []byte("# Otto Bridge\nDaemon Address: http://localhost:3000\nEvents: POST /api/antigravity/events\n"), 0644)
	}
}
