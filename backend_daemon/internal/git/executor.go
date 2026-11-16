package git

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"os/exec"
	"strconv"
	"strings"
	"sync"
	"time"
)

// RepoStatus describes current repository working tree and HEAD state.
type RepoStatus struct {
	CurrentBranch  string   `json:"current_branch"`
	Upstream       string   `json:"upstream,omitempty"`
	Ahead          int      `json:"ahead"`
	Behind         int      `json:"behind"`
	StagedFiles    []string `json:"staged_files"`
	UnstagedFiles  []string `json:"unstaged_files"`
	UntrackedFiles []string `json:"untracked_files"`
	IsClean        bool     `json:"is_clean"`
}

// WorktreeInfo describes an active git worktree.
type WorktreeInfo struct {
	Path   string `json:"path"`
	Branch string `json:"branch"`
	Head   string `json:"head"`
	IsBare bool   `json:"is_bare"`
}

// CommitSummary describes a commit in a graph or branch.
type CommitSummary struct {
	SHA     string    `json:"sha"`
	Message string    `json:"message"`
	Author  string    `json:"author"`
	Date    time.Time `json:"date"`
}

// Executor provides thread-safe git command execution against a repository directory.
type Executor struct {
	repoDir        string
	defaultTimeout time.Duration
	mu             sync.Mutex
}

// NewExecutor creates a new Git Executor for the given working tree path.
func NewExecutor(repoDir string) *Executor {
	return &Executor{
		repoDir:        repoDir,
		defaultTimeout: 45 * time.Second,
	}
}

// Run executes a raw git command and returns standard output and error.
func (e *Executor) run(ctx context.Context, args ...string) (string, error) {
	if ctx == nil {
		ctx = context.Background()
	}
	ctx, cancel := context.WithTimeout(ctx, e.defaultTimeout)
	defer cancel()

	cmd := exec.CommandContext(ctx, "git", args...)
	cmd.Dir = e.repoDir

	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	err := cmd.Run()
	if err != nil {
		stderrStr := strings.TrimSpace(stderr.String())
		if ctx.Err() == context.DeadlineExceeded {
			return "", fmt.Errorf("git %s timed out after %v", strings.Join(args, " "), e.defaultTimeout)
		}
		if stderrStr != "" {
			return "", fmt.Errorf("git %s failed: %s: %w", strings.Join(args, " "), stderrStr, err)
		}
		return "", fmt.Errorf("git %s failed: %w", strings.Join(args, " "), err)
	}

	return stdout.String(), nil
}

// Status inspects the repository status via git status --porcelain=v2 --branch.
func (e *Executor) Status(ctx context.Context) (*RepoStatus, error) {
	out, err := e.run(ctx, "status", "--porcelain=v2", "--branch")
	if err != nil {
		return nil, fmt.Errorf("status query failed: %w", err)
	}

	status := &RepoStatus{
		StagedFiles:    make([]string, 0),
		UnstagedFiles:  make([]string, 0),
		UntrackedFiles: make([]string, 0),
	}

	lines := strings.Split(out, "\n")
	for _, rawLine := range lines {
		line := strings.TrimSpace(rawLine)
		if line == "" {
			continue
		}

		if strings.HasPrefix(line, "# branch.head ") {
			status.CurrentBranch = strings.TrimPrefix(line, "# branch.head ")
		} else if strings.HasPrefix(line, "# branch.upstream ") {
			status.Upstream = strings.TrimPrefix(line, "# branch.upstream ")
		} else if strings.HasPrefix(line, "# branch.ab ") {
			// # branch.ab +1 -0
			abParts := strings.Fields(strings.TrimPrefix(line, "# branch.ab "))
			if len(abParts) == 2 {
				status.Ahead, _ = strconv.Atoi(strings.TrimPrefix(abParts[0], "+"))
				status.Behind, _ = strconv.Atoi(strings.TrimPrefix(abParts[1], "-"))
			}
		} else if strings.HasPrefix(line, "1 ") || strings.HasPrefix(line, "2 ") {
			// Ordinary or renamed changed entry
			// 1 <XY> <sub> <mH> <mI> <mW> <hH> <hI> <path>
			fields := strings.Fields(line)
			if len(fields) >= 9 {
				xy := fields[1]
				path := fields[8]
				if xy[0] != '.' {
					status.StagedFiles = append(status.StagedFiles, path)
				}
				if xy[1] != '.' {
					status.UnstagedFiles = append(status.UnstagedFiles, path)
				}
			}
		} else if strings.HasPrefix(line, "? ") {
			// Untracked
			status.UntrackedFiles = append(status.UntrackedFiles, strings.TrimPrefix(line, "? "))
		}
	}

	status.IsClean = len(status.StagedFiles) == 0 &&
		len(status.UnstagedFiles) == 0 &&
		len(status.UntrackedFiles) == 0

	return status, nil
}

// Diff produces a parsed DiffReport for staged or unstaged changes, or against a base ref.
func (e *Executor) Diff(ctx context.Context, staged bool, baseRef string) (*DiffReport, error) {
	args := []string{"diff", "--no-color", "--unified=3"}

	if staged {
		args = append(args, "--cached")
	} else if baseRef != "" {
		args = append(args, baseRef)
	}

	out, err := e.run(ctx, args...)
	if err != nil {
		return nil, fmt.Errorf("diff failed: %w", err)
	}

	return ParseDiff(out), nil
}

