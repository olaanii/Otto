package main

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
)

func setupTestServer(t *testing.T) (*DaemonServer, *http.ServeMux) {
	tempDir, err := os.MkdirTemp("", "otto-daemon-test-*")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	t.Cleanup(func() {
		_ = os.RemoveAll(tempDir)
	})

	server := NewDaemonServerWithPath(tempDir + "/test-state.json")
	mux := server.SetupRouter()
	return server, mux
}

func TestAntigravityAstSlicerGuardrails(t *testing.T) {
	policy := GuardrailPolicy{
		MaxLocPerCommit:            80,
		MaxFilesPerCommit:          3,
		EnforceConventionalCommits: true,
		IsolateBrainstormingDocs:   true,
		RequireTestsForFeatFix:     true,
		BranchPrefix:               "otto/atomic",
		BaseBranch:                 "main",
	}

	hunks := []DiffHunk{
		{
			ID:          "hunk-code",
			FilePath:    "src/payment/pkceVerifier.ts",
			ModuleScope: "payment",
			Intent:      "feat",
			Summary:     "enforce SHA-256 PKCE code challenge entropy",
			Additions:   48,
			Deletions:   6,
		},
		{
			ID:             "hunk-test",
			FilePath:       "src/payment/pkceVerifier.test.ts",
			ModuleScope:    "payment",
			Intent:         "test",
			Summary:        "add PKCE RFC 7636 challenge entropy test suite",
			Additions:      22,
			Deletions:      2,
			HasCoupledTest: true,
		},
		{
			ID:                 "hunk-doc",
			FilePath:           "docs/antigravity-plan.md",
			ModuleScope:        "docs",
			Intent:             "docs",
			Summary:            "architectural plan for PKCE token exchange",
			Additions:          35,
			Deletions:          0,
			IsBrainstormOrPlan: true,
		},
	}

	slices, metrics := runAntigravityAstSlicer(hunks, policy)

	if len(slices) != 2 {
		t.Fatalf("Expected 2 slices (1 code+test, 1 isolated doc), got %d", len(slices))
	}

	// 1. Verify code + test coupling
	codeSlice := slices[0]
	if codeSlice.Type != "feat" || codeSlice.Scope != "payment" {
		t.Errorf("Expected feat(payment), got %s(%s)", codeSlice.Type, codeSlice.Scope)
	}
	if codeSlice.TotalLoc != 78 {
		t.Errorf("Expected coupled LOC 78, got %d", codeSlice.TotalLoc)
	}
	if codeSlice.TotalLoc > 80 {
		t.Errorf("Guardrail violation: commit exceeds 80 LOC (%d)", codeSlice.TotalLoc)
	}
	if len(codeSlice.BodyBullets) != 2 {
		t.Errorf("Expected 2 rationale bullets, got %d", len(codeSlice.BodyBullets))
	}

	// 2. Verify doc isolation
	docSlice := slices[1]
	if docSlice.Type != "docs" || docSlice.Scope != "plan" {
		t.Errorf("Expected docs(plan), got %s(%s)", docSlice.Type, docSlice.Scope)
	}
	if docSlice.TotalLoc != 35 {
		t.Errorf("Expected doc LOC 35, got %d", docSlice.TotalLoc)
	}
	if len(docSlice.BodyBullets) != 2 {
		t.Errorf("Expected 2 rationale bullets on doc, got %d", len(docSlice.BodyBullets))
	}

	// 3. Verify execution speed < 50ms
	execTime, ok := metrics["executionTimeMs"].(float64)
	if !ok || execTime >= 50.0 {
		t.Errorf("Expected executionTimeMs < 50ms, got %v", execTime)
	}
}

