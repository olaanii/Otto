package git

import (
	"io/fs"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"github.com/fsnotify/fsnotify"
)

// WatchEvent represents a debounced filesystem change batch.
type WatchEvent struct {
	Timestamp time.Time `json:"timestamp"`
	Files     []string  `json:"files"`
	Op        string    `json:"op"`
}

// Watcher provides debounced file system monitoring while ignoring unneeded build/tooling files.
type Watcher struct {
	rootPath     string
	fswatcher    *fsnotify.Watcher
	debounceTime time.Duration
	eventsChan   chan WatchEvent
	errChan      chan error
	stopChan     chan struct{}
	stopped      bool
	mu           sync.Mutex
	watchedDirs  map[string]bool
}

// Default ignored directories and filenames.
var (
	ignoredDirs = map[string]bool{
		".git":        true,
		"node_modules": true,
		"dist":        true,
		".dart_tool":  true,
		"build":       true,
		".idea":       true,
		".vscode":     true,
		".gemini":     true,
		".turbo":      true,
		".next":       true,
		"coverage":    true,
	}

	ignoredFiles = map[string]bool{
		"package-lock.json": true,
		"pnpm-lock.yaml":    true,
		"yarn.lock":         true,
		"pubspec.lock":      true,
		"go.sum":            true,
		"Cargo.lock":        true,
	}
)

// NewWatcher initializes a file watcher rooted at rootPath with a 30ms debounce interval.
func NewWatcher(rootPath string) (*Watcher, error) {
	fsw, err := fsnotify.NewWatcher()
	if err != nil {
		return nil, err
	}

	w := &Watcher{
		rootPath:     rootPath,
		fswatcher:    fsw,
		debounceTime: 30 * time.Millisecond,
		eventsChan:   make(chan WatchEvent, 100),
		errChan:      make(chan error, 50),
		stopChan:     make(chan struct{}),
		watchedDirs:  make(map[string]bool),
	}

	// Add root and subdirectories recursively
	if err := w.watchRecursive(rootPath); err != nil {
		_ = fsw.Close()
		return nil, err
	}

	go w.debounceLoop()

	return w, nil
}

// Events returns the stream of debounced file change events.
func (w *Watcher) Events() <-chan WatchEvent {
	return w.eventsChan
}

// Errors returns the stream of errors encountered while watching.
func (w *Watcher) Errors() <-chan error {
	return w.errChan
}

// isIgnored checks whether a path should be skipped from watching.
func isIgnored(path string, isDir bool) bool {
	clean := filepath.ToSlash(filepath.Clean(path))
	parts := strings.Split(clean, "/")

	for _, part := range parts {
		if ignoredDirs[strings.ToLower(part)] {
			return true
		}
	}

	base := filepath.Base(clean)
	if ignoredFiles[base] {
		return true
	}

	// Skip temporary or backup editor files
	if strings.HasSuffix(base, ".tmp") ||
		strings.HasSuffix(base, ".swp") ||
		strings.HasSuffix(base, "~") ||
		strings.HasPrefix(base, ".#") {
		return true
	}

	return false
}

func (w *Watcher) watchRecursive(root string) error {
	return filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return nil // continue walk even if permission error on single file
		}

		if d.IsDir() {
			name := d.Name()
			if ignoredDirs[strings.ToLower(name)] {
				return filepath.SkipDir
			}

			w.mu.Lock()
			if !w.watchedDirs[path] {
				if err := w.fswatcher.Add(path); err == nil {
					w.watchedDirs[path] = true
				}
			}
			w.mu.Unlock()
		}
		return nil
	})
}

// debounceLoop aggregates incoming filesystem events and flushes them after 30ms of silence.
func (w *Watcher) debounceLoop() {
	var (
		timer      *time.Timer
		timerCh    <-chan time.Time
		pending    = make(map[string]bool)
		pendingMu  sync.Mutex
		lastOp     = "change"
	)

	flush := func() {
		pendingMu.Lock()
		if len(pending) == 0 {
			pendingMu.Unlock()
			return
		}

		files := make([]string, 0, len(pending))
		for f := range pending {
			files = append(files, f)
		}
		pending = make(map[string]bool)
		op := lastOp
		pendingMu.Unlock()

		select {
		case w.eventsChan <- WatchEvent{
			Timestamp: time.Now(),
			Files:     files,
			Op:        op,
		}:
		default:
			// If buffer full, discard oldest or drop to avoid blocking
		}
	}

	for {
		select {
		case <-w.stopChan:
			if timer != nil {
				timer.Stop()
			}
			return

		case err, ok := <-w.fswatcher.Errors:
			if !ok {
				return
			}
			select {
			case w.errChan <- err:
			default:
			}

		case event, ok := <-w.fswatcher.Events:
			if !ok {
				return
			}

			if isIgnored(event.Name, false) {
				continue
			}

			// If a new directory was created, add it to watch list
			if event.Has(fsnotify.Create) {
				fi, err := os.Stat(event.Name)
				if err == nil && fi.IsDir() {
					_ = w.watchRecursive(event.Name)
				}
			}

			pendingMu.Lock()
			rel, err := filepath.Rel(w.rootPath, event.Name)
			if err != nil {
				rel = event.Name
			}
			pending[filepath.ToSlash(rel)] = true

			switch {
			case event.Has(fsnotify.Create):
				lastOp = "create"
			case event.Has(fsnotify.Remove):
				lastOp = "delete"
			case event.Has(fsnotify.Rename):
				lastOp = "rename"
			case event.Has(fsnotify.Write):
				lastOp = "write"
			}
			pendingMu.Unlock()

			// Reset 30ms debounce timer
			if timer != nil {
				timer.Stop()
			}
			timer = time.NewTimer(w.debounceTime)
			timerCh = timer.C

		case <-timerCh:
			flush()
			timer = nil
			timerCh = nil
		}
	}
}

// Close gracefully closes the filesystem watcher.
func (w *Watcher) Close() error {
	w.mu.Lock()
	defer w.mu.Unlock()

	if w.stopped {
		return nil
	}
	w.stopped = true
	close(w.stopChan)
	return w.fswatcher.Close()
}
