package server

import (
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"otto-daemon/internal/git"
	"otto-daemon/internal/github"
	"otto-daemon/internal/slicer"
)

// AnalyzeRequest specifies parameters for diff and stack analysis.
type AnalyzeRequest struct {
	BaseRef string `json:"base_ref,omitempty"`
	Staged  bool   `json:"staged,omitempty"`
}

// AnalyzeResponse contains the diff report and sliced micro-PR stack.
type AnalyzeResponse struct {
	Report      *git.DiffReport            `json:"report"`
	ActiveStack []*slicer.AtomicCommitUnit `json:"active_stack"`
	AnalyzedAt  time.Time                  `json:"analyzed_at"`
}

// HandleGitAnalyze serves POST /api/git/analyze.
func (s *Server) HandleGitAnalyze(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	var req AnalyzeRequest
	_ = json.NewDecoder(r.Body).Decode(&req)

	baseRef := req.BaseRef
	if baseRef == "" {
		baseRef = s.stateStore.Get().BaseBranch
	}
	if baseRef == "" {
		baseRef = "main"
	}

	diffReport, err := s.gitExec.Diff(ctx, req.Staged, baseRef)
	if err != nil {
		writeJSONError(w, http.StatusInternalServerError, "Failed to analyze git diff: "+err.Error())
		return
	}

	state := s.stateStore.Get()
	astSlicer := slicer.NewASTSlicer(&state.Guardrails)
	stack := astSlicer.SliceDiffReport(diffReport, baseRef)

	s.stateStore.Update(func(st *DaemonState) {
		st.ActiveStack = stack
		st.LastAnalyzedAt = time.Now()
	})

	resp := AnalyzeResponse{
		Report:      diffReport,
		ActiveStack: stack,
		AnalyzedAt:  time.Now(),
	}

	s.eventBroker.Broadcast("stack_updated", resp)
	writeJSON(w, http.StatusOK, resp)
}

