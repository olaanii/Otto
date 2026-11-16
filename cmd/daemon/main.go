package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"sync"
	"time"
)

type CommitType string

type DiffHunk struct {
	ID                 string     `json:"id"`
	FilePath           string     `json:"filePath"`
	ModuleScope        string     `json:"moduleScope"`
	Intent             CommitType `json:"intent"`
	Summary            string     `json:"summary"`
	Additions          int        `json:"additions"`
	Deletions          int        `json:"deletions"`
	DiffSnippet        string     `json:"diffSnippet"`
	PromptContext      string     `json:"promptContext,omitempty"`
	SourceAgent        string     `json:"sourceAgent,omitempty"`
	IsBrainstormOrPlan bool       `json:"isBrainstormOrPlan,omitempty"`
	HasCoupledTest     bool       `json:"hasCoupledTest,omitempty"`
}

type AtomicCommitUnit struct {
	ID                 string     `json:"id"`
	Type               CommitType `json:"type"`
	Scope              string     `json:"scope"`
	Title              string     `json:"title"`
	ConventionalHeader string     `json:"conventionalHeader"`
	BodyBullets        []string   `json:"bodyBullets"`
	BranchName         string     `json:"branchName"`
	ParentBranch       string     `json:"parentBranch"`
	Hunks              []DiffHunk `json:"hunks"`
	TotalAdditions     int        `json:"totalAdditions"`
	TotalDeletions     int        `json:"totalDeletions"`
	TotalLoc           int        `json:"totalLoc"`
	ReviewMinutes      int        `json:"reviewMinutes"`
	ComplianceScore    int        `json:"complianceScore"`
	Violations         []string   `json:"violations"`
	Status             string     `json:"status"` // staged, queued, pushed, pr_open, merged, draft
	Sha                string     `json:"sha,omitempty"`
	PrNumber           int        `json:"prNumber,omitempty"`
	CreatedAt          string     `json:"createdAt"`
	PromptOrigin       string     `json:"promptOrigin,omitempty"`
	SourceAgent        string     `json:"sourceAgent,omitempty"`
}

type GuardrailPolicy struct {
	MaxLocPerCommit          int    `json:"maxLocPerCommit"`
	MaxFilesPerCommit        int    `json:"maxFilesPerCommit"`
	EnforceConventionalCommits bool `json:"enforceConventionalCommits"`
	IsolateBrainstormingDocs bool   `json:"isolateBrainstormingDocs"`
	RequireTestsForFeatFix   bool   `json:"requireTestsForFeatFix"`
	AutoCommitCadenceMinutes int    `json:"autoCommitCadenceMinutes"`
	AutoPushToGitHub         bool   `json:"autoPushToGitHub"`
	BranchPrefix             string `json:"branchPrefix"`
	BaseBranch               string `json:"baseBranch"`
}

type GitHubConfig struct {
	Owner         string `json:"owner"`
	Repo          string `json:"repo"`
	DefaultBranch string `json:"defaultBranch"`
	Connected     bool   `json:"connected"`
	LastSyncedAt  string `json:"lastSyncedAt,omitempty"`
	Mode          string `json:"mode,omitempty"`
}

type AppState struct {
	Policy           GuardrailPolicy    `json:"policy"`
	GitHubConfig     GitHubConfig       `json:"githubConfig"`
	IdeProfiles      []any              `json:"ideProfiles"`
	WorkingTreeHunks []DiffHunk         `json:"workingTreeHunks"`
	StagedAtomicStack []AtomicCommitUnit `json:"stagedAtomicStack"`
	PushedStack      []AtomicCommitUnit `json:"pushedStack"`
	DaemonActive     bool               `json:"daemonActive"`
}

type DaemonServer struct {
	mu         sync.RWMutex
	state      AppState
	stateFile  string
	clientsMu  sync.Mutex
	sseClients map[chan string]struct{}
}

func NewDaemonServer() *DaemonServer {
	dataDir := ".data"
	_ = os.MkdirAll(dataDir, 0755)
	stateFile := filepath.Join(dataDir, "atomik-state.json")

	s := &DaemonServer{
		stateFile:  stateFile,
		sseClients: make(map[chan string]struct{}),
	}
	s.loadOrInitState()
	return s
}

