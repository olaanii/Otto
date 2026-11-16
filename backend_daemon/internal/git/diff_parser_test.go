package git

import (
	"testing"
)

const sampleDiff = `diff --git a/internal/auth/clerk_middleware.go b/internal/auth/clerk_middleware.go
index 1111111..2222222 100644
--- a/internal/auth/clerk_middleware.go
+++ b/internal/auth/clerk_middleware.go
@@ -10,6 +10,8 @@ package auth
 import (
 	"context"
 	"net/http"
+	"sync"
+	"time"
 )
 
 func Middleware() {
@@ -25,4 +27,5 @@ func Middleware() {
-	return nil
+	// fix nil check bug
+	if ctx == nil { return nil }
 }
diff --git a/docs/plans/stacked_prs.md b/docs/plans/stacked_prs.md
new file mode 100644
--- /dev/null
+++ b/docs/plans/stacked_prs.md
@@ -0,0 +1,5 @@
+# Stacked PR Plan
+Phase 1: AST Slicing
+Phase 2: Kahn Rebase
+Phase 3: GitHub Sync
+Phase 4: Conventional Commits
diff --git a/internal/auth/clerk_middleware_test.go b/internal/auth/clerk_middleware_test.go
new file mode 100644
--- /dev/null
+++ b/internal/auth/clerk_middleware_test.go
@@ -0,0 +1,6 @@
+package auth_test
+import "testing"
+func TestAuth(t *testing.T) {
+	// run test suite
+}
`

func TestParseDiff_Metrics(t *testing.T) {
	report := ParseDiff(sampleDiff)

	if len(report.Files) != 3 {
		t.Fatalf("expected 3 files, got %d", len(report.Files))
	}

	// File 1: clerk_middleware.go
	f1 := report.Files[0]
	if f1.NewPath != "internal/auth/clerk_middleware.go" {
		t.Errorf("expected path internal/auth/clerk_middleware.go, got %s", f1.NewPath)
	}
	if f1.Additions != 4 {
		t.Errorf("expected 4 additions, got %d", f1.Additions)
	}
	if f1.Deletions != 1 {
		t.Errorf("expected 1 deletion, got %d", f1.Deletions)
	}
	if f1.LOC != 5 {
		t.Errorf("expected 5 LOC, got %d", f1.LOC)
	}
	if len(f1.Hunks) != 2 {
		t.Errorf("expected 2 hunks, got %d", len(f1.Hunks))
	}

	// Scope extraction check
	if f1.Scope != "auth" {
		t.Errorf("expected scope 'auth', got %s", f1.Scope)
	}

	// File 2: docs
	f2 := report.Files[1]
	if f2.Status != FileStatusAdded {
		t.Errorf("expected added status, got %s", f2.Status)
	}
	if f2.Intent != IntentDocs {
		t.Errorf("expected intent docs, got %s", f2.Intent)
	}
	if f2.Scope != "plans" {
		t.Errorf("expected scope plans, got %s", f2.Scope)
	}

	// File 3: test
	f3 := report.Files[2]
	if f3.Intent != IntentTest {
		t.Errorf("expected intent test, got %s", f3.Intent)
	}
}

func TestExtractModuleScope(t *testing.T) {
	tests := []struct {
		path     string
		expected string
	}{
		{"lib/features/auth/login_screen.dart", "auth"},
		{"internal/git/executor.go", "git"},
		{"packages/core/src/index.ts", "core"},
		{"docs/plans/rebase.md", "plans"},
		{"go.mod", "deps"},
		{"pubspec.yaml", "deps"},
		{"README.md", "docs"},
		{".github/workflows/ci.yml", "workflows"},
	}

	for _, tt := range tests {
		actual := ExtractModuleScope(tt.path)
		if actual != tt.expected {
			t.Errorf("ExtractModuleScope(%q) = %q, expected %q", tt.path, actual, tt.expected)
		}
	}
}

func TestClassifyFileIntent(t *testing.T) {
	tests := []struct {
		name     string
		diff     *FileDiff
		expected Intent
	}{
		{
			name: "test file",
			diff: &FileDiff{
				NewPath: "lib/features/auth/auth_test.dart",
			},
			expected: IntentTest,
		},
		{
			name: "doc file",
			diff: &FileDiff{
				NewPath: "docs/architecture.md",
			},
			expected: IntentDocs,
		},
		{
			name: "dependency file",
			diff: &FileDiff{
				NewPath: "go.mod",
			},
			expected: IntentChore,
		},
		{
			name: "fix bug file",
			diff: &FileDiff{
				NewPath:   "lib/main.dart",
				Status:    FileStatusModified,
				Additions: 2,
				Deletions: 1,
				Hunks: []Hunk{
					{
						Lines: []DiffLine{
							{Type: LineAddition, Content: "if (err != nil) { return nil } // fix crash bug"},
						},
					},
				},
			},
			expected: IntentFix,
		},
		{
			name: "perf optimization",
			diff: &FileDiff{
				NewPath:   "internal/cache.go",
				Status:    FileStatusModified,
				Additions: 5,
				Deletions: 2,
				Hunks: []Hunk{
					{
						Lines: []DiffLine{
							{Type: LineAddition, Content: "cachePool.Put(buf) // zero-alloc sync.Pool fastpath"},
						},
					},
				},
			},
			expected: IntentPerf,
		},
	}

	for _, tt := range tests {
		actual := ClassifyFileIntent(tt.diff)
		if actual != tt.expected {
			t.Errorf("ClassifyFileIntent(%s) = %s, expected %s", tt.name, actual, tt.expected)
		}
	}
}
