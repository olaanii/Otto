package git

import (
	"bufio"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
)

// Intent represents the semantic classification of a commit or diff.
type Intent string

const (
	IntentFeat     Intent = "feat"
	IntentFix      Intent = "fix"
	IntentRefactor Intent = "refactor"
	IntentTest     Intent = "test"
	IntentDocs     Intent = "docs"
	IntentChore    Intent = "chore"
	IntentPerf     Intent = "perf"
)

// FileStatus represents git file lifecycle status.
type FileStatus string

const (
	FileStatusModified FileStatus = "modified"
	FileStatusAdded    FileStatus = "added"
	FileStatusDeleted  FileStatus = "deleted"
	FileStatusRenamed  FileStatus = "renamed"
	FileStatusBinary   FileStatus = "binary"
)

// DiffLineType indicates line addition, deletion, or context.
type DiffLineType string

const (
	LineAddition DiffLineType = "+"
	LineDeletion DiffLineType = "-"
	LineContext  DiffLineType = " "
)

// DiffLine represents a single line inside a hunk.
type DiffLine struct {
	Type       DiffLineType `json:"type"`
	Content    string       `json:"content"`
	OldLineNum int          `json:"old_line_num,omitempty"`
	NewLineNum int          `json:"new_line_num,omitempty"`
}

// Hunk represents a unified diff hunk (@@ ... @@).
type Hunk struct {
	Header      string     `json:"header"`
	OldStart    int        `json:"old_start"`
	OldLines    int        `json:"old_lines"`
	NewStart    int        `json:"new_start"`
	NewLines    int        `json:"new_lines"`
	SectionInfo string     `json:"section_info,omitempty"`
	Lines       []DiffLine `json:"lines"`
	Additions   int        `json:"additions"`
	Deletions   int        `json:"deletions"`
}

// FileDiff represents changes for an individual file.
type FileDiff struct {
	OldPath   string     `json:"old_path"`
	NewPath   string     `json:"new_path"`
	Status    FileStatus `json:"status"`
	IsBinary  bool       `json:"is_binary"`
	Additions int        `json:"additions"`
	Deletions int        `json:"deletions"`
	LOC       int        `json:"loc"`
	Scope     string     `json:"scope"`
	Intent    Intent     `json:"intent"`
	Hunks     []Hunk     `json:"hunks"`
}

// DiffReport contains overall parsed diff metrics and structured files.
type DiffReport struct {
	Files          []*FileDiff `json:"files"`
	TotalAdditions int         `json:"total_additions"`
	TotalDeletions int         `json:"total_deletions"`
	TotalLOC       int         `json:"total_loc"`
	PrimaryScope   string      `json:"primary_scope"`
	PrimaryIntent  Intent      `json:"primary_intent"`
	Summary        string      `json:"summary"`
}

var (
	diffGitHeaderRegex = regexp.MustCompile(`^diff --git a/(.*) b/(.*)$`)
	hunkHeaderRegex    = regexp.MustCompile(`^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@(?: ?(.*))?$`)
)