func (s *DaemonServer) loadOrInitState() {
	s.mu.Lock()
	defer s.mu.Unlock()

	data, err := os.ReadFile(s.stateFile)
	if err == nil {
		if err := json.Unmarshal(data, &s.state); err == nil && s.state.Policy.MaxLocPerCommit > 0 {
			return
		}
	}

	// Default fallback state
	s.state = AppState{
		Policy: GuardrailPolicy{
			MaxLocPerCommit:          80,
			MaxFilesPerCommit:        3,
			EnforceConventionalCommits: true,
			IsolateBrainstormingDocs: true,
			RequireTestsForFeatFix:   true,
			AutoCommitCadenceMinutes: 15,
			AutoPushToGitHub:         true,
			BranchPrefix:             "otto/atomic",
			BaseBranch:               "main",
		},
		GitHubConfig: GitHubConfig{
			Owner:         "acme-corp",
			Repo:          "core-ledger-api",
			DefaultBranch: "main",
			Connected:     true,
			LastSyncedAt:  "Just now",
			Mode:          "simulated_git_ledger",
		},
		WorkingTreeHunks: []DiffHunk{
			{
				ID:          "hunk-01",
				FilePath:    "src/payment/pkceVerifier.ts",
				ModuleScope: "payment",
				Intent:      "feat",
				Summary:     "Enforce SHA-256 PKCE code challenge entropy",
				Additions:   48,
				Deletions:   6,
				DiffSnippet: "+ export function verifyPkceChallenge(verifier: string, challenge: string): boolean {\n+   const hash = crypto.createHash('sha256').update(verifier).digest('base64url');\n+   return hash === challenge;\n+ }",
			},
		},
		StagedAtomicStack: []AtomicCommitUnit{
			{
				ID:                 "slice-01",
				Type:               "feat",
				Scope:              "payment",
				Title:              "enforce SHA-256 PKCE challenge entropy",
				ConventionalHeader: "feat(payment): enforce SHA-256 PKCE challenge entropy",
				BodyBullets: []string{
					"Verify RFC 7636 S256 code challenge length and digest matching",
					"Isolate authentication handshake into atomic commit slice",
				},
				BranchName:      "otto/atomic-pr144-payment-pkce",
				ParentBranch:    "main",
				TotalAdditions:  48,
				TotalDeletions:  6,
				TotalLoc:        54,
				ReviewMinutes:   1,
				ComplianceScore: 100,
				Status:          "staged",
				CreatedAt:       time.Now().Format(time.RFC3339),
			},
		},
		PushedStack: []AtomicCommitUnit{
			{
				ID:                 "pr-143",
				Type:               "fix",
				Scope:              "auth",
				Title:              "guard against malformed JWT exp claim",
				ConventionalHeader: "fix(auth): guard against malformed JWT exp claim",
				BranchName:         "otto/atomic-pr143-auth-jwt",
				ParentBranch:       "main",
				TotalAdditions:     24,
				TotalDeletions:     4,
				TotalLoc:           28,
				Status:             "pr_open",
				PrNumber:           143,
				CreatedAt:          time.Now().Add(-1 * time.Hour).Format(time.RFC3339),
			},
		},
		DaemonActive: true,
	}
	s.saveStateLocked()
}

func (s *DaemonServer) saveStateLocked() {
	bytes, err := json.MarshalIndent(s.state, "", "  ")
	if err == nil {
		_ = os.WriteFile(s.stateFile, bytes, 0644)
	}
}

func (s *DaemonServer) broadcastEvent(eventType string, payload any) {
	s.clientsMu.Lock()
	defer s.clientsMu.Unlock()

	msgData, _ := json.Marshal(map[string]any{
		"type":      eventType,
		"timestamp": time.Now().Format(time.RFC3339),
		"payload":   payload,
	})
	msg := fmt.Sprintf("data: %s\n\n", string(msgData))

	for ch := range s.sseClients {
		select {
		case ch <- msg:
		default:
		}
	}
}

