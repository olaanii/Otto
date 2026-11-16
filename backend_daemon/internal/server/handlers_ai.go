package server

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"

	"otto-daemon/internal/git"
	"otto-daemon/internal/llm"
	"otto-daemon/internal/slicer"
)

// AIRefineRequest specifies parameters for AI-powered stack optimization.
type AIRefineRequest struct {
	Prompt         string `json:"prompt,omitempty"`
	PreferredModel string `json:"preferred_model,omitempty"`
	BaseRef        string `json:"base_ref,omitempty"`
}

// AIRefineResponse returns the refined stack along with fallback metadata.
type AIRefineResponse struct {
	Stack        []*slicer.AtomicCommitUnit `json:"stack"`
	FallbackUsed bool                       `json:"fallback_used"`
	FallbackMsg  string                     `json:"fallback_reason,omitempty"`
	ModelUsed    string                     `json:"model_used,omitempty"`
	RefinedAt    time.Time                  `json:"refined_at"`
}

type aiCommitProposal struct {
	Type      string   `json:"type"`
	Scope     string   `json:"scope"`
	Summary   string   `json:"summary"`
	Files     []string `json:"files"`
	Rationale []string `json:"rationale"`
}

// HandleAIRefineStack serves POST /api/ai/refine-stack.
func (s *Server) HandleAIRefineStack(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	var req AIRefineRequest
	_ = json.NewDecoder(r.Body).Decode(&req)

	baseRef := req.BaseRef
	if baseRef == "" {
		baseRef = s.stateStore.Get().BaseBranch
	}
	if baseRef == "" {
		baseRef = "main"
	}

	diffReport, err := s.gitExec.Diff(ctx, false, baseRef)
	if err != nil {
		writeJSONError(w, http.StatusInternalServerError, "Failed to inspect git diff: "+err.Error())
		return
	}

	state := s.stateStore.Get()
	deterministicSlicer := slicer.NewASTSlicer(&state.Guardrails)

	if len(diffReport.Files) == 0 {
		writeJSON(w, http.StatusOK, AIRefineResponse{
			Stack:     []*slicer.AtomicCommitUnit{},
			RefinedAt: time.Now(),
		})
		return
	}

	preferredModel := req.PreferredModel
	if preferredModel == "" {
		preferredModel = state.PreferredModel
	}

	// Try AI refinement if gateway is configured
	var (
		refinedStack []*slicer.AtomicCommitUnit
		fallbackUsed = false
		fallbackMsg  = ""
		modelUsed    = ""
	)

	if s.llmGateway != nil {
		aiUnits, aiModel, aiErr := s.refineWithLLM(ctx, diffReport, baseRef, preferredModel, req.Prompt, state.Guardrails)
		if aiErr == nil && len(aiUnits) > 0 {
			refinedStack = aiUnits
			modelUsed = aiModel
		} else {
			fallbackUsed = true
			if aiErr != nil {
				fallbackMsg = aiErr.Error()
			} else {
				fallbackMsg = "LLM returned empty stack proposals"
			}
		}
	} else {
		fallbackUsed = true
		fallbackMsg = "No LLM gateway configured"
	}

	// Fallback to deterministic AST slicer
	if fallbackUsed || len(refinedStack) == 0 {
		refinedStack = deterministicSlicer.SliceDiffReport(diffReport, baseRef)
	}

	s.stateStore.Update(func(st *DaemonState) {
		st.ActiveStack = refinedStack
		st.LastAnalyzedAt = time.Now()
	})

	resp := AIRefineResponse{
		Stack:        refinedStack,
		FallbackUsed: fallbackUsed,
		FallbackMsg:  fallbackMsg,
		ModelUsed:    modelUsed,
		RefinedAt:    time.Now(),
	}

	s.eventBroker.Broadcast("stack_updated", resp)
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) refineWithLLM(
	ctx context.Context,
	diff *git.DiffReport,
	baseBranch string,
	preferredProvider string,
	userPrompt string,
	guardrails slicer.SlicerGuardrails,
) ([]*slicer.AtomicCommitUnit, string, error) {

	// Build compact diff summary
	var fileSummaries []string
	for _, f := range diff.Files {
		fileSummaries = append(fileSummaries, fmt.Sprintf("- %s (+%d/-%d LOC, intent: %s, scope: %s)",
			f.NewPath, f.Additions, f.Deletions, f.Intent, f.Scope))
	}

	systemInstruction := fmt.Sprintf(`You are Otto's Principal Systems Architect.
Your task is to decompose the git diff into an optimal stack of atomic, single-responsibility commits.
Guardrails:
1. Max %d LOC per commit.
2. Max %d files per commit.
3. Isolate architecture docs/plans into docs(plans) commits first.
4. Couple test files with their implementation code where possible.
5. Format Conventional Commits 1.0 (imperative, <=68 chars header, no trailing period).

Respond ONLY with a JSON array matching:
[
  {
    "type": "feat|fix|refactor|test|docs|chore|perf",
    "scope": "domain_scope",
    "summary": "imperative summary in lowercase without period",
    "files": ["file1.go", "file2.go"],
    "rationale": ["why this commit exists", "impact"]
  }
]`, guardrails.MaxLOCPerCommit, guardrails.MaxFilesPerCommit)

	userContent := fmt.Sprintf("Changed files:\n%s\n\nTotal LOC: %d", strings.Join(fileSummaries, "\n"), diff.TotalLOC)
	if userPrompt != "" {
		userContent += fmt.Sprintf("\nUser Instructions: %s", userPrompt)
	}

	llmReq := llm.CompletionRequest{
		Messages: []llm.Message{
			{Role: "system", Content: systemInstruction},
			{Role: "user", Content: userContent},
		},
		Temperature: 0.2,
		JSONMode:    true,
	}

	completion, err := s.llmGateway.GenerateWithFallback(ctx, preferredProvider, llmReq)
	if err != nil {
		return nil, "", err
	}

	rawJSON := cleanJSONBlock(completion.Content)
	var proposals []aiCommitProposal
	if err := json.Unmarshal([]byte(rawJSON), &proposals); err != nil {
		return nil, completion.Model, fmt.Errorf("failed to parse AI JSON proposal: %w", err)
	}

	if len(proposals) == 0 {
		return nil, completion.Model, fmt.Errorf("LLM produced 0 proposals")
	}

	fileMap := make(map[string]*git.FileDiff)
	for _, f := range diff.Files {
		fileMap[f.NewPath] = f
		if f.OldPath != "" {
			fileMap[f.OldPath] = f
		}
	}

	var units []*slicer.AtomicCommitUnit
	currentBase := baseBranch

	for i, prop := range proposals {
		idx := i + 1
		header := slicer.FormatHeader(prop.Type, prop.Scope, prop.Summary)
		bullets := prop.Rationale
		if len(bullets) == 0 {
			bullets = slicer.GenerateRationaleBullets(prop.Type, prop.Scope, prop.Files, 0, "")
		}
		fullMsg := slicer.BuildFullCommitMessage(header, bullets)

		branchSlug := strings.ToLower(fmt.Sprintf("%s-%s", prop.Type, prop.Scope))
		branchSlug = strings.ReplaceAll(branchSlug, "/", "-")
		branchName := fmt.Sprintf("otto/%d-%s", idx, branchSlug)

		var hunks []git.Hunk
		loc := 0
		for _, fp := range prop.Files {
			if fd, ok := fileMap[fp]; ok {
				loc += fd.LOC
				hunks = append(hunks, fd.Hunks...)
			}
		}

		unit := &slicer.AtomicCommitUnit{
			Index:       idx,
			BranchName:  branchName,
			BaseBranch:  currentBase,
			Header:      header,
			Type:        prop.Type,
			Scope:       prop.Scope,
			Summary:     prop.Summary,
			FullMessage: fullMsg,
			Files:       prop.Files,
			LOC:         loc,
			Hunks:       hunks,
			Rationale:   bullets,
			PRTitle:     header,
		}

		units = append(units, unit)
		currentBase = branchName
	}

	return units, completion.Model, nil
}

func cleanJSONBlock(content string) string {
	content = strings.TrimSpace(content)
	if strings.HasPrefix(content, "```json") {
		content = strings.TrimPrefix(content, "```json")
		content = strings.TrimSuffix(content, "```")
	} else if strings.HasPrefix(content, "```") {
		content = strings.TrimPrefix(content, "```")
		content = strings.TrimSuffix(content, "```")
	}
	return strings.TrimSpace(content)
}
