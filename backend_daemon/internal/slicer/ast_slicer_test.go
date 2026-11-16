package slicer

import (
	"strings"
	"testing"

	"otto-daemon/internal/git"
)

func TestASTSlicer_GuardrailsAndCoupling(t *testing.T) {
	slicer := NewASTSlicer(nil) // uses DefaultGuardrails (80 LOC, 3 files, coupled tests, isolated docs)

	report := &git.DiffReport{
		Files: []*git.FileDiff{
			{
				NewPath:   "docs/plans/rebase.md",
				Status:    git.FileStatusAdded,
				LOC:       25,
				Scope:     "plans",
				Intent:    git.IntentDocs,
			},
			{
				NewPath:   "lib/auth.dart",
				Status:    git.FileStatusModified,
				LOC:       30,
				Scope:     "auth",
				Intent:    git.IntentFeat,
			},
			{
				NewPath:   "test/auth_test.dart",
				Status:    git.FileStatusAdded,
				LOC:       20,
				Scope:     "auth",
				Intent:    git.IntentTest,
			},
		},
	}

	units := slicer.SliceDiffReport(report, "main")

	if len(units) != 2 {
		t.Fatalf("expected 2 units (docs + coupled auth/test), got %d", len(units))
	}

	// First unit must be docs plan
	unit1 := units[0]
	if unit1.Type != "docs" {
		t.Errorf("expected unit 1 type 'docs', got %s", unit1.Type)
	}
	if unit1.Scope != "plans" {
		t.Errorf("expected unit 1 scope 'plans', got %s", unit1.Scope)
	}
	if unit1.BaseBranch != "main" {
		t.Errorf("expected unit 1 base branch 'main', got %s", unit1.BaseBranch)
	}
	if !strings.HasPrefix(unit1.Header, "docs(plans):") {
		t.Errorf("expected docs(plans) header, got %s", unit1.Header)
	}

	// Second unit must couple implementation + test
	unit2 := units[1]
	if unit2.BaseBranch != unit1.BranchName {
		t.Errorf("expected unit 2 base branch %s, got %s", unit1.BranchName, unit2.BaseBranch)
	}
	if len(unit2.Files) != 2 {
		t.Fatalf("expected 2 files coupled in unit 2, got %d", len(unit2.Files))
	}
	if unit2.LOC != 50 {
		t.Errorf("expected unit 2 LOC 50, got %d", unit2.LOC)
	}
}

func TestASTSlicer_ExceedsMaxLOC_SeparatesImplAndTest(t *testing.T) {
	slicer := NewASTSlicer(&SlicerGuardrails{
		MaxLOCPerCommit:   50,
		MaxFilesPerCommit: 3,
		CoupleTests:       true,
		IsolateDocs:       true,
	})

	report := &git.DiffReport{
		Files: []*git.FileDiff{
			{
				NewPath:   "lib/analytics.dart",
				LOC:       40,
				Scope:     "analytics",
				Intent:    git.IntentFeat,
			},
			{
				NewPath:   "test/analytics_test.dart",
				LOC:       30, // 40 + 30 = 70 > 50 MaxLOC
				Scope:     "analytics",
				Intent:    git.IntentTest,
			},
		},
	}

	units := slicer.SliceDiffReport(report, "main")

	if len(units) != 2 {
		t.Fatalf("expected 2 separated units due to LOC budget, got %d", len(units))
	}
	if units[0].Type != "feat" {
		t.Errorf("expected unit 0 feat, got %s", units[0].Type)
	}
	if units[1].Type != "test" {
		t.Errorf("expected unit 1 test, got %s", units[1].Type)
	}
}

func TestFormatHeader(t *testing.T) {
	tests := []struct {
		typ      string
		scope    string
		summary  string
		expected string
	}{
		{
			typ:      "feat",
			scope:    "auth",
			summary:  "adds clerk middleware token verification.",
			expected: "feat(auth): add clerk middleware token verification",
		},
		{
			typ:      "fix",
			scope:    "git",
			summary:  "fixes nil pointer dereference in diff parser!",
			expected: "fix(git): fix nil pointer dereference in diff parser",
		},
		{
			typ:      "docs",
			scope:    "plans",
			summary:  "documenting stacked PR architecture",
			expected: "docs(plans): document stacked PR architecture",
		},
	}

	for _, tt := range tests {
		actual := FormatHeader(tt.typ, tt.scope, tt.summary)
		if actual != tt.expected {
			t.Errorf("FormatHeader(%q, %q, %q) = %q, expected %q", tt.typ, tt.scope, tt.summary, actual, tt.expected)
		}
		if len(actual) > 68 {
			t.Errorf("header length %d exceeds max 68 chars: %s", len(actual), actual)
		}
	}
}
