package config

import (
	"os"
	"strconv"
)

type Config struct {
	Port                int
	RepoPath            string
	ClerkSecretKey      string
	ClerkPublishableKey string
	GeminiApiKey        string
	AnthropicApiKey     string
	OpenAiApiKey        string
	OllamaURL           string
	LmStudioURL         string
	MaxLocDefault       int
	BaseBranch          string
}

func LoadConfig() *Config {
	port := 3000
	if pStr := os.Getenv("PORT"); pStr != "" {
		if p, err := strconv.Atoi(pStr); err == nil {
			port = p
		}
	}

	repoPath := os.Getenv("REPO_PATH")
	if repoPath == "" {
		repoPath = "."
	}

	ollamaURL := os.Getenv("OLLAMA_URL")
	if ollamaURL == "" {
		ollamaURL = "http://localhost:11434"
	}

	lmStudioURL := os.Getenv("LMSTUDIO_URL")
	if lmStudioURL == "" {
		lmStudioURL = "http://localhost:1234/v1"
	}

	maxLoc := 80
	if locStr := os.Getenv("MAX_LOC_DEFAULT"); locStr != "" {
		if l, err := strconv.Atoi(locStr); err == nil {
			maxLoc = l
		}
	}

	baseBranch := os.Getenv("BASE_BRANCH")
	if baseBranch == "" {
		baseBranch = "main"
	}

	return &Config{
		Port:                port,
		RepoPath:            repoPath,
		ClerkSecretKey:      os.Getenv("CLERK_SECRET_KEY"),
		ClerkPublishableKey: os.Getenv("CLERK_PUBLISHABLE_KEY"),
		GeminiApiKey:        os.Getenv("GEMINI_API_KEY"),
		AnthropicApiKey:     os.Getenv("ANTHROPIC_API_KEY"),
		OpenAiApiKey:        os.Getenv("OPENAI_API_KEY"),
		OllamaURL:           ollamaURL,
		LmStudioURL:         lmStudioURL,
		MaxLocDefault:       maxLoc,
		BaseBranch:          baseBranch,
	}
}
