package server

import (
	"compress/gzip"
	"encoding/json"
	"io"
	"net/http"
	"strings"
	"sync"
	"time"

	"otto-daemon/internal/auth"
	"otto-daemon/internal/git"
	"otto-daemon/internal/github"
	"otto-daemon/internal/llm"
)

// Server encapsulates HTTP routes, dependencies, and middleware for the Otto daemon.
type Server struct {
	gitExec         *git.Executor
	watcher         *git.Watcher
	llmGateway      *llm.Gateway
	githubClient    *github.SyncClient
	eventBroker     *EventBroker
	stateStore      *StateStore
	clerkMiddleware *auth.ClerkMiddleware
	handler         http.Handler
}

// ServerConfig configures Server creation.
type ServerConfig struct {
	RepoDir         string
	GitExec         *git.Executor
	Watcher         *git.Watcher
	LLMGateway      *llm.Gateway
	GitHubClient    *github.SyncClient
	ClerkMiddleware *auth.ClerkMiddleware
}

// NewServer constructs the complete Server with all handlers and middlewares attached.
func NewServer(cfg ServerConfig) *Server {
	s := &Server{
		gitExec:         cfg.GitExec,
		watcher:         cfg.Watcher,
		llmGateway:      cfg.LLMGateway,
		githubClient:    cfg.GitHubClient,
		eventBroker:     NewEventBroker(),
		stateStore:      NewStateStore(cfg.RepoDir),
		clerkMiddleware: cfg.ClerkMiddleware,
	}

	mux := http.NewServeMux()

	// Public health endpoints
	mux.HandleFunc("GET /api/health", s.handleHealth)
	mux.HandleFunc("GET /healthz", s.handleHealth)

	// State endpoints
	mux.HandleFunc("GET /api/state", s.HandleGetState)
	mux.HandleFunc("POST /api/state", s.HandleUpdateState)
	mux.HandleFunc("POST /api/reset", s.HandleResetState)

	// Git operations
	mux.HandleFunc("POST /api/git/analyze", s.HandleGitAnalyze)
	mux.HandleFunc("POST /api/git/split", s.HandleGitSplit)
	mux.HandleFunc("POST /api/git/rebase", s.HandleGitRebase)
	mux.HandleFunc("POST /api/git/push-stack", s.HandleGitPushStack)

	// AI Refinement
	mux.HandleFunc("POST /api/ai/refine-stack", s.HandleAIRefineStack)

	// Server-Sent Events stream
	mux.HandleFunc("GET /api/events", s.eventBroker.HandleEvents)

	// LLM Providers status
	mux.HandleFunc("GET /api/llm/providers", s.HandleGetProviders)

	// Pipe watcher file change events into SSE broker
	if s.watcher != nil {
		go func() {
			for ev := range s.watcher.Events() {
				s.eventBroker.Broadcast("file_changed", ev)
			}
		}()
	}

	// Middleware chain: CORS -> Compression -> Clerk Auth -> Router
	var rootHandler http.Handler = mux

	if s.clerkMiddleware != nil {
		rootHandler = s.clerkMiddleware.Middleware(rootHandler)
	}

	rootHandler = gzipMiddleware(rootHandler)
	rootHandler = corsMiddleware(rootHandler)

	s.handler = rootHandler
	return s
}

// ServeHTTP satisfies http.Handler interface.
func (s *Server) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	s.handler.ServeHTTP(w, r)
}

// Close cleans up server resources and brokers.
func (s *Server) Close() {
	if s.eventBroker != nil {
		s.eventBroker.Close()
	}
}

func (s *Server) handleHealth(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{
		"status":    "healthy",
		"service":   "otto-daemon",
		"version":   "1.0.0",
		"timestamp": time.Now().UTC().Format(time.RFC3339),
	})
}

// corsMiddleware injects permissive development CORS headers and responds to preflight OPTIONS.
func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Authorization, Content-Type, Accept, X-Requested-With, Origin")
		w.Header().Set("Access-Control-Max-Age", "86400")

		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}

var gzipWriterPool = sync.Pool{
	New: func() any {
		return gzip.NewWriter(io.Discard)
	},
}

type gzipResponseWriter struct {
	http.ResponseWriter
	writer *gzip.Writer
}

func (g *gzipResponseWriter) Write(b []byte) (int, error) {
	return g.writer.Write(b)
}

// gzipMiddleware compresses JSON and text responses if client supports gzip.
func gzipMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Do not compress SSE streams
		if r.URL.Path == "/api/events" || !strings.Contains(r.Header.Get("Accept-Encoding"), "gzip") {
			next.ServeHTTP(w, r)
			return
		}

		gz := gzipWriterPool.Get().(*gzip.Writer)
		defer gzipWriterPool.Put(gz)
		gz.Reset(w)
		defer gz.Close()

		w.Header().Set("Content-Encoding", "gzip")
		gzw := &gzipResponseWriter{ResponseWriter: w, writer: gz}
		next.ServeHTTP(gzw, r)
	})
}

func writeJSON(w http.ResponseWriter, status int, data any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(data)
}

func writeJSONError(w http.ResponseWriter, status int, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(map[string]any{
		"error":     message,
		"status":    status,
		"timestamp": time.Now().UnixMilli(),
	})
}
