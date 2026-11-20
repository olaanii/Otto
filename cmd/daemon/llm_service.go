package main

import (
	"context"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

type CliToolInfo struct {
	ID           string `json:"id"`
	Name         string `json:"name"`
	Installed    bool   `json:"installed"`
	BinaryPath   string `json:"binaryPath"`
	Version      string `json:"version"`
	Subscription string `json:"subscription"`
}

// DetectLocalClis identifies installed coding agent CLIs for $0 subscription usage.
func DetectLocalClis() []CliToolInfo {
	tools := []struct {
		id, name, sub string
		fallbacks     []string
	}{
		{"antigravity", "Google Antigravity", "Google AI Pro Plan ($0 token fees)", []string{
			`C:\Users\olani\AppData\Local\agy\bin\agy.exe`,
			`C:\Users\olani\.gemini\bin\agy.exe`,
		}},
		{"claude", "Claude Code", "Claude Pro / Team Subscription", []string{
			`C:\Users\olani\.local\bin\claude.exe`,
		}},
		{"codex", "OpenAI Codex CLI", "OpenAI Subscription", nil},
	}

	var results []CliToolInfo
	for _, t := range tools {
		binPath, err := exec.LookPath(t.id)
		if err != nil {
			for _, fb := range t.fallbacks {
				if _, statErr := exec.LookPath(fb); statErr == nil || filepath.IsAbs(fb) {
					binPath = fb
					err = nil
					break
				}
			}
		}

		info := CliToolInfo{
			ID:           t.id,
			Name:         t.name,
			Installed:    err == nil && binPath != "",
			BinaryPath:   binPath,
			Subscription: t.sub,
		}
		if info.Installed {
			info.Version = "active"
		}
		results = append(results, info)
	}
	return results
}

// TestCliConnection executes a lightweight version or readiness check for a local CLI.
func TestCliConnection(ctx context.Context, cliID string) (bool, string) {
	clis := DetectLocalClis()
	for _, c := range clis {
		if c.ID == cliID && c.Installed {
			start := time.Now()
			out, err := exec.CommandContext(ctx, "cmd", "/c", c.ID, "--version").Output()
			lat := time.Since(start).Milliseconds()
			ver := strings.TrimSpace(string(out))
			if err == nil && ver != "" {
				return true, strings.Split(ver, "\n")[0]
			}
			return true, c.Name + " ready (" + c.Subscription + ")" + " [" + time.Duration(lat).String() + "]"
		}
	}
	return false, "CLI tool not found on system PATH"
}
