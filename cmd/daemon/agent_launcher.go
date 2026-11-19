package main

import (
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
)

// launchAgentRedirect resolves the protocol URI or CLI for an AI agent/IDE and launches it.
func launchAgentRedirect(agentID string, targetDir string) string {
	uri, cli := "", ""
	switch agentID {
	case "antigravity":
		uri, cli = "antigravity://open?workspace="+targetDir, "agy"
		rulesDir := filepath.Join(targetDir, ".agents", "rules")
		_ = os.MkdirAll(rulesDir, 0755)
		rulePath := filepath.Join(rulesDir, "otto.md")
		if _, err := os.Stat(rulePath); os.IsNotExist(err) {
			_ = os.WriteFile(rulePath, []byte("# Otto Bridge\nDaemon Address: http://localhost:3000\nEvents: POST /api/antigravity/events\n"), 0644)
		}
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
			if err := exec.Command("cmd", "/c", "start", "", uri).Run(); err != nil && cli != "" {
				_ = exec.Command("cmd", "/c", cli, targetDir).Run()
			}
		} else if runtime.GOOS == "darwin" {
			_ = exec.Command("open", uri).Run()
		} else {
			_ = exec.Command("xdg-open", uri).Run()
		}
	}()
	return uri
}
