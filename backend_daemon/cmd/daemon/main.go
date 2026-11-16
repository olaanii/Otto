package main

import (
	"context"
	"errors"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"path/filepath"
	"syscall"
	"time"

	"otto-daemon/internal/auth"
	"otto-daemon/internal/git"
	"otto-daemon/internal/github"
	"otto-daemon/internal/llm"
	"otto-daemon/internal/server"
)

func main() {
	log.Println("🚀 Initializing Otto High-Performance Backend Daemon...")

	port := getEnv("PORT", "8787")
	host := getEnv("HOST", "127.0.0.1")
	repoPath := getEnv("REPO_PATH", "")
	if repoPath == "" {
		cwd, err := os.Getwd()
		if err != nil {
			log.Fatalf("Failed to detect working directory: %v", err)
		}
		repoPath = cwd
	}

	absRepoPath, err := filepath.Abs(repoPath)
	if err != nil {
		log.Fatalf("Invalid repository path %q: %v", repoPath, err)
	}

	log.Printf("📂 Monitored repository: %s", absRepoPath)

	// 1. Initialize Git Executor
	gitExec := git.NewExecutor(absRepoPath)
	if !gitExec.IsGitRepo(context.Background()) {
		log.Printf("⚠️ Warning: %s is not currently an initialized git repository; running in standby mode", absRepoPath)
	} else {
		branch, _ := gitExec.CurrentBranch(context.Background())
		log.Printf("🌿 Active git branch: %s", branch)
	}

	// 2. Initialize File System Watcher with 30ms debounce
	watcher, err := git.NewWatcher(absRepoPath)
	if err != nil {
		log.Printf("⚠️ Could not start filesystem watcher on %s: %v", absRepoPath, err)
	} else {
		log.Println("👀 Debounced file system watcher active (30ms debounce window)")
	}

	// 3. Initialize Clerk JWT Authentication Middleware
	clerkSecret := os.Getenv("CLERK_SECRET_KEY")
	devMode := getEnv("CLERK_DEV_MODE", "true") == "true" || clerkSecret == ""
	clerkMiddleware := auth.NewClerkMiddleware(auth.ClerkConfig{
		SecretKey: clerkSecret,
		DevMode:   devMode,
	})
	if devMode {
		log.Println("🔐 Clerk Auth: running in Development Mode (pre-authorized local claims)")
	} else {
		log.Println("🔐 Clerk Auth: running in Production Mode (strict JWT / JWKS verification)")
	}

	// 4. Initialize Multi-Model LLM Gateway
	gateway := llm.NewGateway()
	gateway.RegisterProvider(llm.NewGeminiProvider("", "gemini-3.8-flash"))
	gateway.RegisterProvider(llm.NewClaudeProvider("", "claude-3-5-sonnet-20241022"))
	gateway.RegisterProvider(llm.NewOpenAIProvider("", "", "gpt-4o"))
	gateway.RegisterProvider(llm.NewOllamaProvider("", "qwen2.5-coder"))
	gateway.RegisterProvider(llm.NewLMStudioProvider("", "local-model"))
	log.Println("🧠 Multi-model LLM Gateway initialized (Gemini, Claude, OpenAI, Ollama, LM Studio)")

	// 5. Initialize GitHub Sync Client
	githubToken := os.Getenv("GITHUB_TOKEN")
	githubOwner := os.Getenv("GITHUB_OWNER")
	githubRepo := os.Getenv("GITHUB_REPO")
	var ghClient *github.SyncClient
	if githubToken != "" {
		ghClient = github.NewSyncClient(githubToken, githubOwner, githubRepo)
		log.Printf("🐙 GitHub client configured for repo %s/%s", githubOwner, githubRepo)
	}

	// 6. Initialize HTTP Router
	srvHandler := server.NewServer(server.ServerConfig{
		RepoDir:         absRepoPath,
		GitExec:         gitExec,
		Watcher:         watcher,
		LLMGateway:      gateway,
		GitHubClient:    ghClient,
		ClerkMiddleware: clerkMiddleware,
	})

	listenAddr := fmt.Sprintf("%s:%s", host, port)
	httpServer := &http.Server{
		Addr:              listenAddr,
		Handler:           srvHandler,
		ReadHeaderTimeout: 10 * time.Second,
		IdleTimeout:       120 * time.Second,
	}

	// Start server in background goroutine
	go func() {
		log.Printf("✨ Otto daemon listening on http://%s", listenAddr)
		log.Printf("📡 Real-time SSE stream available at http://%s/api/events", listenAddr)
		if err := httpServer.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatalf("HTTP server fatal error: %v", err)
		}
	}()

	// 7. Handle Graceful Shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	sig := <-quit
	log.Printf("🛑 Received shutdown signal (%s), terminating gracefully...", sig)

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := httpServer.Shutdown(shutdownCtx); err != nil {
		log.Printf("Error during HTTP server shutdown: %v", err)
	}

	if watcher != nil {
		_ = watcher.Close()
	}

	srvHandler.Close()
	log.Println("👋 Otto daemon shutdown completed successfully")
}

func getEnv(key, defaultVal string) string {
	val := os.Getenv(key)
	if val != "" {
		return val
	}
	return defaultVal
}
