package main

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"
)

func TestSecurityCORSOrigins(t *testing.T) {
	server, mux := setupTestServer(t)
	_ = server

	tests := []struct {
		name       string
		method     string
		origin     string
		wantReject bool
	}{
		{
			name:       "Malicious external origin rejected on OPTIONS",
			method:     http.MethodOptions,
			origin:     "https://malicious.com",
			wantReject: true,
		},
		{
			name:       "Malicious external origin rejected on GET",
			method:     http.MethodGet,
			origin:     "https://malicious.com",
			wantReject: true,
		},
		{
			name:       "Attacker subdomain rejected",
			method:     http.MethodOptions,
			origin:     "http://localhost.evil.com",
			wantReject: true,
		},
		{
			name:       "Localhost loopback allowed",
			method:     http.MethodGet,
			origin:     "http://localhost:3000",
			wantReject: false,
		},
		{
			name:       "IPv4 loopback allowed",
			method:     http.MethodGet,
			origin:     "http://127.0.0.1:3000",
			wantReject: false,
		},
		{
			name:       "Tauri desktop localhost allowed",
			method:     http.MethodGet,
			origin:     "tauri://localhost",
			wantReject: false,
		},
		{
			name:       "Empty origin (desktop client) allowed",
			method:     http.MethodGet,
			origin:     "",
			wantReject: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest(tt.method, "/api/state", nil)
			if tt.origin != "" {
				req.Header.Set("Origin", tt.origin)
			}
			rec := httptest.NewRecorder()
			mux.ServeHTTP(rec, req)

			allowOrigin := rec.Header().Get("Access-Control-Allow-Origin")
			if tt.wantReject {
				if rec.Code != http.StatusForbidden {
					t.Errorf("Expected status 403 Forbidden for origin %q, got %d", tt.origin, rec.Code)
				}
				if allowOrigin == "*" || allowOrigin == tt.origin {
					t.Errorf("Access-Control-Allow-Origin must not allow %q or *", tt.origin)
				}
			} else {
				if rec.Code == http.StatusForbidden {
					t.Errorf("Expected origin %q to be accepted, but got 403", tt.origin)
				}
				if tt.origin != "" && allowOrigin != tt.origin {
					t.Errorf("Expected Access-Control-Allow-Origin to be %q, got %q", tt.origin, allowOrigin)
				}
				if allowOrigin == "*" {
					t.Errorf("Access-Control-Allow-Origin must never be wildcard *")
				}
			}
		})
	}
}

func TestSecurityHandshakeTokenVerification(t *testing.T) {
	server, mux := setupTestServer(t)

	server.mu.Lock()
	server.state.IdeProfiles = []IdeAgentProfile{
		{
			ID:               "antigravity",
			Name:             "Google Antigravity",
			Status:           "pending_auth",
			Connected:        false,
			HandshakeToken:   "super-secret-handshake-token-999",
			PendingWorkspace: "C:/test/workspace",
		},
	}
	server.mu.Unlock()

	// 1. Attempt handshake with empty token (must be rejected)
	emptyPayload, _ := json.Marshal(map[string]string{
		"agentId": "antigravity",
		"token":   "",
	})
	reqEmpty := httptest.NewRequest(http.MethodPost, "/api/agents/confirm", bytes.NewReader(emptyPayload))
	recEmpty := httptest.NewRecorder()
	mux.ServeHTTP(recEmpty, reqEmpty)

	if recEmpty.Code != http.StatusBadRequest {
		t.Fatalf("Expected 400 Bad Request for empty handshake token, got %d", recEmpty.Code)
	}

	server.mu.RLock()
	if server.state.IdeProfiles[0].Connected {
		t.Fatalf("Agent profile should NOT be connected after empty token attempt")
	}
	server.mu.RUnlock()

	// 2. Attempt handshake with invalid token (must be rejected)
	badPayload, _ := json.Marshal(map[string]string{
		"agentId": "antigravity",
		"token":   "wrong-token",
	})
	reqBad := httptest.NewRequest(http.MethodPost, "/api/agents/confirm", bytes.NewReader(badPayload))
	recBad := httptest.NewRecorder()
	mux.ServeHTTP(recBad, reqBad)

	if recBad.Code != http.StatusBadRequest {
		t.Fatalf("Expected 400 Bad Request for invalid token, got %d", recBad.Code)
	}

	// 3. Attempt handshake with valid token (must succeed)
	goodPayload, _ := json.Marshal(map[string]string{
		"agentId": "antigravity",
		"token":   "super-secret-handshake-token-999",
	})
	reqGood := httptest.NewRequest(http.MethodPost, "/api/agents/confirm", bytes.NewReader(goodPayload))
	recGood := httptest.NewRecorder()
	mux.ServeHTTP(recGood, reqGood)

	if recGood.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK for valid token, got %d: %s", recGood.Code, recGood.Body.String())
	}

	server.mu.RLock()
	if !server.state.IdeProfiles[0].Connected {
		t.Fatalf("Agent profile should be connected after valid handshake")
	}
	server.mu.RUnlock()
}

