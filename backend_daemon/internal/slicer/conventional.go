package slicer

import (
	"fmt"
	"strings"
	"unicode"
)

// Imperative verb normalization map
var imperativeMap = map[string]string{
	"adds":         "add",
	"added":        "add",
	"adding":       "add",
	"fixes":        "fix",
	"fixed":        "fix",
	"fixing":       "fix",
	"updates":      "update",
	"updated":      "update",
	"updating":     "update",
	"implements":   "implement",
	"implemented": "implement",
	"implementing": "implement",
	"removes":      "remove",
	"removed":      "remove",
	"removing":     "remove",
	"refactors":    "refactor",
	"refactored":   "refactor",
	"refactoring":  "refactor",
	"creates":      "create",
	"created":      "create",
	"creating":     "create",
	"optimizes":    "optimize",
	"optimized":    "optimize",
	"optimizing":   "optimize",
	"ensures":      "ensure",
	"ensured":      "ensure",
	"ensuring":     "ensure",
	"handles":      "handle",
	"handled":      "handle",
	"handling":     "handle",
	"supports":     "support",
	"supported":    "support",
	"supporting":   "support",
}

// FormatHeader formats a Conventional Commit 1.0 header:
// - Format: <type>(<scope>): <imperative description>
// - Imperative tone
// - <= 68 characters
// - No trailing period
func FormatHeader(commitType, scope, summary string) string {
	commitType = strings.TrimSpace(strings.ToLower(commitType))
	if commitType == "" {
		commitType = "feat"
	}

	scope = strings.TrimSpace(strings.ToLower(scope))
	// Remove forbidden characters in scope
	scope = strings.Map(func(r rune) rune {
		if unicode.IsLetter(r) || unicode.IsDigit(r) || r == '-' || r == '_' {
			return r
		}
		return -1
	}, scope)

	summary = strings.TrimSpace(summary)
	// Strip trailing punctuation
	summary = strings.TrimRight(summary, ".!?:;")

	// Enforce imperative verb on first word
	words := strings.Fields(summary)
	if len(words) > 0 {
		first := strings.ToLower(words[0])
		if imp, ok := imperativeMap[first]; ok {
			words[0] = imp
		} else {
			// Ensure lowercase first char
			r := []rune(words[0])
			if len(r) > 0 {
				r[0] = unicode.ToLower(r[0])
				words[0] = string(r)
			}
		}
		summary = strings.Join(words, " ")
	}

	var prefix string
	if scope != "" {
		prefix = fmt.Sprintf("%s(%s): ", commitType, scope)
	} else {
		prefix = fmt.Sprintf("%s: ", commitType)
	}

	header := prefix + summary
	const maxLen = 68

	if len(header) > maxLen {
		allowedSummaryLen := maxLen - len(prefix)
		if allowedSummaryLen < 15 {
			// If prefix is too long, drop scope
			prefix = fmt.Sprintf("%s: ", commitType)
			allowedSummaryLen = maxLen - len(prefix)
		}

		if len(summary) > allowedSummaryLen {
			// Truncate at word boundary
			truncated := summary[:allowedSummaryLen]
			lastSpace := strings.LastIndex(truncated, " ")
			if lastSpace > 10 {
				truncated = truncated[:lastSpace]
			}
			header = prefix + strings.TrimRight(truncated, ".!?:; ")
		}
	}

	return header
}

// GenerateRationaleBullets creates structured rationale bullet points for a commit.
func GenerateRationaleBullets(intent, scope string, files []string, loc int, contextSummary string) []string {
	var bullets []string

	switch intent {
	case "feat":
		bullets = append(bullets, fmt.Sprintf("Implement %s functionality in %d LOC across %d files", scope, loc, len(files)))
	case "fix":
		bullets = append(bullets, fmt.Sprintf("Resolve edge-case / defect in %s module", scope))
	case "refactor":
		bullets = append(bullets, fmt.Sprintf("Streamline %s architecture without breaking existing behavior", scope))
	case "perf":
		bullets = append(bullets, fmt.Sprintf("Optimize throughput and reduce memory overhead in %s", scope))
	case "test":
		bullets = append(bullets, fmt.Sprintf("Add unit test coverage and regression guards for %s", scope))
	case "docs":
		bullets = append(bullets, fmt.Sprintf("Document %s architectural decisions and workflows", scope))
	default:
		bullets = append(bullets, fmt.Sprintf("Update %s configuration and dependencies", scope))
	}

	if contextSummary != "" {
		bullets = append(bullets, contextSummary)
	}

	if len(files) > 0 {
		fileList := strings.Join(files, ", ")
		if len(fileList) > 60 {
			fileList = fmt.Sprintf("%d files (%s...)", len(files), files[0])
		}
		bullets = append(bullets, fmt.Sprintf("Scoped to: %s", fileList))
	}

	return bullets
}

// BuildFullCommitMessage combines header and rationale bullets into standard git message.
func BuildFullCommitMessage(header string, bullets []string) string {
	if len(bullets) == 0 {
		return header
	}

	var sb strings.Builder
	sb.WriteString(header)
	sb.WriteString("\n\n")

	for _, b := range bullets {
		clean := strings.TrimSpace(b)
		if !strings.HasPrefix(clean, "- ") {
			clean = "- " + clean
		}
		sb.WriteString(clean)
		sb.WriteString("\n")
	}

	return strings.TrimRight(sb.String(), "\n")
}