// HandleGitSplit serves POST /api/git/split.
func (s *Server) HandleGitSplit(w http.ResponseWriter, r *http.Request) {
	var req struct {
		FilePath string `json:"file_path"`
		MaxLOC   int    `json:"max_loc,omitempty"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.FilePath == "" {
		writeJSONError(w, http.StatusBadRequest, "Invalid file_path for split")
		return
	}

	report, err := s.gitExec.Diff(r.Context(), false, "")
	if err != nil {
		writeJSONError(w, http.StatusInternalServerError, err.Error())
		return
	}

	var targetFile *git.FileDiff
	for _, f := range report.Files {
		if f.NewPath == req.FilePath || f.OldPath == req.FilePath {
			targetFile = f
			break
		}
	}

	if targetFile == nil {
		writeJSONError(w, http.StatusNotFound, "File diff not found in current changes: "+req.FilePath)
		return
	}

	maxLOC := req.MaxLOC
	if maxLOC <= 0 {
		maxLOC = s.stateStore.Get().Guardrails.MaxLOCPerCommit
	}

	singleSlicer := slicer.NewASTSlicer(&slicer.SlicerGuardrails{
		MaxLOCPerCommit:   maxLOC,
		MaxFilesPerCommit: 1,
	})

	miniReport := &git.DiffReport{Files: []*git.FileDiff{targetFile}}
	units := singleSlicer.SliceDiffReport(miniReport, s.stateStore.Get().BaseBranch)

	writeJSON(w, http.StatusOK, map[string]any{
		"file_path": req.FilePath,
		"units":     units,
	})
}

// HandleGitRebase serves POST /api/git/rebase.
func (s *Server) HandleGitRebase(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	var req struct {
		BaseBranch string `json:"base_branch,omitempty"`
		DryRun     bool   `json:"dry_run,omitempty"`
	}
	_ = json.NewDecoder(r.Body).Decode(&req)

	baseBranch := req.BaseBranch
	if baseBranch == "" {
		baseBranch = s.stateStore.Get().BaseBranch
	}
	if baseBranch == "" {
		baseBranch = "main"
	}

	state := s.stateStore.Get()
	if len(state.ActiveStack) == 0 {
		writeJSONError(w, http.StatusBadRequest, "No active stack to rebase; run /api/git/analyze first")
		return
	}

	graph := git.NewRebaseGraph(baseBranch)
	for _, unit := range state.ActiveStack {
		graph.AddNode(&git.PRNode{
			Branch:       unit.BranchName,
			BaseBranch:   unit.BaseBranch,
			Title:        unit.Header,
			ChangedFiles: unit.Files,
		})
	}

	conflicts := graph.DetectConflicts(nil)
	steps, err := graph.PlanRebase()
	if err != nil {
		writeJSONError(w, http.StatusConflict, "Cannot plan rebase: "+err.Error())
		return
	}

	if req.DryRun || len(conflicts) > 0 {
		writeJSON(w, http.StatusOK, map[string]any{
			"status":    "planned",
			"conflicts": conflicts,
			"steps":     steps,
		})
		return
	}

	// Execute rebase steps
	for _, step := range steps {
		if step.Action == "rebase" {
			if err := s.gitExec.Checkout(ctx, step.Branch, false); err != nil {
				writeJSONError(w, http.StatusInternalServerError, fmt.Sprintf("Failed to checkout %s: %v", step.Branch, err))
				return
			}
			if err := s.gitExec.Rebase(ctx, step.OntoBranch); err != nil {
				_ = s.gitExec.RebaseAbort(ctx)
				writeJSONError(w, http.StatusConflict, fmt.Sprintf("Conflict rebasing %s onto %s: %v", step.Branch, step.OntoBranch, err))
				return
			}
		}
	}

	s.eventBroker.Broadcast("git_operation", map[string]string{
		"operation": "rebase",
		"status":    "completed",
		"base":      baseBranch,
	})

	writeJSON(w, http.StatusOK, map[string]any{
		"status": "success",
		"steps":  steps,
	})
}

// HandleGitPushStack serves POST /api/git/push-stack.
func (s *Server) HandleGitPushStack(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	var req struct {
		Remote    string `json:"remote,omitempty"`
		Draft     bool   `json:"draft,omitempty"`
		CreatePRs bool   `json:"create_prs,omitempty"`
	}
	_ = json.NewDecoder(r.Body).Decode(&req)

	remote := req.Remote
	if remote == "" {
		remote = "origin"
	}

	state := s.stateStore.Get()
	if len(state.ActiveStack) == 0 {
		writeJSONError(w, http.StatusBadRequest, "No active stack to push; run /api/git/analyze first")
		return
	}

	type pushedResult struct {
		Branch    string              `json:"branch"`
		Base      string              `json:"base"`
		Header    string              `json:"header"`
		PR        *github.PullRequest `json:"pr,omitempty"`
		CommitSHA string              `json:"commit_sha,omitempty"`
	}

	var results []pushedResult
	var stackItems []github.StackPRItem

	// Phase 1: Checkout branches, commit, push
	for _, unit := range state.ActiveStack {
		// Create or switch branch
		_ = s.gitExec.Checkout(ctx, unit.BranchName, true)

		// Commit scoped files
		sha, commitErr := s.gitExec.Commit(ctx, unit.FullMessage, unit.Files)
		if commitErr != nil {
			// If already committed or clean, grab current SHA
			currSHA, _ := s.gitExec.CurrentBranch(ctx)
			sha = currSHA
		}

		// Push with force-with-lease
		if err := s.gitExec.Push(ctx, remote, unit.BranchName, true); err != nil {
			writeJSONError(w, http.StatusInternalServerError, fmt.Sprintf("Failed to push branch %s: %v", unit.BranchName, err))
			return
		}

		res := pushedResult{
			Branch:    unit.BranchName,
			Base:      unit.BaseBranch,
			Header:    unit.Header,
			CommitSHA: sha,
		}

		// Phase 2: Create stacked PR if requested and GitHub client is configured
		if req.CreatePRs && s.githubClient != nil {
			pr, err := s.githubClient.CreateStackedPR(ctx, unit.Header, unit.FullMessage, unit.BranchName, unit.BaseBranch, req.Draft)
			if err == nil && pr != nil {
				res.PR = pr
				stackItems = append(stackItems, github.StackPRItem{
					Number:  pr.Number,
					Title:   pr.Title,
					Branch:  unit.BranchName,
					HTMLURL: pr.HTMLURL,
				})
			}
		}

		results = append(results, res)
	}

	s.eventBroker.Broadcast("git_operation", map[string]any{
		"operation": "push-stack",
		"remote":    remote,
		"branches":  len(results),
	})

	writeJSON(w, http.StatusOK, map[string]any{
		"status":  "success",
		"pushed":  results,
		"total":   len(results),
	})
}
