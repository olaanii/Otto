package llm

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"time"
)

// OllamaProvider integrates locally running Ollama instance.
type OllamaProvider struct {
	baseURL    string
	model      string
	httpClient *http.Client
}

// NewOllamaProvider initializes Ollama provider targeting localhost:11434 by default.
func NewOllamaProvider(baseURL, model string) *OllamaProvider {
	if baseURL == "" {
		baseURL = os.Getenv("OLLAMA_BASE_URL")
	}
	if baseURL == "" {
		baseURL = "http://localhost:11434"
	}
	if model == "" {
		model = os.Getenv("OLLAMA_MODEL")
	}
	if model == "" {
		model = "qwen2.5-coder"
	}

	return &OllamaProvider{
		baseURL: baseURL,
		model:   model,
		httpClient: &http.Client{
			Timeout: 90 * time.Second,
		},
	}
}

func (p *OllamaProvider) ID() string {
	return "ollama"
}

func (p *OllamaProvider) Name() string {
	return "Local Ollama"
}

func (p *OllamaProvider) IsAvailable(ctx context.Context) bool {
	probeCtx, cancel := context.WithTimeout(ctx, 2*time.Second)
	defer cancel()

	req, err := http.NewRequestWithContext(probeCtx, http.MethodGet, fmt.Sprintf("%s/api/version", p.baseURL), nil)
	if err != nil {
		return false
	}

	resp, err := p.httpClient.Do(req)
	if err != nil {
		return false
	}
	defer resp.Body.Close()

	return resp.StatusCode == http.StatusOK
}

func (p *OllamaProvider) Info(ctx context.Context) ProviderInfo {
	return ProviderInfo{
		ID:          p.ID(),
		Name:        p.Name(),
		Type:        "local",
		IsAvailable: p.IsAvailable(ctx),
		Model:       p.model,
		Endpoint:    p.baseURL,
	}
}

func (p *OllamaProvider) Generate(ctx context.Context, req CompletionRequest) (*CompletionResponse, error) {
	model := req.Model
	if model == "" {
		model = p.model
	}

	payload := map[string]any{
		"model":    model,
		"messages": req.Messages,
		"stream":   false,
	}

	if req.Temperature > 0 {
		payload["temperature"] = req.Temperature
	}
	if req.JSONMode {
		payload["format"] = "json"
	}

	bodyBytes, err := json.Marshal(payload)
	if err != nil {
		return nil, err
	}

	url := fmt.Sprintf("%s/v1/chat/completions", p.baseURL)
	httpReq, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(bodyBytes))
	if err != nil {
		return nil, err
	}
	httpReq.Header.Set("Content-Type", "application/json")

	httpResp, err := p.httpClient.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("ollama connection error: %w", err)
	}
	defer httpResp.Body.Close()

	respBytes, err := io.ReadAll(httpResp.Body)
	if err != nil {
		return nil, fmt.Errorf("read ollama response: %w", err)
	}

	if httpResp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("ollama error %d: %s", httpResp.StatusCode, string(respBytes))
	}

	var chatResp openAIChatResp
	if err := json.Unmarshal(respBytes, &chatResp); err != nil {
		return nil, fmt.Errorf("unmarshal ollama response: %w", err)
	}

	if len(chatResp.Choices) == 0 {
		return nil, errors.New("ollama returned no completions")
	}

	return &CompletionResponse{
		Provider: p.ID(),
		Model:    model,
		Content:  chatResp.Choices[0].Message.Content,
		Usage: Usage{
			PromptTokens:     chatResp.Usage.PromptTokens,
			CompletionTokens: chatResp.Usage.CompletionTokens,
			TotalTokens:      chatResp.Usage.TotalTokens,
		},
	}, nil
}