// ParseDiff parses standard unified git diff text into structured DiffReport.
func ParseDiff(diffText string) *DiffReport {
	report := &DiffReport{
		Files: make([]*FileDiff, 0),
	}

	if strings.TrimSpace(diffText) == "" {
		return report
	}

	scanner := bufio.NewScanner(strings.NewReader(diffText))
	// Buffer up to 1MB lines for huge diffs
	buf := make([]byte, 1024*1024)
	scanner.Buffer(buf, 10*1024*1024)

	var currentFile *FileDiff
	var currentHunk *Hunk
	oldLinePtr := 0
	newLinePtr := 0

	finalizeHunk := func() {
		if currentHunk != nil && currentFile != nil {
			currentFile.Hunks = append(currentFile.Hunks, *currentHunk)
			currentHunk = nil
		}
	}

	finalizeFile := func() {
		finalizeHunk()
		if currentFile != nil {
			currentFile.LOC = currentFile.Additions + currentFile.Deletions
			currentFile.Scope = ExtractModuleScope(currentFile.NewPath)
			currentFile.Intent = ClassifyFileIntent(currentFile)
			report.Files = append(report.Files, currentFile)
			report.TotalAdditions += currentFile.Additions
			report.TotalDeletions += currentFile.Deletions
			report.TotalLOC += currentFile.LOC
			currentFile = nil
		}
	}

	for scanner.Scan() {
		line := scanner.Text()

		// New file diff header
		if strings.HasPrefix(line, "diff --git ") {
			finalizeFile()

			matches := diffGitHeaderRegex.FindStringSubmatch(line)
			oldPath := ""
			newPath := ""
			if len(matches) == 3 {
				oldPath = matches[1]
				newPath = matches[2]
			}

			currentFile = &FileDiff{
				OldPath: oldPath,
				NewPath: newPath,
				Status:  FileStatusModified,
				Hunks:   make([]Hunk, 0),
			}
			continue
		}

		if currentFile == nil {
			continue
		}

		// File metadata
		if strings.HasPrefix(line, "new file mode ") {
			currentFile.Status = FileStatusAdded
			continue
		} else if strings.HasPrefix(line, "deleted file mode ") {
			currentFile.Status = FileStatusDeleted
			continue
		} else if strings.HasPrefix(line, "similarity index ") {
			currentFile.Status = FileStatusRenamed
			continue
		} else if strings.HasPrefix(line, "rename from ") {
			currentFile.OldPath = strings.TrimPrefix(line, "rename from ")
			currentFile.Status = FileStatusRenamed
			continue
		} else if strings.HasPrefix(line, "rename to ") {
			currentFile.NewPath = strings.TrimPrefix(line, "rename to ")
			currentFile.Status = FileStatusRenamed
			continue
		} else if strings.HasPrefix(line, "Binary files ") || strings.Contains(line, "GIT binary patch") {
			currentFile.IsBinary = true
			currentFile.Status = FileStatusBinary
			continue
		} else if strings.HasPrefix(line, "--- ") {
			p := strings.TrimPrefix(line, "--- ")
			p = strings.TrimPrefix(p, "a/")
			if p != "/dev/null" && currentFile.OldPath == "" {
				currentFile.OldPath = p
			}
			continue
		} else if strings.HasPrefix(line, "+++ ") {
			p := strings.TrimPrefix(line, "+++ ")
			p = strings.TrimPrefix(p, "b/")
			if p != "/dev/null" && currentFile.NewPath == "" {
				currentFile.NewPath = p
			}
			continue
		}

		// Hunk header @@ -X,Y +A,B @@
		if strings.HasPrefix(line, "@@ ") {
			finalizeHunk()

			matches := hunkHeaderRegex.FindStringSubmatch(line)
			if len(matches) >= 4 {
				oldStart, _ := strconv.Atoi(matches[1])
				oldLines := 1
				if matches[2] != "" {
					oldLines, _ = strconv.Atoi(matches[2])
				}
				newStart, _ := strconv.Atoi(matches[3])
				newLines := 1
				if matches[4] != "" {
					newLines, _ = strconv.Atoi(matches[4])
				}
				sectionInfo := ""
				if len(matches) >= 6 {
					sectionInfo = strings.TrimSpace(matches[5])
				}

				oldLinePtr = oldStart
				newLinePtr = newStart

				currentHunk = &Hunk{
					Header:      line,
					OldStart:    oldStart,
					OldLines:    oldLines,
					NewStart:    newStart,
					NewLines:    newLines,
					SectionInfo: sectionInfo,
					Lines:       make([]DiffLine, 0),
				}
			}
			continue
		}

		// Hunk lines
		if currentHunk != nil && len(line) > 0 {
			switch line[0] {
			case '+':
				currentFile.Additions++
				currentHunk.Additions++
				currentHunk.Lines = append(currentHunk.Lines, DiffLine{
					Type:       LineAddition,
					Content:    line[1:],
					NewLineNum: newLinePtr,
				})
				newLinePtr++
			case '-':
				currentFile.Deletions++
				currentHunk.Deletions++
				currentHunk.Lines = append(currentHunk.Lines, DiffLine{
					Type:       LineDeletion,
					Content:    line[1:],
					OldLineNum: oldLinePtr,
				})
				oldLinePtr++
			case ' ':
				currentHunk.Lines = append(currentHunk.Lines, DiffLine{
					Type:       LineContext,
					Content:    line[1:],
					OldLineNum: oldLinePtr,
					NewLineNum: newLinePtr,
				})
				oldLinePtr++
				newLinePtr++
			}
		}
	}

	finalizeFile()

	report.PrimaryScope = determinePrimaryScope(report.Files)
	report.PrimaryIntent = determinePrimaryIntent(report.Files)
	return report
}

