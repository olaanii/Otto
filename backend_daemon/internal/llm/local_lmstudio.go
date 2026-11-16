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

// LMStudioProvider integrates local LM Studio instance running on port 1234.
type LMStudioProvider struct {
	baseURL    string
	model      string
	httpClient *http.Client
}

// NewLMStudioProvider initializes LM Studio client targeting localhost:1234.
func NewLMStudioProvider(baseURL, model string) *LMStudioProvider {
	if baseURL == "" {
		baseURL = os.Getenv("LMSTUDIO_BASE_URL")
	}
	if baseURL == "" {
		baseURL = "http://localhost:1234"
	}
	if model == "" {
		model = os.Getenv("LMSTUDIO_MODEL")
	}
	if model == "" {
		model = "local-model"
	}

	return &LMStudioProvider{
		baseURL: baseURL,
		model:   model,
		httpClient: &http.Client{
			Timeout: 90 * time.Second,
		},
	}
}

func (p *LMStudioProvider) ID() string {
	return "lmstudio"
}

func (p *LMStudioProvider) Name() string {
	return "LM Studio"
}

func (p *LMStudioProvider) IsAvailable(ctx context.Context) bool {
	probeCtx, cancel := context.WithTimeout(ctx, 2*time.Second)
	defer cancel()

	req, err := http.NewRequestWithContext(probeCtx, http.MethodGet, fmt.Sprintf("%s/v1/models", p.baseURL), nil)
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

func (p *LMStudioProvider) Info(ctx context.Context) ProviderInfo {
	return ProviderInfo{
		ID:          p.ID(),
		Name:        p.Name(),
		Type:        "local",
		IsAvailable: p.IsAvailable(ctx),
		Model:       p.model,
		Endpoint:    p.baseURL,
	}
}

func (p *LMStudioProvider) Generate(ctx context.Context, req CompletionRequest) (*CompletionResponse, error) {
	model := req.Model
	if model == "" {
		model = p.model
	}

	payload := map[string]any{
		"model":       model,
		"messages":    req.Messages,
		"temperature": req.Temperature,
		"stream":      false,
	}

	if req.MaxTokens > 0 {
		payload["max_tokens"] = req.MaxTokens
	}
	if req.JSONMode {
		payload["response_format"] = map[string]any{"type": "json_object"}
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
		return nil, fmt.Errorf("lm studio connection error: %w", err)
	}
	defer httpResp.Body.Close()

	respBytes, err := io.ReadAll(httpResp.Body)
	if err != nil {
		return nil, fmt.Errorf("read lm studio response: %w", err)
	}

	if httpResp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("lm studio status %d: %s", httpResp.StatusCode, string(respBytes))
	}

	var chatResp openAIChatResp
	if err := json.Unmarshal(respBytes, &chatResp); err != nil {
		return nil, fmt.Errorf("unmarshal lm studio response: %w", err)
	}

	if len(chatResp.Choices) == 0 {
		return nil, errors.New("lm studio returned no completions")
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
