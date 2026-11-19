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

	// 1. POST /api/workspace/open with invalid path
	req := httptest.NewRequest(http.MethodPost, "/api/workspace/open", bytes.NewReader([]byte(`{"path": "invalid_non_git_path_12345"}`)))
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)
	if rec.Code != http.StatusBadRequest {
		t.Errorf("Expected 400 Bad Request for non-git directory, got %d", rec.Code)
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

	// 2. POST /api/llm/configure
	configBody := []byte(`{"providerId": "gemini", "apiKey": "test-key-12345"}`)
	reqConfig := httptest.NewRequest(http.MethodPost, "/api/llm/configure", bytes.NewReader(configBody))
	recConfig := httptest.NewRecorder()
	mux.ServeHTTP(recConfig, reqConfig)
	if recConfig.Code != http.StatusOK {
		t.Errorf("Expected 200 OK for /api/llm/configure, got %d", recConfig.Code)
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
}