// ExtractModuleScope extracts a logical domain scope from a file path.
// e.g. "lib/features/auth/login.dart" -> "auth"
// "internal/git/diff_parser.go" -> "git"
// "docs/plans/stacked_prs.md" -> "plans"
func ExtractModuleScope(path string) string {
	clean := filepath.ToSlash(filepath.Clean(path))
	parts := strings.Split(clean, "/")

	if len(parts) == 0 {
		return "core"
	}

	// Root config / meta files
	if len(parts) == 1 {
		base := parts[0]
		switch {
		case base == "go.mod" || base == "go.sum":
			return "deps"
		case base == "pubspec.yaml" || base == "pubspec.lock":
			return "deps"
		case base == "package.json" || strings.Contains(base, "lock"):
			return "deps"
		case strings.HasSuffix(base, ".md"):
			return "docs"
		case strings.HasPrefix(base, "."):
			return "config"
		default:
			ext := filepath.Ext(base)
			return strings.TrimPrefix(ext, ".")
		}
	}

	// Skip standard boilerplate folders to locate the functional domain
	skipDirs := map[string]bool{
		"lib": true, "src": true, "internal": true, "pkg": true,
		"packages": true, "features": true, "app": true, "modules": true,
		"cmd": true, "test": true, "tests": true,
	}

	for i, part := range parts[:len(parts)-1] {
		lower := strings.ToLower(part)
		if !skipDirs[lower] && lower != "." {
			return lower
		}
		// If nested inside "features" or "packages" or "internal", next part is usually scope
		if (lower == "features" || lower == "packages" || lower == "internal") && i+1 < len(parts)-1 {
			return strings.ToLower(parts[i+1])
		}
	}

	// If inside docs
	if parts[0] == "docs" && len(parts) > 1 {
		return parts[1]
	}

	// Fallback to parent directory of the file
	return strings.ToLower(parts[len(parts)-2])
}

// ClassifyFileIntent classifies intent (feat, fix, refactor, test, docs, chore, perf).
func ClassifyFileIntent(fd *FileDiff) Intent {
	pathLower := strings.ToLower(fd.NewPath)
	if pathLower == "" {
		pathLower = strings.ToLower(fd.OldPath)
	}

	// Tests
	if strings.Contains(pathLower, "_test.") ||
		strings.Contains(pathLower, ".test.") ||
		strings.Contains(pathLower, ".spec.") ||
		strings.HasPrefix(pathLower, "test/") ||
		strings.Contains(pathLower, "/tests/") {
		return IntentTest
	}

	// Documentation
	if strings.HasPrefix(pathLower, "docs/") ||
		strings.HasSuffix(pathLower, ".md") ||
		strings.Contains(pathLower, "license") ||
		strings.Contains(pathLower, "readme") {
		return IntentDocs
	}

	// Build / Tooling / Deps
	if strings.HasSuffix(pathLower, "go.mod") ||
		strings.HasSuffix(pathLower, "go.sum") ||
		strings.HasSuffix(pathLower, "pubspec.yaml") ||
		strings.HasSuffix(pathLower, "package.json") ||
		strings.Contains(pathLower, ".github/") ||
		strings.Contains(pathLower, "dockerfile") {
		return IntentChore
	}

	// Inspect hunk contents for semantic signals
	hasPerfSignal := false
	hasFixSignal := false

	perfKeywords := []string{"cache", "pool", "benchmark", "zerocopy", "alloc", "fastpath", "optimize"}
	fixKeywords := []string{"fix", "bug", "resolve", "nil check", "null check", "panic", "error handling", "corner case"}

	for _, hunk := range fd.Hunks {
		for _, line := range hunk.Lines {
			if line.Type == LineAddition || line.Type == LineDeletion {
				lower := strings.ToLower(line.Content)
				for _, kw := range perfKeywords {
					if strings.Contains(lower, kw) {
						hasPerfSignal = true
					}
				}
				for _, kw := range fixKeywords {
					if strings.Contains(lower, kw) {
						hasFixSignal = true
					}
				}
			}
		}
	}

	if hasPerfSignal {
		return IntentPerf
	}
	if hasFixSignal {
		return IntentFix
	}

	// If file was added with substantial code, it's feat
	if fd.Status == FileStatusAdded {
		return IntentFeat
	}

	// If deletions and additions are roughly equal without new files, it's refactor
	if fd.Additions > 0 && fd.Deletions > 0 {
		diffRatio := float64(fd.Additions) / float64(fd.Deletions)
		if diffRatio > 0.6 && diffRatio < 1.4 && fd.LOC > 30 {
			return IntentRefactor
		}
	}

	// Default to feat if additions predominate, or fix if small change
	if fd.Additions > fd.Deletions {
		return IntentFeat
	}

	return IntentFix
}

func determinePrimaryScope(files []*FileDiff) string {
	if len(files) == 0 {
		return "core"
	}

	counts := make(map[string]int)
	for _, f := range files {
		if f.Scope != "" {
			counts[f.Scope] += f.LOC + 1
		}
	}

	maxScope := "core"
	maxCount := -1
	for scope, cnt := range counts {
		if cnt > maxCount {
			maxCount = cnt
			maxScope = scope
		}
	}
	return maxScope
}

func determinePrimaryIntent(files []*FileDiff) Intent {
	if len(files) == 0 {
		return IntentFeat
	}

	counts := make(map[Intent]int)
	for _, f := range files {
		counts[f.Intent] += f.LOC + 1
	}

	// Prioritize feat or fix over chore/docs if present
	maxIntent := IntentFeat
	maxCount := -1
	for intent, cnt := range counts {
		if cnt > maxCount {
			maxCount = cnt
			maxIntent = intent
		}
	}
	return maxIntent
}
