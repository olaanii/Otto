package main

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"testing"
)

func TestGitHubRemoteAutoDetection(t *testing.T) {
	t.Run("HTTPS remote URL parsing", func(t *testing.T) {
		rawURL := "https://github.com/olaanii/Otto"
		owner, repo, branch, err := ParseGitRemote(rawURL)
		if err != nil {
			t.Fatalf("ParseGitRemote(%q) returned unexpected error: %v", rawURL, err)
		}
		if owner != "olaanii" {
			t.Errorf("expected owner 'olaanii', got %q", owner)
		}
		if repo != "Otto" {
			t.Errorf("expected repo 'Otto', got %q", repo)
		}
		if branch != "main" {
			t.Errorf("expected default branch 'main', got %q", branch)
		}

		// Also verify DetectGitRemote returns the same info struct
		info, err := DetectGitRemote(rawURL)
		if err != nil {
			t.Fatalf("DetectGitRemote(%q) returned unexpected error: %v", rawURL, err)
		}
		if info.Owner != "olaanii" || info.Repo != "Otto" || info.DefaultBranch != "main" {
			t.Errorf("DetectGitRemote(%q) struct mismatch: %+v", rawURL, info)
		}
	})

	t.Run("HTTPS remote URL with .git suffix", func(t *testing.T) {
		rawURL := "https://github.com/olaanii/Otto.git"
		owner, repo, branch, err := ParseGitHubRemote(rawURL)
		if err != nil {
			t.Fatalf("ParseGitHubRemote(%q) returned unexpected error: %v", rawURL, err)
		}
		if owner != "olaanii" || repo != "Otto" || branch != "main" {
			t.Errorf("expected (olaanii, Otto, main), got (%s, %s, %s)", owner, repo, branch)
		}
	})

	t.Run("SSH remote URL parsing", func(t *testing.T) {
		rawURL := "git@github.com:olaanii/Otto.git"
		owner, repo, branch, err := ParseGitRemote(rawURL)
		if err != nil {
			t.Fatalf("ParseGitRemote(%q) returned unexpected error: %v", rawURL, err)
		}
		if owner != "olaanii" || repo != "Otto" || branch != "main" {
			t.Errorf("expected (olaanii, Otto, main), got (%s, %s, %s)", owner, repo, branch)
		}
	})

	t.Run("Auto-detection from repository git context", func(t *testing.T) {
		// When passed an empty string, DetectGitRemote inspects local git origin
		info, err := DetectGitRemote("")
		if err != nil {
			t.Fatalf("DetectGitRemote(\"\") auto-detection failed: %v", err)
		}
		if info.Owner != "olaanii" {
			t.Errorf("expected auto-detected owner 'olaanii', got %q", info.Owner)
		}
		if info.Repo != "Otto" {
			t.Errorf("expected auto-detected repo 'Otto', got %q", info.Repo)
		}
		if info.DefaultBranch != "main" {
			t.Errorf("expected auto-detected default branch 'main', got %q", info.DefaultBranch)
		}
	})
}

