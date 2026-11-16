package slicer

import (
	"fmt"
	"path/filepath"
	"strings"

	"otto-daemon/internal/git"
)

// SlicerGuardrails defines constraints for atomic commits.
type SlicerGuardrails struct {
	MaxLOCPerCommit   int `json:"max_loc_per_commit"`
	MaxFilesPerCommit int `json:"max_files_per_commit"`
	CoupleTests       bool `json:"couple_tests"`
	IsolateDocs       bool `json:"isolate_docs"`
}

// DefaultGuardrails provides Otto's strict atomic PR guardrails.
func DefaultGuardrails() SlicerGuardrails {
	return SlicerGuardrails{
		MaxLOCPerCommit:   80,
		MaxFilesPerCommit: 3,
		CoupleTests:       true,
		IsolateDocs:       true,
	}
}

// AtomicCommitUnit represents an isolated, single-responsibility commit.
type AtomicCommitUnit struct {
	Index       int        `json:"index"`
	BranchName  string     `json:"branch_name"`
	BaseBranch  string     `json:"base_branch"`
	Header      string     `json:"header"`
	Type        string     `json:"type"`
	Scope       string     `json:"scope"`
	Summary     string     `json:"summary"`
	FullMessage string     `json:"full_message"`
	Files       []string   `json:"files"`
	LOC         int        `json:"loc"`
	Hunks       []git.Hunk `json:"hunks"`
	Rationale   []string   `json:"rationale"`
	PRTitle     string     `json:"pr_title"`
}

// ASTSlicer decomposes git diff reports into atomic commit stacks.
type ASTSlicer struct {
	guardrails SlicerGuardrails
}

// NewASTSlicer creates an ASTSlicer with specified or default guardrails.
func NewASTSlicer(g *SlicerGuardrails) *ASTSlicer {
	if g == nil {
		def := DefaultGuardrails()
		g = &def
	}
	return &ASTSlicer{
		guardrails: *g,
	}
}

// SliceDiffReport splits a DiffReport into an ordered stack of AtomicCommitUnits.
func (s *ASTSlicer) SliceDiffReport(report *git.DiffReport, baseBranch string) []*AtomicCommitUnit {
	if baseBranch == "" {
		baseBranch = "main"
	}

	if report == nil || len(report.Files) == 0 {
		return []*AtomicCommitUnit{}
	}

	var (
		docFiles  []*git.FileDiff
		testFiles = make(map[string]*git.FileDiff) // key: impl base or test path
		implFiles []*git.FileDiff
	)

	// Step 1: Categorize files
	for _, f := range report.Files {
		path := f.NewPath
		if path == "" {
			path = f.OldPath
		}

		if s.guardrails.IsolateDocs && isDocPlan(path) {
			docFiles = append(docFiles, f)
		} else if isTestFile(path) {
			implKey := getCorrespondingImplKey(path)
			testFiles[implKey] = f
		} else {
			implFiles = append(implFiles, f)
		}
	}

	var units []*AtomicCommitUnit
	unitIndex := 1
	currentBase := baseBranch

	// Step 2: Emit isolated doc plan commits first
	if len(docFiles) > 0 {
		docBatches := s.batchFiles(docFiles)
		for _, batch := range docBatches {
			unit := s.createCommitUnit(unitIndex, "docs", "plans", "add architecture plan", batch, currentBase)
			units = append(units, unit)
			currentBase = unit.BranchName
			unitIndex++
		}
	}

	// Step 3: Process implementation files, coupling with tests when possible
	usedTestPaths := make(map[string]bool)

	for _, impl := range implFiles {
		path := impl.NewPath
		if path == "" {
			path = impl.OldPath
		}
		implKey := getImplKey(path)
		testFile, hasMatchingTest := testFiles[implKey]

		// Check if we can couple impl + test
		canCouple := s.guardrails.CoupleTests &&
			hasMatchingTest &&
			!usedTestPaths[testFile.NewPath] &&
			(impl.LOC+testFile.LOC) <= s.guardrails.MaxLOCPerCommit

		if canCouple {
			usedTestPaths[testFile.NewPath] = true
			coupledBatch := []*git.FileDiff{impl, testFile}
			scope := impl.Scope
			if scope == "" {
				scope = git.ExtractModuleScope(path)
			}
			intent := string(impl.Intent)
			if intent == "" {
				intent = "feat"
			}

			summary := fmt.Sprintf("implement %s with tests", scope)
			unit := s.createCommitUnit(unitIndex, intent, scope, summary, coupledBatch, currentBase)
			units = append(units, unit)
			currentBase = unit.BranchName
			unitIndex++
		} else {
			// Single impl commit or chunked if > MaxLOC
			chunks := s.splitFileDiff(impl)
			for _, chunk := range chunks {
				scope := chunk.Scope
				intent := string(chunk.Intent)
				summary := fmt.Sprintf("implement %s logic", scope)
				unit := s.createCommitUnit(unitIndex, intent, scope, summary, []*git.FileDiff{chunk}, currentBase)
				units = append(units, unit)
				currentBase = unit.BranchName
				unitIndex++
			}

			// If test file exists but couldn't be coupled due to LOC, add it right after
			if hasMatchingTest && !usedTestPaths[testFile.NewPath] {
				usedTestPaths[testFile.NewPath] = true
				testScope := testFile.Scope
				testSummary := fmt.Sprintf("add unit tests for %s", testScope)
				unit := s.createCommitUnit(unitIndex, "test", testScope, testSummary, []*git.FileDiff{testFile}, currentBase)
				units = append(units, unit)
				currentBase = unit.BranchName
				unitIndex++
			}
		}
	}

	// Step 4: Any standalone tests remaining without matched impl
	for _, testFile := range testFiles {
		if !usedTestPaths[testFile.NewPath] {
			scope := testFile.Scope
			summary := fmt.Sprintf("add test coverage for %s", scope)
			unit := s.createCommitUnit(unitIndex, "test", scope, summary, []*git.FileDiff{testFile}, currentBase)
			units = append(units, unit)
			currentBase = unit.BranchName
			unitIndex++
		}
	}

	return units
}