func TestSecurityStateTokenExclusion(t *testing.T) {
	server, mux := setupTestServer(t)

	rawGitHubToken := "ghp_sensitive_secret_token_abcdef123456"
	rawOpenAIKey := "sk-proj-supersecretkey1234"
	rawGeminiKey := "AIzaSySensitiveKey9876"

	server.mu.Lock()
	server.state.GitHubConfig = GitHubConfig{
		Owner:     "octocat",
		Repo:      "hello-world",
		Connected: true,
		Token:     rawGitHubToken,
		HasToken:  true,
	}
	server.state.LlmKeys = map[string]string{
		"openai":       rawOpenAIKey,
		"gemini":       rawGeminiKey,
		"openai_model": "gpt-4o",
	}
	server.mu.Unlock()

	req := httptest.NewRequest(http.MethodGet, "/api/state", nil)
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("Expected 200 OK from /api/state, got %d", rec.Code)
	}

	bodyStr := rec.Body.String()

	// Ensure raw secrets do NOT leak anywhere in response JSON
	if strings.Contains(bodyStr, rawGitHubToken) {
		t.Fatalf("Security breach: Raw GitHub token leaked in /api/state response: %s", bodyStr)
	}
	if strings.Contains(bodyStr, rawOpenAIKey) {
		t.Fatalf("Security breach: Raw OpenAI key leaked in /api/state response: %s", bodyStr)
	}
	if strings.Contains(bodyStr, rawGeminiKey) {
		t.Fatalf("Security breach: Raw Gemini key leaked in /api/state response: %s", bodyStr)
	}

	// Parse JSON to verify safe masking and HasToken indicator
	var stateResp map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &stateResp); err != nil {
		t.Fatalf("Failed to parse state JSON: %v", err)
	}

	ghCfg, ok := stateResp["githubConfig"].(map[string]any)
	if !ok {
		t.Fatalf("Missing githubConfig in state response: %v", stateResp)
	}
	if ghCfg["token"] != nil && ghCfg["token"] != "" {
		t.Fatalf("Expected token to be omitted or empty, got %v", ghCfg["token"])
	}
	if ghCfg["hasToken"] != true {
		t.Fatalf("Expected hasToken to be true, got %v", ghCfg["hasToken"])
	}

	llmKeys, ok := stateResp["llmKeys"].(map[string]any)
	if !ok {
		t.Fatalf("Missing llmKeys in state response: %v", stateResp)
	}
	openaiMasked, ok := llmKeys["openai"].(string)
	if !ok || !strings.Contains(openaiMasked, "...") {
		t.Errorf("Expected masked openai key, got %v", llmKeys["openai"])
	}
	if !strings.HasSuffix(openaiMasked, "1234") {
		t.Errorf("Expected masked openai key to end with 1234, got %s", openaiMasked)
	}
	// Verify non-secret config like openai_model is preserved unmasked
	if llmKeys["openai_model"] != "gpt-4o" {
		t.Errorf("Expected openai_model to be gpt-4o, got %v", llmKeys["openai_model"])
	}
}

func TestSecurityClerkSecretKeyUnconfigured(t *testing.T) {
	origKey := os.Getenv("CLERK_SECRET_KEY")
	_ = os.Unsetenv("CLERK_SECRET_KEY")
	t.Cleanup(func() {
		if origKey != "" {
			_ = os.Setenv("CLERK_SECRET_KEY", origKey)
		} else {
			_ = os.Unsetenv("CLERK_SECRET_KEY")
		}
	})

	_, mux := setupTestServer(t)

	// 1. POST /auth/clerk-verify without CLERK_SECRET_KEY must return 500
	reqVerify := httptest.NewRequest(http.MethodPost, "/auth/clerk-verify", bytes.NewReader([]byte(`{"ticket":"t123"}`)))
	recVerify := httptest.NewRecorder()
	mux.ServeHTTP(recVerify, reqVerify)

	if recVerify.Code != http.StatusInternalServerError {
		t.Fatalf("Expected 500 for unconfigured CLERK_SECRET_KEY on /auth/clerk-verify, got %d", recVerify.Code)
	}
	var verifyResp map[string]any
	_ = json.Unmarshal(recVerify.Body.Bytes(), &verifyResp)
	if verifyResp["ok"] != false || !strings.Contains(verifyResp["error"].(string), "CLERK_SECRET_KEY environment variable is not configured") {
		t.Fatalf("Unexpected response body: %s", recVerify.Body.String())
	}

	// 2. GET /auth/callback without email and without CLERK_SECRET_KEY must return 500
	reqCb := httptest.NewRequest(http.MethodGet, "/auth/callback", nil)
	recCb := httptest.NewRecorder()
	mux.ServeHTTP(recCb, reqCb)

	if recCb.Code != http.StatusInternalServerError {
		t.Fatalf("Expected 500 for unconfigured CLERK_SECRET_KEY on /auth/callback, got %d", recCb.Code)
	}
	var cbResp map[string]any
	_ = json.Unmarshal(recCb.Body.Bytes(), &cbResp)
	if cbResp["ok"] != false || !strings.Contains(cbResp["error"].(string), "CLERK_SECRET_KEY environment variable is not configured") {
		t.Fatalf("Unexpected response body: %s", recCb.Body.String())
	}
}