func TestGitHubVerifyEndpoint(t *testing.T) {
	tempStateFile := filepath.Join(t.TempDir(), "test-atomik-state.json")
	server := NewDaemonServerWithPath(tempStateFile)
	router := server.SetupRouter()

	t.Run("POST /api/github/verify with explicit remote URL", func(t *testing.T) {
		reqBody := []byte(`{"remoteUrl":"https://github.com/olaanii/Otto"}`)
		req := httptest.NewRequest(http.MethodPost, "/api/github/verify", bytes.NewReader(reqBody))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()

		router.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected status 200, got %d: %s", rec.Code, rec.Body.String())
		}

		var resp map[string]any
		if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
			t.Fatalf("failed to decode JSON response: %v", err)
		}

		if resp["ok"] != true {
			t.Errorf("expected ok: true, got %v", resp["ok"])
		}
		if resp["connected"] != true {
			t.Errorf("expected connected: true, got %v", resp["connected"])
		}
		if resp["owner"] != "olaanii" {
			t.Errorf("expected owner 'olaanii', got %v", resp["owner"])
		}
		if resp["repo"] != "Otto" {
			t.Errorf("expected repo 'Otto', got %v", resp["repo"])
		}
		if resp["defaultBranch"] != "main" {
			t.Errorf("expected defaultBranch 'main', got %v", resp["defaultBranch"])
		}
		if resp["branch"] != "main" {
			t.Errorf("expected branch 'main', got %v", resp["branch"])
		}

		// Verify internal server state was updated
		server.mu.RLock()
		defer server.mu.RUnlock()
		if !server.state.GitHubConfig.Connected {
			t.Errorf("server state GitHubConfig.Connected should be true")
		}
		if server.state.GitHubConfig.Owner != "olaanii" {
			t.Errorf("server state GitHubConfig.Owner should be 'olaanii', got %q", server.state.GitHubConfig.Owner)
		}
		if server.state.GitHubConfig.Repo != "Otto" {
			t.Errorf("server state GitHubConfig.Repo should be 'Otto', got %q", server.state.GitHubConfig.Repo)
		}
		if server.state.GitHubConfig.DefaultBranch != "main" {
			t.Errorf("server state GitHubConfig.DefaultBranch should be 'main', got %q", server.state.GitHubConfig.DefaultBranch)
		}
	})

	t.Run("POST /api/github/verify with empty payload", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodPost, "/api/github/verify", bytes.NewReader([]byte(`{}`)))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()

		router.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected status 200, got %d: %s", rec.Code, rec.Body.String())
		}

		var resp map[string]any
		if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
			t.Fatalf("failed to decode JSON response: %v", err)
		}

		if resp["connected"] != true {
			t.Errorf("expected connected: true, got %v", resp["connected"])
		}
		if resp["owner"] != "olaanii" {
			t.Errorf("expected owner 'olaanii', got %v", resp["owner"])
		}
		if resp["repo"] != "Otto" {
			t.Errorf("expected repo 'Otto', got %v", resp["repo"])
		}
		if resp["defaultBranch"] != "main" {
			t.Errorf("expected defaultBranch 'main', got %v", resp["defaultBranch"])
		}
	})

	t.Run("GET /api/github/verify method not allowed", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/github/verify", nil)
		rec := httptest.NewRecorder()

		router.ServeHTTP(rec, req)

		if rec.Code != http.StatusMethodNotAllowed {
			t.Errorf("expected status 405 Method Not Allowed, got %d", rec.Code)
		}
	})
}

