package main

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestIntegrationsWorkspaceEndpoints(t *testing.T) {
	_, mux := setupTestServer(t)

	// 1. POST /api/workspace/open with non-existent path
	req := httptest.NewRequest(http.MethodPost, "/api/workspace/open", bytes.NewReader([]byte(`{"path": "invalid_non_git_path_12345"}`)))
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	var resp map[string]any
	_ = json.Unmarshal(rec.Body.Bytes(), &resp)
	if resp["ok"] == true {
		t.Errorf("Expected ok: false for non-existent directory, got %v", resp)
	}

	// 2. POST /api/workspace/open with real non-git folder (auto-init) with Windows quotes
	tmpDir := t.TempDir()
	initPayload, _ := json.Marshal(map[string]any{
		"path":     "\"" + tmpDir + "\"",
		"autoInit": true,
	})
	reqInit := httptest.NewRequest(http.MethodPost, "/api/workspace/open", bytes.NewReader(initPayload))
	recInit := httptest.NewRecorder()
	mux.ServeHTTP(recInit, reqInit)
	var respInit map[string]any
	_ = json.Unmarshal(recInit.Body.Bytes(), &respInit)
	if respInit["ok"] != true || respInit["isNewRepo"] != true {
		t.Errorf("Expected ok: true and isNewRepo: true for auto-initialized directory, got %v", respInit)
	}

	// 2. GET /api/workspace/recent
	reqRecent := httptest.NewRequest(http.MethodGet, "/api/workspace/recent", nil)
	recRecent := httptest.NewRecorder()
	mux.ServeHTTP(recRecent, reqRecent)
	if recRecent.Code != http.StatusOK {
		t.Errorf("Expected 200 OK for /api/workspace/recent, got %d", recRecent.Code)
	}
}

func TestIntegrationsGitHubEndpoints(t *testing.T) {
	_, mux := setupTestServer(t)

	// 1. POST /api/github/connect with empty token
	reqConnect := httptest.NewRequest(http.MethodPost, "/api/github/connect", bytes.NewReader([]byte(`{"token": ""}`)))
	recConnect := httptest.NewRecorder()
	mux.ServeHTTP(recConnect, reqConnect)
	if recConnect.Code != http.StatusBadRequest && recConnect.Code != http.StatusUnauthorized {
		t.Errorf("Expected 400 or 401 for empty token connect, got %d", recConnect.Code)
	}

	// 2. GET /api/github/user when disconnected
	reqUser := httptest.NewRequest(http.MethodGet, "/api/github/user", nil)
	recUser := httptest.NewRecorder()
	mux.ServeHTTP(recUser, reqUser)
	if recUser.Code != http.StatusUnauthorized {
		t.Errorf("Expected 401 when disconnected, got %d", recUser.Code)
	}

	// 3. POST /api/github/disconnect
	reqDisc := httptest.NewRequest(http.MethodPost, "/api/github/disconnect", nil)
	recDisc := httptest.NewRecorder()
	mux.ServeHTTP(recDisc, reqDisc)
	if recDisc.Code != http.StatusOK {
		t.Errorf("Expected 200 OK for disconnect, got %d", recDisc.Code)
	}
}

