package main

import (
	"encoding/json"
	"net/http"
)

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
			s.broadcastEvent("agent_connected", map[string]any{"agentId": body.AgentID, "confirmed": true})
			_ = json.NewEncoder(w).Encode(map[string]any{"ok": true, "agentId": body.AgentID, "connected": true})
			return
		}
		w.WriteHeader(http.StatusBadRequest)
		_ = json.NewEncoder(w).Encode(map[string]any{"ok": false, "error": "Invalid or expired token"})
	})
}
