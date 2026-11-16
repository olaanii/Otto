package git

import (
	"strings"
	"testing"
)

func TestRebaseGraph_TopologicalSort_LinearChain(t *testing.T) {
	graph := NewRebaseGraph("main")

	// Stack: main -> pr-141 -> pr-142 -> pr-143
	graph.AddNode(&PRNode{
		ID:         "141",
		Branch:     "feature/pr-141",
		BaseBranch: "main",
		Title:      "feat(auth): initial clerk setup",
		PRNumber:   141,
	})
	graph.AddNode(&PRNode{
		ID:         "142",
		Branch:     "feature/pr-142",
		BaseBranch: "feature/pr-141",
		Title:      "feat(auth): add middleware token parsing",
		PRNumber:   142,
	})
	graph.AddNode(&PRNode{
		ID:         "143",
		Branch:     "feature/pr-143",
		BaseBranch: "feature/pr-142",
		Title:      "test(auth): add clerk tests",
		PRNumber:   143,
	})

	sorted, err := graph.TopologicalSort()
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}

	if len(sorted) != 3 {
		t.Fatalf("expected 3 nodes, got %d", len(sorted))
	}

	expectedOrder := []string{"feature/pr-141", "feature/pr-142", "feature/pr-143"}
	for i, node := range sorted {
		if node.Branch != expectedOrder[i] {
			t.Errorf("expected sorted[%d] = %s, got %s", i, expectedOrder[i], node.Branch)
		}
	}
}

func TestRebaseGraph_CalculateChain(t *testing.T) {
	graph := NewRebaseGraph("main")

	graph.AddNode(&PRNode{
		Branch:     "feature/141",
		BaseBranch: "main",
		PRNumber:   141,
	})
	graph.AddNode(&PRNode{
		Branch:     "feature/142",
		BaseBranch: "feature/141",
		PRNumber:   142,
	})
	graph.AddNode(&PRNode{
		Branch:     "feature/143",
		BaseBranch: "feature/142",
		PRNumber:   143,
	})

	chain, err := graph.CalculateChain("feature/143")
	if err != nil {
		t.Fatalf("failed to calculate chain: %v", err)
	}

	if len(chain) != 3 {
		t.Fatalf("expected chain length 3, got %d", len(chain))
	}
	if chain[0].PRNumber != 141 || chain[1].PRNumber != 142 || chain[2].PRNumber != 143 {
		t.Errorf("unexpected chain order: %v, %v, %v", chain[0].PRNumber, chain[1].PRNumber, chain[2].PRNumber)
	}
}

func TestRebaseGraph_CycleDetection(t *testing.T) {
	graph := NewRebaseGraph("main")

	// Create a cycle: branch-a -> branch-b -> branch-a
	graph.AddNode(&PRNode{
		Branch:     "branch-a",
		BaseBranch: "branch-b",
	})
	graph.AddNode(&PRNode{
		Branch:     "branch-b",
		BaseBranch: "branch-a",
	})

	_, err := graph.TopologicalSort()
	if err == nil {
		t.Fatalf("expected error detecting cycle, got nil")
	}
	if !strings.Contains(err.Error(), "cycle detected") {
		t.Errorf("expected 'cycle detected' message, got %v", err)
	}
}

func TestRebaseGraph_ConflictDetection(t *testing.T) {
	graph := NewRebaseGraph("main")

	graph.AddNode(&PRNode{
		Branch:       "branch-parent",
		BaseBranch:   "main",
		ChangedFiles: []string{"lib/auth.dart", "lib/main.dart"},
	})
	graph.AddNode(&PRNode{
		Branch:       "branch-child",
		BaseBranch:   "branch-parent",
		ChangedFiles: []string{"lib/auth.dart"},
	})

	conflicts := graph.DetectConflicts(nil)
	if len(conflicts) != 1 {
		t.Fatalf("expected 1 conflict warning, got %d", len(conflicts))
	}
	if conflicts[0].FilePath != "lib/auth.dart" {
		t.Errorf("expected conflict on lib/auth.dart, got %s", conflicts[0].FilePath)
	}
}

func TestRebaseGraph_PlanRebase(t *testing.T) {
	graph := NewRebaseGraph("main")

	graph.AddNode(&PRNode{
		Branch:     "branch-1",
		BaseBranch: "main",
	})
	graph.AddNode(&PRNode{
		Branch:     "branch-2",
		BaseBranch: "branch-1",
	})

	steps, err := graph.PlanRebase()
	if err != nil {
		t.Fatalf("failed to plan rebase: %v", err)
	}

	if len(steps) != 4 { // 2 nodes * 2 steps (rebase + push)
		t.Fatalf("expected 4 steps, got %d", len(steps))
	}
}