func TestIntegrationsLlmEndpoints(t *testing.T) {
	_, mux := setupTestServer(t)

	// 1. GET /api/llm/providers
	reqProviders := httptest.NewRequest(http.MethodGet, "/api/llm/providers", nil)
	recProviders := httptest.NewRecorder()
	mux.ServeHTTP(recProviders, reqProviders)
	if recProviders.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK for /api/llm/providers, got %d", recProviders.Code)
	}
	var provResp map[string]any
	_ = json.Unmarshal(recProviders.Body.Bytes(), &provResp)
	provList, ok := provResp["providers"].([]any)
	if !ok || len(provList) < 4 {
		t.Errorf("Expected at least 4 providers, got %v", provResp["providers"])
	}
	foundAntigravity := false
	for _, p := range provList {
		if pm, ok := p.(map[string]any); ok && pm["id"] == "antigravity" {
			foundAntigravity = true
			break
		}
	}
	if !foundAntigravity {
		t.Errorf("Expected antigravity provider in /api/llm/providers, got %v", provResp["providers"])
	}

	// 2. POST /api/llm/configure
	configBody := []byte(`{"providerId": "gemini", "apiKey": "test-key-12345"}`)
	reqConfig := httptest.NewRequest(http.MethodPost, "/api/llm/configure", bytes.NewReader(configBody))
	recConfig := httptest.NewRecorder()
	mux.ServeHTTP(recConfig, reqConfig)
	if recConfig.Code != http.StatusOK {
		t.Errorf("Expected 200 OK for /api/llm/configure, got %d", recConfig.Code)
	}

	// 2b. POST /api/llm/test-connection
	testConnBody := []byte(`{"mode": "cli", "providerId": "antigravity"}`)
	reqTestConn := httptest.NewRequest(http.MethodPost, "/api/llm/test-connection", bytes.NewReader(testConnBody))
	recTestConn := httptest.NewRecorder()
	mux.ServeHTTP(recTestConn, reqTestConn)
	if recTestConn.Code != http.StatusOK {
		t.Errorf("Expected 200 OK for /api/llm/test-connection, got %d", recTestConn.Code)
	}

	// 3. POST /llm/commit-message
	hunksBody := []byte(`{"provider_id": "gemini", "hunks": [{"filePath": "src/auth/jwt.ts", "moduleScope": "auth", "intent": "feat", "summary": "enforce PKCE entropy", "additions": 20, "deletions": 2}]}`)
	reqMsg := httptest.NewRequest(http.MethodPost, "/llm/commit-message", bytes.NewReader(hunksBody))
	recMsg := httptest.NewRecorder()
	mux.ServeHTTP(recMsg, reqMsg)
	if recMsg.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK for /llm/commit-message, got %d", recMsg.Code)
	}
	var msgResp map[string]any
	_ = json.Unmarshal(recMsg.Body.Bytes(), &msgResp)
	if title, _ := msgResp["title"].(string); title != "feat(auth): enforce PKCE entropy" {
		t.Errorf("Expected conventional title, got %v", title)
	}
	if prov, _ := msgResp["provider"].(string); prov != "google_antigravity" {
		t.Errorf("Expected provider google_antigravity, got %v", prov)
	}
	if sub, _ := msgResp["subscription"].(string); sub == "" {
		t.Errorf("Expected non-empty subscription, got %v", sub)
	}
}

func TestIntegrationsAgentRedirectionEndpoints(t *testing.T) {
	_, mux := setupTestServer(t)

	tmpDir := t.TempDir()
	body, _ := json.Marshal(map[string]any{"agentId": "antigravity", "workspacePath": tmpDir})
	req := httptest.NewRequest(http.MethodPost, "/api/agents/connect", bytes.NewReader(body))
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK for /api/agents/connect, got %d", rec.Code)
	}
	var resp map[string]any
	_ = json.Unmarshal(rec.Body.Bytes(), &resp)
	token, _ := resp["token"].(string)
	if resp["ok"] != true || resp["status"] != "awaiting_confirmation" || token == "" {
		t.Errorf("Unexpected handshake initiation response: %v", resp)
	}

	reqAuth := httptest.NewRequest(http.MethodGet, "/agents/authorize?agentId=antigravity&token="+token, nil)
	recAuth := httptest.NewRecorder()
	mux.ServeHTTP(recAuth, reqAuth)
	if recAuth.Code != http.StatusOK || !bytes.Contains(recAuth.Body.Bytes(), []byte("AGENT HANDSHAKE")) {
		t.Errorf("Expected 200 OK and auth page for /agents/authorize, got %d", recAuth.Code)
	}

	confirmBody, _ := json.Marshal(map[string]any{"agentId": "antigravity", "token": token})
	reqConf := httptest.NewRequest(http.MethodPost, "/api/agents/confirm", bytes.NewReader(confirmBody))
	recConf := httptest.NewRecorder()
	mux.ServeHTTP(recConf, reqConf)
	if recConf.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK for /api/agents/confirm, got %d", recConf.Code)
	}

	discBody, _ := json.Marshal(map[string]any{"agentId": "antigravity"})
	reqDisc := httptest.NewRequest(http.MethodPost, "/api/agents/disconnect", bytes.NewReader(discBody))
	recDisc := httptest.NewRecorder()
	mux.ServeHTTP(recDisc, reqDisc)
	if recDisc.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK for /api/agents/disconnect, got %d", recDisc.Code)
	}
}
