package git

import (
	"fmt"
	"sort"
	"strings"
)

// PRNode represents a single branch/PR in a stacked PR dependency graph.
type PRNode struct {
	ID         string   `json:"id"`
	Branch     string   `json:"branch"`
	BaseBranch string   `json:"base_branch"`
	Title      string   `json:"title"`
	PRNumber   int      `json:"pr_number,omitempty"`
	CommitSHA  string   `json:"commit_sha,omitempty"`
	Status     string   `json:"status"` // "ready", "merged", "conflict", "draft"
	DependsOn  []string `json:"depends_on"` // Parent branches
	Children   []string `json:"children"`   // Child branches
	ChangedFiles []string `json:"changed_files,omitempty"`
}

// ConflictWarning represents a potential rebase conflict detected between stack branches.
type ConflictWarning struct {
	SourceBranch string `json:"source_branch"`
	TargetBranch string `json:"target_branch"`
	FilePath     string `json:"file_path"`
	Reason       string `json:"reason"`
}

// RebaseStep represents an atomic step in executing a stack rebase.
type RebaseStep struct {
	StepNumber   int    `json:"step_number"`
	Branch       string `json:"branch"`
	OntoBranch   string `json:"onto_branch"`
	Action       string `json:"action"` // "checkout", "rebase", "push"
	Instructions string `json:"instructions"`
}

// RebaseGraph represents the stacked PR dependency tree and rebase planner.
type RebaseGraph struct {
	nodes map[string]*PRNode
	base  string // e.g. "main" or "master"
}

// NewRebaseGraph creates an empty graph with a target default branch.
func NewRebaseGraph(baseBranch string) *RebaseGraph {
	if baseBranch == "" {
		baseBranch = "main"
	}
	return &RebaseGraph{
		nodes: make(map[string]*PRNode),
		base:  baseBranch,
	}
}

// AddNode adds or updates a PR node in the graph.
func (g *RebaseGraph) AddNode(node *PRNode) {
	if node.DependsOn == nil {
		node.DependsOn = make([]string, 0)
	}
	if node.Children == nil {
		node.Children = make([]string, 0)
	}
	if node.BaseBranch == "" {
		node.BaseBranch = g.base
	}
	g.nodes[node.Branch] = node
}

// BuildEdges populates DependsOn and Children based on BaseBranch relations.
func (g *RebaseGraph) BuildEdges() {
	// Clear existing derived edges
	for _, node := range g.nodes {
		node.Children = make([]string, 0)
		node.DependsOn = make([]string, 0)
	}

	for branch, node := range g.nodes {
		parent := node.BaseBranch
		if parent != "" && parent != g.base {
			if parentNode, exists := g.nodes[parent]; exists {
				node.DependsOn = append(node.DependsOn, parent)
				parentNode.Children = append(parentNode.Children, branch)
			}
		}
	}
}

// TopologicalSort executes Kahn's algorithm on the stacked PR graph.
// Returns the correctly ordered slice of branches, or an error if a cycle is detected.
func (g *RebaseGraph) TopologicalSort() ([]*PRNode, error) {
	g.BuildEdges()

	inDegree := make(map[string]int)
	for branch := range g.nodes {
		inDegree[branch] = 0
	}

	for _, node := range g.nodes {
		for _, child := range node.Children {
			inDegree[child]++
		}
	}

	// Collect nodes with in-degree 0 (direct children of main or root)
	queue := make([]string, 0)
	for branch, degree := range inDegree {
		if degree == 0 {
			queue = append(queue, branch)
		}
	}

	// Sort queue for deterministic evaluation
	sort.Strings(queue)

	result := make([]*PRNode, 0, len(g.nodes))
	for len(queue) > 0 {
		currBranch := queue[0]
		queue = queue[1:]

		node := g.nodes[currBranch]
		result = append(result, node)

		for _, childBranch := range node.Children {
			inDegree[childBranch]--
			if inDegree[childBranch] == 0 {
				queue = append(queue, childBranch)
			}
		}
		sort.Strings(queue)
	}

	if len(result) != len(g.nodes) {
		// Identify cycle members
		var cycleMembers []string
		for branch, deg := range inDegree {
			if deg > 0 {
				cycleMembers = append(cycleMembers, branch)
			}
		}
		return nil, fmt.Errorf("cycle detected in stacked PRs involving branches: %s", strings.Join(cycleMembers, ", "))
	}

	return result, nil
}

// CalculateChain computes the upstream branch chain for a given leaf branch.
// Example: given "#143", returns ["#141", "#142", "#143"]
func (g *RebaseGraph) CalculateChain(branch string) ([]*PRNode, error) {
	visited := make(map[string]bool)
	var chain []*PRNode

	curr := branch
	for curr != "" && curr != g.base {
		if visited[curr] {
			return nil, fmt.Errorf("cycle detected in chain traversal for branch %q", branch)
		}
		visited[curr] = true

		node, exists := g.nodes[curr]
		if !exists {
			break
		}
		chain = append([]*PRNode{node}, chain...) // prepend to get root -> leaf order
		curr = node.BaseBranch
	}

	return chain, nil
}

// DetectConflicts checks for overlapping file modifications between stacked branches.
func (g *RebaseGraph) DetectConflicts(diffs map[string]*DiffReport) []ConflictWarning {
	var warnings []ConflictWarning

	sortedNodes, err := g.TopologicalSort()
	if err != nil {
		return warnings
	}

	// Track modified files per branch
	branchFiles := make(map[string]map[string]bool)
	for _, node := range sortedNodes {
		files := make(map[string]bool)
		for _, f := range node.ChangedFiles {
			files[f] = true
		}
		if report, ok := diffs[node.Branch]; ok {
			for _, fd := range report.Files {
				files[fd.NewPath] = true
				if fd.OldPath != "" {
					files[fd.OldPath] = true
				}
			}
		}
		branchFiles[node.Branch] = files
	}

	// Check each parent -> child pair
	for _, node := range sortedNodes {
		for _, childBranch := range node.Children {
			parentFiles := branchFiles[node.Branch]
			childFiles := branchFiles[childBranch]

			for file := range childFiles {
				if parentFiles[file] {
					warnings = append(warnings, ConflictWarning{
						SourceBranch: node.Branch,
						TargetBranch: childBranch,
						FilePath:     file,
						Reason:       fmt.Sprintf("Both %s and %s touch %s; potential rebase conflict", node.Branch, childBranch, file),
					})
				}
			}
		}
	}

	return warnings
}

// PlanRebase produces the ordered sequence of rebase steps to restack all branches.
func (g *RebaseGraph) PlanRebase() ([]RebaseStep, error) {
	sorted, err := g.TopologicalSort()
	if err != nil {
		return nil, err
	}

	var steps []RebaseStep
	stepNum := 1

	for _, node := range sorted {
		parent := node.BaseBranch
		if parent == "" {
			parent = g.base
		}

		steps = append(steps, RebaseStep{
			StepNumber:   stepNum,
			Branch:       node.Branch,
			OntoBranch:   parent,
			Action:       "rebase",
			Instructions: fmt.Sprintf("git checkout %s && git rebase %s", node.Branch, parent),
		})
		stepNum++

		steps = append(steps, RebaseStep{
			StepNumber:   stepNum,
			Branch:       node.Branch,
			OntoBranch:   "origin/" + node.Branch,
			Action:       "push",
			Instructions: fmt.Sprintf("git push origin %s --force-with-lease", node.Branch),
		})
		stepNum++
	}

	return steps, nil
}