func (s *DaemonServer) enableCORS(w http.ResponseWriter, r *http.Request) bool {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS, PUT, DELETE")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With")
	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return true
	}
	return false
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "3000"
	}

	server := NewDaemonServer()
	mux := http.NewServeMux()

	// GET /api/state & POST /api/state
	mux.HandleFunc("/api/state", func(w http.ResponseWriter, r *http.Request) {
		if server.enableCORS(w, r) {
			return
		}
		w.Header().Set("Content-Type", "application/json")

		if r.Method == http.MethodGet {
			server.mu.RLock()
			defer server.mu.RUnlock()
			_ = json.NewEncoder(w).Encode(server.state)
			return
		}

		if r.Method == http.MethodPost {
			var patch map[string]any
			if err := json.NewDecoder(r.Body).Decode(&patch); err != nil {
				http.Error(w, err.Error(), http.StatusBadRequest)
				return
			}
			server.mu.Lock()
			if d, ok := patch["daemonActive"].(bool); ok {
				server.state.DaemonActive = d
			}
			server.saveStateLocked()
			currentState := server.state
			server.mu.Unlock()

			server.broadcastEvent("state_updated", currentState)
			_ = json.NewEncoder(w).Encode(currentState)
			return
		}
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	})

	// GET /api/github/sync-status
	mux.HandleFunc("/api/github/sync-status", func(w http.ResponseWriter, r *http.Request) {
		if server.enableCORS(w, r) {
			return
		}
		w.Header().Set("Content-Type", "application/json")

		server.mu.RLock()
		stagedCount := len(server.state.StagedAtomicStack)
		openPrCount := 0
		for _, p := range server.state.PushedStack {
			if p.Status == "pr_open" {
				openPrCount++
			}
		}
		cfg := server.state.GitHubConfig
		daemonActive := server.state.DaemonActive
		server.mu.RUnlock()

		_ = json.NewEncoder(w).Encode(map[string]any{
			"connected":          cfg.Connected,
			"owner":              cfg.Owner,
			"repo":               cfg.Repo,
			"defaultBranch":      cfg.DefaultBranch,
			"activeBranch":       "main",
			"pendingPrSyncCount": stagedCount,
			"stagedCount":        stagedCount,
			"openPrCount":        openPrCount,
			"latestPrNumber":     144,
			"latestSha":          "8f4e2c1",
			"daemonActive":       daemonActive,
			"syncState":          "synced",
			"lastSyncedAt":       "Just now",
			"checkedAt":          time.Now().Format(time.RFC3339),
		})
	})

	// POST /api/github/sync-now
	mux.HandleFunc("/api/github/sync-now", func(w http.ResponseWriter, r *http.Request) {
		if server.enableCORS(w, r) {
			return
		}
		w.Header().Set("Content-Type", "application/json")

		server.mu.Lock()
		server.state.GitHubConfig.LastSyncedAt = "Just now"
		server.saveStateLocked()
		currentState := server.state
		server.mu.Unlock()

		server.broadcastEvent("stack_pushed", currentState)
		_ = json.NewEncoder(w).Encode(map[string]any{
			"ok":       true,
			"state":    currentState,
			"syncedAt": time.Now().Format(time.RFC3339),
		})
	})

	// POST /api/git/analyze
	mux.HandleFunc("/api/git/analyze", func(w http.ResponseWriter, r *http.Request) {
		if server.enableCORS(w, r) {
			return
		}
		w.Header().Set("Content-Type", "application/json")

		server.mu.RLock()
		totalLoc := 0
		for _, h := range server.state.WorkingTreeHunks {
			totalLoc += h.Additions + h.Deletions
		}
		staged := server.state.StagedAtomicStack
		server.mu.RUnlock()

		_ = json.NewEncoder(w).Encode(map[string]any{
			"stagedSlices":        staged,
			"totalUncommittedLoc": totalLoc,
			"workingTreeClean":    len(staged) == 0,
			"engine":              "otto-ast-slicer-native-go",
		})
	})

	// POST /api/git/push-stack
	mux.HandleFunc("/api/git/push-stack", func(w http.ResponseWriter, r *http.Request) {
		if server.enableCORS(w, r) {
			return
		}
		w.Header().Set("Content-Type", "application/json")

		server.mu.Lock()
		highestPr := 143
		for _, p := range server.state.PushedStack {
			if p.PrNumber > highestPr {
				highestPr = p.PrNumber
			}
		}

		pushedCount := len(server.state.StagedAtomicStack)
		for _, unit := range server.state.StagedAtomicStack {
			highestPr++
			unit.Status = "pr_open"
			unit.PrNumber = highestPr
			server.state.PushedStack = append([]AtomicCommitUnit{unit}, server.state.PushedStack...)
		}
		server.state.WorkingTreeHunks = nil
		server.state.StagedAtomicStack = nil
		server.saveStateLocked()
		currentStack := server.state.PushedStack
		server.mu.Unlock()

		server.broadcastEvent("stack_pushed", map[string]any{
			"pushedCount":    pushedCount,
			"latestPrNumber": highestPr,
		})

		_ = json.NewEncoder(w).Encode(map[string]any{
			"ok":             true,
			"pushedCount":    pushedCount,
			"latestPrNumber": highestPr,
			"stack":          currentStack,
		})
	})

	// POST /api/ai/refine-stack
	mux.HandleFunc("/api/ai/refine-stack", func(w http.ResponseWriter, r *http.Request) {
		if server.enableCORS(w, r) {
			return
		}
		w.Header().Set("Content-Type", "application/json")

		server.mu.RLock()
		staged := server.state.StagedAtomicStack
		server.mu.RUnlock()

		_ = json.NewEncoder(w).Encode(map[string]any{
			"stack":  staged,
			"engine": "otto-native-go-refiner",
		})
	})

	// SSE /api/events
	mux.HandleFunc("/api/events", func(w http.ResponseWriter, r *http.Request) {
		if server.enableCORS(w, r) {
			return
		}
		flusher, ok := w.(http.Flusher)
		if !ok {
			http.Error(w, "Streaming unsupported!", http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "text/event-stream")
		w.Header().Set("Cache-Control", "no-cache")
		w.Header().Set("Connection", "keep-alive")

		ch := make(chan string, 16)
		server.clientsMu.Lock()
		server.sseClients[ch] = struct{}{}
		server.clientsMu.Unlock()

		defer func() {
			server.clientsMu.Lock()
			delete(server.sseClients, ch)
			server.clientsMu.Unlock()
			close(ch)
		}()

		// Send initial heartbeat
		fmt.Fprintf(w, "data: {\"type\":\"connected\",\"timestamp\":\"%s\"}\n\n", time.Now().Format(time.RFC3339))
		flusher.Flush()

		for {
			select {
			case <-r.Context().Done():
				return
			case msg := <-ch:
				fmt.Fprint(w, msg)
				flusher.Flush()
			}
		}
	})

	log.Printf("🐙 Otto Native Go Daemon listening on http://localhost:%s\n", port)
	if err := http.ListenAndServe(":"+port, mux); err != nil {
		log.Fatalf("Server stopped: %v", err)
	}
}
