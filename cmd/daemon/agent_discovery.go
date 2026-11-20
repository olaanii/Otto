package main

import (
	"os"
	"path/filepath"
	"strings"
)

type DiscoveredProject struct {
	AgentID     string `json:"agentId"`
	AgentName   string `json:"agentName"`
	Name        string `json:"name"`
	Path        string `json:"path"`
	IsGitRepo   bool   `json:"isGitRepo"`
	LastUpdated string `json:"lastUpdated,omitempty"`
}

// DiscoverAgentProjects scans the local system for projects started in connected agents.
func (s *DaemonServer) DiscoverAgentProjects(agentID string) []DiscoveredProject {
	var results []DiscoveredProject
	seen := make(map[string]bool)

	addProject := func(id, name, path string) {
		clean := filepath.Clean(path)
		lower := strings.ToLower(clean)
		if seen[lower] {
			return
		}
		fi, err := os.Stat(clean)
		if err != nil || !fi.IsDir() {
			return
		}
		seen[lower] = true
		isGit := false
		if _, gErr := os.Stat(filepath.Join(clean, ".git")); gErr == nil {
			isGit = true
		}
		results = append(results, DiscoveredProject{
			AgentID:   id,
			AgentName: name,
			Name:      filepath.Base(clean),
			Path:      clean,
			IsGitRepo: isGit,
		})
	}

	homeDir, _ := os.UserHomeDir()
	appData := os.Getenv("APPDATA")

	// 1. Claude Projects
	if agentID == "" || agentID == "claude" {
		claudeDir := filepath.Join(homeDir, ".claude", "projects")
		if entries, err := os.ReadDir(claudeDir); err == nil {
			for _, e := range entries {
				if e.IsDir() {
					if decoded, ok := DecodeClaudeProjectPath(e.Name()); ok {
						addProject("claude", "Claude Code", decoded)
					}
				}
			}
		}
	}

	// 2. Antigravity Worktrees
	if agentID == "" || agentID == "antigravity" {
		agDir := filepath.Join(homeDir, ".gemini", "antigravity", "worktrees")
		if entries, err := os.ReadDir(agDir); err == nil {
			for _, e := range entries {
				if e.IsDir() {
					subDir := filepath.Join(agDir, e.Name())
					if subEntries, sErr := os.ReadDir(subDir); sErr == nil {
						for _, se := range subEntries {
							if se.IsDir() {
								addProject("antigravity", "Google Antigravity", filepath.Join(subDir, se.Name()))
							}
						}
					}
				}
			}
		}
		s.mu.RLock()
		if s.antigravity.WorktreePath != "" {
			addProject("antigravity", "Google Antigravity", s.antigravity.WorktreePath)
		}
		s.mu.RUnlock()
	}

	// 3. VS Code / Cursor / Codex
	if agentID == "" || agentID == "codex" || agentID == "vscode" || agentID == "cursor" {
		cursorDb := filepath.Join(appData, "Cursor", "User", "globalStorage", "state.vscdb")
		for _, p := range ExtractPathsFromVscDb(cursorDb) {
			addProject("cursor", "Cursor IDE", p)
		}
		codeDb := filepath.Join(appData, "Code", "User", "globalStorage", "state.vscdb")
		for _, p := range ExtractPathsFromVscDb(codeDb) {
			addProject("vscode", "VS Code Copilot", p)
		}
	}

	return results
}