func TestPushStackStaging(t *testing.T) {
	tempStateFile := filepath.Join(t.TempDir(), "test-push-stack-state.json")
	server := NewDaemonServerWithPath(tempStateFile)
	router := server.SetupRouter()

	t.Run("Pushes staged stack units and updates pushed stack", func(t *testing.T) {
		// Populate initial staged stack and working tree hunks
		server.mu.Lock()
		server.state.WorkingTreeHunks = []DiffHunk{
			{
				ID:        "hunk-auth-01",
				FilePath:  "src/auth/jwt.ts",
				Additions: 32,
				Deletions: 4,
			},
		}
		server.state.StagedAtomicStack = []AtomicCommitUnit{
			{
				ID:                 "slice-01",
				Type:               "feat",
				Scope:              "auth",
				Title:              "add jwt token verifier",
				ConventionalHeader: "feat(auth): add jwt token verifier",
				BranchName:         "otto/atomic-pr144-auth",
				ParentBranch:       "main",
				Status:             "staged",
				TotalAdditions:     32,
				TotalDeletions:     4,
				TotalLoc:           36,
			},
			{
				ID:                 "slice-02",
				Type:               "fix",
				Scope:              "payment",
				Title:              "prevent duplicate charge on timeout",
				ConventionalHeader: "fix(payment): prevent duplicate charge on timeout",
				BranchName:         "otto/atomic-pr145-payment",
				ParentBranch:       "main",
				Status:             "staged",
				TotalAdditions:     15,
				TotalDeletions:     2,
				TotalLoc:           17,
			},
		}
		server.state.PushedStack = []AtomicCommitUnit{
			{
				ID:                 "pr-143",
				Type:               "fix",
				Scope:              "ledger",
				Title:              "correct ledger balance rounding",
				ConventionalHeader: "fix(ledger): correct ledger balance rounding",
				BranchName:         "otto/atomic-pr143-ledger",
				ParentBranch:       "main",
				Status:             "pr_open",
				PrNumber:           143,
			},
		}
		server.mu.Unlock()

		// Verify initial state
		if len(server.state.StagedAtomicStack) != 2 {
			t.Fatalf("expected 2 staged units initially, got %d", len(server.state.StagedAtomicStack))
		}
		if len(server.state.PushedStack) != 1 {
			t.Fatalf("expected 1 pushed unit initially, got %d", len(server.state.PushedStack))
		}

		// Perform POST /api/git/push-stack
		req := httptest.NewRequest(http.MethodPost, "/api/git/push-stack", nil)
		rec := httptest.NewRecorder()

		router.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected status 200, got %d: %s", rec.Code, rec.Body.String())
		}

		var resp map[string]any
		if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
			t.Fatalf("failed to decode JSON response: %v", err)
		}

		if resp["ok"] != true {
			t.Errorf("expected ok: true, got %v", resp["ok"])
		}
		if pushedCount, ok := resp["pushedCount"].(float64); !ok || int(pushedCount) != 2 {
			t.Errorf("expected pushedCount: 2, got %v", resp["pushedCount"])
		}
		if latestPr, ok := resp["latestPrNumber"].(float64); !ok || int(latestPr) != 145 {
			t.Errorf("expected latestPrNumber: 145, got %v", resp["latestPrNumber"])
		}

		// Verify server internal state mutations
		server.mu.RLock()
		defer server.mu.RUnlock()

		if len(server.state.StagedAtomicStack) != 0 {
			t.Errorf("expected StagedAtomicStack to be cleared (0), got %d", len(server.state.StagedAtomicStack))
		}
		if len(server.state.WorkingTreeHunks) != 0 {
			t.Errorf("expected WorkingTreeHunks to be cleared (0), got %d", len(server.state.WorkingTreeHunks))
		}
		if len(server.state.PushedStack) != 3 {
			t.Fatalf("expected PushedStack to have 3 items, got %d", len(server.state.PushedStack))
		}

		// Verify newly pushed units have "pr_open" status and assigned PR numbers
		foundSlice1 := false
		foundSlice2 := false
		for _, unit := range server.state.PushedStack {
			if unit.ID == "slice-01" {
				foundSlice1 = true
				if unit.Status != "pr_open" {
					t.Errorf("expected slice-01 status 'pr_open', got %q", unit.Status)
				}
				if unit.PrNumber <= 143 {
					t.Errorf("expected slice-01 PrNumber > 143, got %d", unit.PrNumber)
				}
			}
			if unit.ID == "slice-02" {
				foundSlice2 = true
				if unit.Status != "pr_open" {
					t.Errorf("expected slice-02 status 'pr_open', got %q", unit.Status)
				}
				if unit.PrNumber <= 143 {
					t.Errorf("expected slice-02 PrNumber > 143, got %d", unit.PrNumber)
				}
			}
		}

		if !foundSlice1 || !foundSlice2 {
			t.Errorf("missing promoted units in PushedStack: foundSlice1=%v, foundSlice2=%v", foundSlice1, foundSlice2)
		}
	})

	t.Run("Idempotent push with empty staged stack", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodPost, "/api/git/push-stack", nil)
		rec := httptest.NewRecorder()

		router.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected status 200, got %d: %s", rec.Code, rec.Body.String())
		}

		var resp map[string]any
		if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
			t.Fatalf("failed to decode JSON response: %v", err)
		}

		if resp["ok"] != true {
			t.Errorf("expected ok: true, got %v", resp["ok"])
		}
		if pushedCount, ok := resp["pushedCount"].(float64); !ok || int(pushedCount) != 0 {
			t.Errorf("expected pushedCount: 0, got %v", resp["pushedCount"])
		}
	})
}
