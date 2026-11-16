package server

import (
	"encoding/json"
	"net/http"
	"sync"
	"time"

	"otto-daemon/internal/git"
	"otto-daemon/internal/slicer"
)

// DaemonState holds comprehensive runtime state for Otto.
type DaemonState struct {
	RepoPath        string                    `json:"repo_path"`
	CurrentBranch   string                    `json:"current_branch"`
	BaseBranch      string                    `json:"base_branch"`
	IsClean         bool                      `json:"is_clean"`
	Status          *git.RepoStatus           `json:"status,omitempty"`
	ActiveStack     []*slicer.AtomicCommitUnit `json:"active_stack"`
	Guardrails      slicer.SlicerGuardrails   `json:"guardrails"`
	PreferredModel  string                    `json:"preferred_model"`
	LastAnalyzedAt  time.Time                 `json:"last_analyzed_at"`
	UpdatedAt       time.Time                 `json:"updated_at"`
}

// StateStore provides thread-safe access and mutation to the daemon's state.
type StateStore struct {
	mu    sync.RWMutex
	state DaemonState
}

// NewStateStore creates an initialized StateStore.
func NewStateStore(repoPath string) *StateStore {
	return &StateStore{
		state: DaemonState{
			RepoPath:       repoPath,
			BaseBranch:     "main",
			ActiveStack:    make([]*slicer.AtomicCommitUnit, 0),
			Guardrails:     slicer.DefaultGuardrails(),
			PreferredModel: "gemini-3.8-flash",
			UpdatedAt:      time.Now(),
		},
	}
}

// Get returns a shallow copy of the state.
func (s *StateStore) Get() DaemonState {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.state
}

// Update mutates state using a modifier callback.
func (s *StateStore) Update(fn func(state *DaemonState)) DaemonState {
	s.mu.Lock()
	defer s.mu.Unlock()
	fn(&s.state)
	s.state.UpdatedAt = time.Now()
	return s.state
}

// Reset clears the active stack and restores default guardrails.
func (s *StateStore) Reset() DaemonState {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.state.ActiveStack = make([]*slicer.AtomicCommitUnit, 0)
	s.state.Guardrails = slicer.DefaultGuardrails()
	s.state.UpdatedAt = time.Now()
	return s.state
}

// HandleGetState serves GET /api/state.
func (s *Server) HandleGetState(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	state := s.stateStore.Get()

	// Query live git status if executor is available
	if s.gitExec != nil {
		status, err := s.gitExec.Status(ctx)
		if err == nil && status != nil {
			s.stateStore.Update(func(st *DaemonState) {
				st.Status = status
				st.CurrentBranch = status.CurrentBranch
				st.IsClean = status.IsClean
			})
			state = s.stateStore.Get()
		}
	}

	writeJSON(w, http.StatusOK, state)
}

// HandleUpdateState serves POST /api/state.
func (s *Server) HandleUpdateState(w http.ResponseWriter, r *http.Request) {
	var req struct {
		BaseBranch     *string                  `json:"base_branch,omitempty"`
		Guardrails     *slicer.SlicerGuardrails `json:"guardrails,omitempty"`
		PreferredModel *string                  `json:"preferred_model,omitempty"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSONError(w, http.StatusBadRequest, "Invalid request body: "+err.Error())
		return
	}

	updated := s.stateStore.Update(func(st *DaemonState) {
		if req.BaseBranch != nil {
			st.BaseBranch = *req.BaseBranch
		}
		if req.Guardrails != nil {
			st.Guardrails = *req.Guardrails
		}
		if req.PreferredModel != nil {
			st.PreferredModel = *req.PreferredModel
		}
	})

	s.eventBroker.Broadcast("state_updated", updated)
	writeJSON(w, http.StatusOK, updated)
}

// HandleResetState serves POST /api/reset.
func (s *Server) HandleResetState(w http.ResponseWriter, r *http.Request) {
	resetState := s.stateStore.Reset()

	if s.gitExec != nil {
		status, err := s.gitExec.Status(r.Context())
		if err == nil {
			s.stateStore.Update(func(st *DaemonState) {
				st.Status = status
				st.CurrentBranch = status.CurrentBranch
				st.IsClean = status.IsClean
			})
			resetState = s.stateStore.Get()
		}
	}

	s.eventBroker.Broadcast("state_reset", resetState)
	writeJSON(w, http.StatusOK, resetState)
}