func (s *ASTSlicer) batchFiles(files []*git.FileDiff) [][]*git.FileDiff {
	var batches [][]*git.FileDiff
	var current []*git.FileDiff
	currentLOC := 0

	for _, f := range files {
		if len(current) > 0 && (len(current) >= s.guardrails.MaxFilesPerCommit || currentLOC+f.LOC > s.guardrails.MaxLOCPerCommit) {
			batches = append(batches, current)
			current = []*git.FileDiff{}
			currentLOC = 0
		}
		current = append(current, f)
		currentLOC += f.LOC
	}

	if len(current) > 0 {
		batches = append(batches, current)
	}
	return batches
}

func (s *ASTSlicer) splitFileDiff(fd *git.FileDiff) []*git.FileDiff {
	if fd.LOC <= s.guardrails.MaxLOCPerCommit || len(fd.Hunks) <= 1 {
		return []*git.FileDiff{fd}
	}

	// Split hunks across multiple units if necessary
	var chunks []*git.FileDiff
	var currentHunks []git.Hunk
	currentLOC := 0

	for _, hunk := range fd.Hunks {
		hunkLOC := hunk.Additions + hunk.Deletions
		if len(currentHunks) > 0 && currentLOC+hunkLOC > s.guardrails.MaxLOCPerCommit {
			chunks = append(chunks, &git.FileDiff{
				OldPath:   fd.OldPath,
				NewPath:   fd.NewPath,
				Status:    fd.Status,
				Scope:     fd.Scope,
				Intent:    fd.Intent,
				LOC:       currentLOC,
				Hunks:     currentHunks,
			})
			currentHunks = []git.Hunk{}
			currentLOC = 0
		}
		currentHunks = append(currentHunks, hunk)
		currentLOC += hunkLOC
	}

	if len(currentHunks) > 0 {
		chunks = append(chunks, &git.FileDiff{
			OldPath:   fd.OldPath,
			NewPath:   fd.NewPath,
			Status:    fd.Status,
			Scope:     fd.Scope,
			Intent:    fd.Intent,
			LOC:       currentLOC,
			Hunks:     currentHunks,
		})
	}

	return chunks
}

func (s *ASTSlicer) createCommitUnit(index int, commitType, scope, summary string, files []*git.FileDiff, baseBranch string) *AtomicCommitUnit {
	header := FormatHeader(commitType, scope, summary)

	var filePaths []string
	var hunks []git.Hunk
	totalLOC := 0

	for _, f := range files {
		path := f.NewPath
		if path == "" {
			path = f.OldPath
		}
		filePaths = append(filePaths, path)
		totalLOC += f.LOC
		hunks = append(hunks, f.Hunks...)
	}

	bullets := GenerateRationaleBullets(commitType, scope, filePaths, totalLOC, "")
	fullMsg := BuildFullCommitMessage(header, bullets)

	branchSlug := strings.ToLower(fmt.Sprintf("%s-%s", commitType, scope))
	branchSlug = strings.ReplaceAll(branchSlug, "/", "-")
	branchSlug = strings.ReplaceAll(branchSlug, "_", "-")
	branchName := fmt.Sprintf("otto/%d-%s", index, branchSlug)

	return &AtomicCommitUnit{
		Index:       index,
		BranchName:  branchName,
		BaseBranch:  baseBranch,
		Header:      header,
		Type:        commitType,
		Scope:       scope,
		Summary:     summary,
		FullMessage: fullMsg,
		Files:       filePaths,
		LOC:         totalLOC,
		Hunks:       hunks,
		Rationale:   bullets,
		PRTitle:     header,
	}
}

func isDocPlan(path string) bool {
	lower := strings.ToLower(path)
	if strings.HasPrefix(lower, "docs/") ||
		strings.Contains(lower, "plan") ||
		strings.HasSuffix(lower, ".md") {
		return true
	}
	return false
}

func isTestFile(path string) bool {
	lower := strings.ToLower(path)
	return strings.Contains(lower, "_test.") ||
		strings.Contains(lower, ".test.") ||
		strings.Contains(lower, ".spec.") ||
		strings.HasPrefix(lower, "test/") ||
		strings.Contains(lower, "/test/")
}

func getCorrespondingImplKey(testPath string) string {
	clean := filepath.ToSlash(filepath.Clean(testPath))
	clean = strings.TrimPrefix(clean, "test/")
	clean = strings.TrimPrefix(clean, "tests/")

	base := filepath.Base(clean)
	ext := filepath.Ext(base)

	noExt := strings.TrimSuffix(base, ext)
	noExt = strings.TrimSuffix(noExt, "_test")
	noExt = strings.TrimSuffix(noExt, ".test")
	noExt = strings.TrimSuffix(noExt, ".spec")

	return noExt
}

func getImplKey(implPath string) string {
	base := filepath.Base(implPath)
	ext := filepath.Ext(base)
	return strings.TrimSuffix(base, ext)
}
