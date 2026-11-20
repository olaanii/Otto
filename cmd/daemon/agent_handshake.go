package main

import (
	"encoding/json"
	"net/http"
	"os/exec"
	"runtime"
	"strings"
)

// focusOttoDesktopWindow brings the Otto desktop app into active OS foreground focus.
func focusOttoDesktopWindow() {
	go func() {
		if runtime.GOOS == "windows" {
			_ = exec.Command("powershell", "-NoProfile", "-NonInteractive", "-Command", "$w=New-Object -ComObject WScript.Shell; $w.AppActivate('Otto'); $w.AppActivate('otto_frontend')").Run()
		} else if runtime.GOOS == "darwin" {
			_ = exec.Command("osascript", "-e", `tell application "Otto" to activate`).Run()
		}
	}()
}

// RegisterAgentHandshakeEndpoints registers /agents/authorize and confirmation routes.
func (s *DaemonServer) RegisterAgentHandshakeEndpoints(mux *http.ServeMux) {
	mux.HandleFunc("/agents/authorize", func(w http.ResponseWriter, r *http.Request) {
		agentID := r.URL.Query().Get("agentId")
		token := r.URL.Query().Get("token")
		workspace := r.URL.Query().Get("workspace")
		agentName := "Google Antigravity"
		if agentID == "cursor" {
			agentName = "Cursor"
		} else if agentID == "vscode" {
			agentName = "VS Code"
		}
		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		_, _ = w.Write([]byte(renderAgentAuthPage(agentID, agentName, workspace, token)))
	})

	mux.HandleFunc("/api/agents/confirm", func(w http.ResponseWriter, r *http.Request) {
		if s.enableCORS(w, r) {
			return
		}
		w.Header().Set("Content-Type", "application/json")
		var body struct {
			AgentID string `json:"agentId"`
			Token   string `json:"token"`
		}
		_ = json.NewDecoder(r.Body).Decode(&body)
		s.mu.Lock()
		confirmed := false
		targetDir := ""
		for i := range s.state.IdeProfiles {
			if s.state.IdeProfiles[i].ID == body.AgentID {
				if body.Token == "" || s.state.IdeProfiles[i].HandshakeToken == body.Token {
					s.state.IdeProfiles[i].Connected = true
					s.state.IdeProfiles[i].Status = "watching_realtime"
					s.state.IdeProfiles[i].HandshakeToken = ""
					targetDir = s.state.IdeProfiles[i].PendingWorkspace
					confirmed = true
				}
			}
		}
		s.saveStateLocked()
		s.mu.Unlock()

		if confirmed {
			provisionOttoBridge(targetDir)
			focusOttoDesktopWindow()
			discovered := s.DiscoverAgentProjects(body.AgentID)
			s.mu.Lock()
			for _, dp := range discovered {
				found := false
				for _, rw := range s.state.RecentWorkspaces {
					if strings.EqualFold(rw, dp.Path) {
						found = true
						break
					}
				}
				if !found && len(s.state.RecentWorkspaces) < 15 {
					s.state.RecentWorkspaces = append(s.state.RecentWorkspaces, dp.Path)
				}
			}
			s.saveStateLocked()
			s.mu.Unlock()

			s.broadcastEvent("agent_connected", map[string]any{"agentId": body.AgentID, "confirmed": true, "discoveredProjects": discovered})
			_ = json.NewEncoder(w).Encode(map[string]any{"ok": true, "agentId": body.AgentID, "connected": true, "discoveredProjects": discovered})
			return
		}
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(map[string]any{"ok": false, "error": "Invalid or expired token"})
	})
}