// Commit stages the provided files and creates a new commit with the given message.
func (e *Executor) Commit(ctx context.Context, message string, files []string) (string, error) {
	e.mu.Lock()
	defer e.mu.Unlock()

	if len(files) > 0 {
		addArgs := append([]string{"add", "--"}, files...)
		if _, err := e.run(ctx, addArgs...); err != nil {
			return "", fmt.Errorf("git add failed: %w", err)
		}
	} else {
		if _, err := e.run(ctx, "add", "-A"); err != nil {
			return "", fmt.Errorf("git add -A failed: %w", err)
		}
	}

	if _, err := e.run(ctx, "commit", "-m", message); err != nil {
		return "", fmt.Errorf("git commit failed: %w", err)
	}

	sha, err := e.run(ctx, "rev-parse", "HEAD")
	if err != nil {
		return "", fmt.Errorf("git rev-parse HEAD failed: %w", err)
	}

	return strings.TrimSpace(sha), nil
}

// Checkout switches to the specified branch, optionally creating it.
func (e *Executor) Checkout(ctx context.Context, branch string, create bool) error {
	e.mu.Lock()
	defer e.mu.Unlock()

	var args []string
	if create {
		args = []string{"checkout", "-b", branch}
	} else {
		args = []string{"checkout", branch}
	}

	_, err := e.run(ctx, args...)
	return err
}

// CurrentBranch returns the currently checked-out branch name.
func (e *Executor) CurrentBranch(ctx context.Context) (string, error) {
	out, err := e.run(ctx, "rev-parse", "--abbrev-ref", "HEAD")
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(out), nil
}

// CreateBranch creates a new branch without switching to it.
func (e *Executor) CreateBranch(ctx context.Context, branch string, startPoint string) error {
	args := []string{"branch", branch}
	if startPoint != "" {
		args = append(args, startPoint)
	}
	_, err := e.run(ctx, args...)
	return err
}

// WorktreeAdd adds a new worktree linked to a branch.
func (e *Executor) WorktreeAdd(ctx context.Context, path string, branch string) error {
	e.mu.Lock()
	defer e.mu.Unlock()

	_, err := e.run(ctx, "worktree", "add", path, branch)
	return err
}

// WorktreeRemove forcefully removes an existing worktree.
func (e *Executor) WorktreeRemove(ctx context.Context, path string) error {
	e.mu.Lock()
	defer e.mu.Unlock()

	_, err := e.run(ctx, "worktree", "remove", "--force", path)
	return err
}

// WorktreeList lists all registered worktrees.
func (e *Executor) WorktreeList(ctx context.Context) ([]WorktreeInfo, error) {
	out, err := e.run(ctx, "worktree", "list", "--porcelain")
	if err != nil {
		return nil, err
	}

	var worktrees []WorktreeInfo
	var current WorktreeInfo

	lines := strings.Split(out, "\n")
	for _, l := range lines {
		line := strings.TrimSpace(l)
		if strings.HasPrefix(line, "worktree ") {
			if current.Path != "" {
				worktrees = append(worktrees, current)
			}
			current = WorktreeInfo{
				Path: strings.TrimPrefix(line, "worktree "),
			}
		} else if strings.HasPrefix(line, "HEAD ") {
			current.Head = strings.TrimPrefix(line, "HEAD ")
		} else if strings.HasPrefix(line, "branch ") {
			current.Branch = strings.TrimPrefix(line, "branch refs/heads/")
		} else if line == "bare" {
			current.IsBare = true
		}
	}

	if current.Path != "" {
		worktrees = append(worktrees, current)
	}

	return worktrees, nil
}

// Rebase performs a git rebase onto the specified upstream branch.
func (e *Executor) Rebase(ctx context.Context, upstream string) error {
	e.mu.Lock()
	defer e.mu.Unlock()

	_, err := e.run(ctx, "rebase", upstream)
	return err
}

// RebaseAbort aborts an ongoing rebase operation.
func (e *Executor) RebaseAbort(ctx context.Context) error {
	e.mu.Lock()
	defer e.mu.Unlock()

	_, err := e.run(ctx, "rebase", "--abort")
	return err
}

// Push pushes the specified branch to the remote, with optional force-with-lease.
func (e *Executor) Push(ctx context.Context, remote, branch string, forceWithLease bool) error {
	if remote == "" {
		remote = "origin"
	}
	args := []string{"push", remote, branch}
	if forceWithLease {
		args = append(args, "--force-with-lease")
	}

	_, err := e.run(ctx, args...)
	return err
}

// LogGraph returns recent commits in reverse chronological order.
func (e *Executor) LogGraph(ctx context.Context, limit int) ([]CommitSummary, error) {
	if limit <= 0 {
		limit = 20
	}
	format := "%H%x1f%s%x1f%an%x1f%aI"
	out, err := e.run(ctx, "log", fmt.Sprintf("-n%d", limit), fmt.Sprintf("--format=%s", format))
	if err != nil {
		return nil, err
	}

	var commits []CommitSummary
	lines := strings.Split(out, "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}
		parts := strings.Split(line, "\x1f")
		if len(parts) >= 4 {
			t, _ := time.Parse(time.RFC3339, parts[3])
			commits = append(commits, CommitSummary{
				SHA:     parts[0],
				Message: parts[1],
				Author:  parts[2],
				Date:    t,
			})
		}
	}

	return commits, nil
}

// RepoDir returns the base directory of the repository.
func (e *Executor) RepoDir() string {
	return e.repoDir
}

// IsGitRepo checks if the configured directory is a valid git repository.
func (e *Executor) IsGitRepo(ctx context.Context) bool {
	out, err := e.run(ctx, "rev-parse", "--is-inside-work-tree")
	return err == nil && strings.TrimSpace(out) == "true"
}

// ErrRebaseConflict is returned when git rebase encounters merge conflicts.
var ErrRebaseConflict = errors.New("rebase conflict detected")
