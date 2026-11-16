package llm

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"time"
)

// Message represents a prompt message in a conversation.
type Message struct {
	Role    string `json:"role"` // "system", "user", "assistant"
	Content string `json:"content"`
}

// CompletionRequest provides structured input for LLM generation.
type CompletionRequest struct {
	Model       string    `json:"model,omitempty"`
	Messages    []Message `json:"messages"`
	Temperature float64   `json:"temperature,omitempty"`
	MaxTokens   int       `json:"max_tokens,omitempty"`
	JSONMode    bool      `json:"json_mode,omitempty"`
}

// Usage holds token consumption statistics.
type Usage struct {
	PromptTokens     int `json:"prompt_tokens"`
	CompletionTokens int `json:"completion_tokens"`
	TotalTokens      int `json:"total_tokens"`
}

// CompletionResponse encapsulates standard LLM output.
type CompletionResponse struct {
	Provider string `json:"provider"`
	Model    string `json:"model"`
	Content  string `json:"content"`
	Usage    Usage  `json:"usage,omitempty"`
}

// ProviderInfo contains metadata and availability state for an LLM provider.
type ProviderInfo struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Type        string `json:"type"` // "cloud" or "local"
	IsAvailable bool   `json:"is_available"`
	Model       string `json:"model"`
	Endpoint    string `json:"endpoint,omitempty"`
}

// Provider defines the standard interface implemented by each AI backend.
type Provider interface {
	ID() string
	Name() string
	IsAvailable(ctx context.Context) bool
	Generate(ctx context.Context, req CompletionRequest) (*CompletionResponse, error)
	Info(ctx context.Context) ProviderInfo
}

// Gateway orchestrates multiple LLM providers with automatic health checks and failover.
type Gateway struct {
	mu        sync.RWMutex
	providers map[string]Provider
	order     []string // Fallback priority order
}

// NewGateway creates an empty LLM Gateway.
func NewGateway() *Gateway {
	return &Gateway{
		providers: make(map[string]Provider),
		order:     make([]string, 0),
	}
}

// RegisterProvider registers an LLM provider with the gateway.
func (g *Gateway) RegisterProvider(p Provider) {
	g.mu.Lock()
	defer g.mu.Unlock()

	id := p.ID()
	if _, exists := g.providers[id]; !exists {
		g.order = append(g.order, id)
	}
	g.providers[id] = p
}

// GetProvider retrieves a specific provider by ID.
func (g *Gateway) GetProvider(id string) (Provider, bool) {
	g.mu.RLock()
	defer g.mu.RUnlock()

	p, ok := g.providers[id]
	return p, ok
}

// ListProviders returns real-time status and availability for all registered providers.
func (g *Gateway) ListProviders(ctx context.Context) []ProviderInfo {
	g.mu.RLock()
	orderCopy := make([]string, len(g.order))
	copy(orderCopy, g.order)
	providersCopy := make(map[string]Provider, len(g.providers))
	for k, v := range g.providers {
		providersCopy[k] = v
	}
	g.mu.RUnlock()

	var wg sync.WaitGroup
	infos := make([]ProviderInfo, len(orderCopy))

	for i, id := range orderCopy {
		wg.Add(1)
		go func(idx int, provID string) {
			defer wg.Done()
			p := providersCopy[provID]
			// Use short timeout for availability probes
			probeCtx, cancel := context.WithTimeout(ctx, 3*time.Second)
			defer cancel()
			infos[idx] = p.Info(probeCtx)
		}(i, id)
	}

	wg.Wait()
	return infos
}

// GenerateWithFallback executes completion using the requested provider or falls back to next available.
func (g *Gateway) GenerateWithFallback(ctx context.Context, preferredID string, req CompletionRequest) (*CompletionResponse, error) {
	g.mu.RLock()
	orderCopy := make([]string, len(g.order))
	copy(orderCopy, g.order)
	providersCopy := make(map[string]Provider, len(g.providers))
	for k, v := range g.providers {
		providersCopy[k] = v
	}
	g.mu.RUnlock()

	// Prioritize preferredID if specified
	var candidates []Provider
	if preferredID != "" {
		if p, ok := providersCopy[preferredID]; ok {
			candidates = append(candidates, p)
		}
	}

	for _, id := range orderCopy {
		if id != preferredID {
			if p, ok := providersCopy[id]; ok {
				candidates = append(candidates, p)
			}
		}
	}

	if len(candidates) == 0 {
		return nil, errors.New("no LLM providers configured")
	}

	var lastErr error
	for _, p := range candidates {
		if !p.IsAvailable(ctx) {
			continue
		}

		resp, err := p.Generate(ctx, req)
		if err == nil && resp != nil {
			return resp, nil
		}
		lastErr = err
	}

	if lastErr != nil {
		return nil, fmt.Errorf("all LLM providers failed, last error: %w", lastErr)
	}

	return nil, errors.New("no active LLM provider currently available")
}