func TestAntigravityConnectAndStatusEndpoints(t *testing.T) {
	_, mux := setupTestServer(t)

	// Test POST /api/antigravity/connect
	connectPayload := []byte(`{"email":"developer@otto.dev","name":"Otto Developer","authProvider":"google"}`)
	req := httptest.NewRequest(http.MethodPost, "/api/antigravity/connect", bytes.NewReader(connectPayload))
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("POST /api/antigravity/connect returned %d", rec.Code)
	}

	var connResp struct {
		Ok          bool               `json:"ok"`
		Connected   bool               `json:"connected"`
		Antigravity AntigravitySession `json:"antigravity"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &connResp); err != nil {
		t.Fatalf("Failed to parse connect response: %v", err)
	}
	if !connResp.Connected || connResp.Antigravity.User.Email != "developer@otto.dev" {
		t.Errorf("Unexpected connect response: %+v", connResp)
	}

	// Test POST /api/antigravity/connect with empty payload (rejection of unauthenticated empty connects)
	reqEmpty := httptest.NewRequest(http.MethodPost, "/api/antigravity/connect", bytes.NewReader([]byte(`{}`)))
	recEmpty := httptest.NewRecorder()
	mux.ServeHTTP(recEmpty, reqEmpty)

	if recEmpty.Code != http.StatusBadRequest {
		t.Fatalf("POST /api/antigravity/connect with empty payload should return 400, got %d", recEmpty.Code)
	}

	// Test GET /auth/login (OAuth initialization)
	reqLogin := httptest.NewRequest(http.MethodGet, "/auth/login?format=json", nil)
	recLogin := httptest.NewRecorder()
	mux.ServeHTTP(recLogin, reqLogin)
	if recLogin.Code != http.StatusOK {
		t.Fatalf("GET /auth/login returned %d", recLogin.Code)
	}

	// Test GET /auth/callback (Loopback browser redirect handler)
	reqCallback := httptest.NewRequest(http.MethodGet, "/auth/callback?email=oauth-user@otto.dev&name=OAuth+User&provider=google", nil)
	recCallback := httptest.NewRecorder()
	mux.ServeHTTP(recCallback, reqCallback)
	if recCallback.Code != http.StatusOK {
		t.Fatalf("GET /auth/callback returned %d", recCallback.Code)
	}

	// Test GET /api/antigravity/status
	statusReq := httptest.NewRequest(http.MethodGet, "/api/antigravity/status", nil)
	statusRec := httptest.NewRecorder()
	mux.ServeHTTP(statusRec, statusReq)

	if statusRec.Code != http.StatusOK {
		t.Fatalf("GET /api/antigravity/status returned %d", statusRec.Code)
	}

	var statusResp map[string]any
	if err := json.Unmarshal(statusRec.Body.Bytes(), &statusResp); err != nil {
		t.Fatalf("Failed to parse status response: %v", err)
	}
	if statusResp["subscriptionMode"] != "$0 extra token fees" {
		t.Errorf("Expected subscriptionMode '$0 extra token fees', got %v", statusResp["subscriptionMode"])
	}
	if statusResp["model"] != "Gemini 3.8 Flash (High)" {
		t.Errorf("Expected model 'Gemini 3.8 Flash (High)', got %v", statusResp["model"])
	}
}

func TestAntigravityEventsEndpoint(t *testing.T) {
	_, mux := setupTestServer(t)

	payload := []byte(`{
		"id": "evt_12345",
		"timestamp": "2026-11-19T10:00:00Z",
		"promptText": "implement PKCE RFC 7636 verifier",
		"sourceAgent": "antigravity",
		"category": "feature",
		"filesTouched": ["src/payment/pkceVerifier.ts"],
		"locDelta": "+48 -6",
		"agentAction": "turn_completed"
	}`)

	req := httptest.NewRequest(http.MethodPost, "/api/antigravity/events", bytes.NewReader(payload))
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("POST /api/antigravity/events returned %d", rec.Code)
	}

	var resp map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("Failed to parse response: %v", err)
	}

	if resp["ok"] != true {
		t.Errorf("Expected ok: true, got %v", resp["ok"])
	}
}

func TestAntigravityTestConnectionEndpoint(t *testing.T) {
	_, mux := setupTestServer(t)

	req := httptest.NewRequest(http.MethodPost, "/api/antigravity/test-connection", nil)
	rec := httptest.NewRecorder()
	mux.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("POST /api/antigravity/test-connection returned %d", rec.Code)
	}

	var resp map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("Failed to parse test-connection response: %v", err)
	}

	if resp["ok"] != true {
		t.Errorf("Expected ok: true, got %v", resp["ok"])
	}
	if resp["guardrailsVerified"] != true {
		t.Errorf("Expected guardrailsVerified: true, got %v", resp["guardrailsVerified"])
	}
}

func TestAuthSessionAndCallbackFlow(t *testing.T) {
	server, mux := setupTestServer(t)

	// 1. Initial state: unauthenticated
	reqSession := httptest.NewRequest(http.MethodGet, "/auth/session", nil)
	recSession := httptest.NewRecorder()
	mux.ServeHTTP(recSession, reqSession)
	if recSession.Code != http.StatusUnauthorized {
		t.Fatalf("Expected /auth/session to return 401 when disconnected, got %d", recSession.Code)
	}

	// 2. Callback with email establishes session
	reqCb := httptest.NewRequest(http.MethodGet, "/auth/callback?email=user@domain.com&name=Test+User", nil)
	recCb := httptest.NewRecorder()
	mux.ServeHTTP(recCb, reqCb)
	if recCb.Code != http.StatusOK {
		t.Fatalf("Expected /auth/callback to return 200, got %d", recCb.Code)
	}

	// 3. Verify /auth/session is now authenticated
	recSession2 := httptest.NewRecorder()
	mux.ServeHTTP(recSession2, reqSession)
	if recSession2.Code != http.StatusOK {
		t.Fatalf("Expected /auth/session to return 200, got %d", recSession2.Code)
	}
	var sessResp map[string]any
	_ = json.Unmarshal(recSession2.Body.Bytes(), &sessResp)
	if sessResp["authenticated"] != true {
		t.Errorf("Expected authenticated: true, got %v", sessResp["authenticated"])
	}

	// 4. Test /auth/signout
	reqSignOut := httptest.NewRequest(http.MethodPost, "/auth/signout", nil)
	recSignOut := httptest.NewRecorder()
	mux.ServeHTTP(recSignOut, reqSignOut)
	if recSignOut.Code != http.StatusOK {
		t.Fatalf("Expected /auth/signout to return 200, got %d", recSignOut.Code)
	}
	if server.antigravity.Connected {
		t.Errorf("Expected Connected: false after signout")
	}
}
