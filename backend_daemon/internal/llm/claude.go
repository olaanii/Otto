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
	"strings"
	"time"
)

// ClaudeProvider integrates Anthropic's Messages API.
type ClaudeProvider struct {
	apiKey     string
	model      string
	httpClient *http.Client
}

// NewClaudeProvider initializes Anthropic Claude client.
func NewClaudeProvider(apiKey, model string) *ClaudeProvider {
	if apiKey == "" {
		apiKey = os.Getenv("ANTHROPIC_API_KEY")
	}
	if model == "" {
		model = os.Getenv("ANTHROPIC_MODEL")
	}
	if model == "" {
		model = "claude-3-5-sonnet-20241022"
	}

	return &ClaudeProvider{
		apiKey: apiKey,
		model:  model,
		httpClient: &http.Client{
			Timeout: 60 * time.Second,
		},
	}
}

func (p *ClaudeProvider) ID() string {
	return "claude"
}

func (p *ClaudeProvider) Name() string {
	return "Anthropic Claude"
}

func (p *ClaudeProvider) IsAvailable(ctx context.Context) bool {
	return p.apiKey != ""
}

func (p *ClaudeProvider) Info(ctx context.Context) ProviderInfo {
	return ProviderInfo{
		ID:          p.ID(),
		Name:        p.Name(),
		Type:        "cloud",
		IsAvailable: p.IsAvailable(ctx),
		Model:       p.model,
		Endpoint:    "https://api.anthropic.com",
	}
}

type claudeMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type claudeReq struct {
	Model       string          `json:"model"`
	Messages    []claudeMessage `json:"messages"`
	System      string          `json:"system,omitempty"`
	MaxTokens   int             `json:"max_tokens"`
	Temperature float64         `json:"temperature,omitempty"`
}

type claudeResp struct {
	ID      string `json:"id"`
	Type    string `json:"type"`
	Role    string `json:"role"`
	Content []struct {
		Type string `json:"type"`
		Text string `json:"text"`
	} `json:"content"`
	Usage struct {
		InputTokens  int `json:"input_tokens"`
		OutputTokens int `json:"output_tokens"`
	} `json:"usage"`
	Error *struct {
		Type    string `json:"type"`
		Message string `json:"message"`
	} `json:"error,omitempty"`
}

func (p *ClaudeProvider) Generate(ctx context.Context, req CompletionRequest) (*CompletionResponse, error) {
	if p.apiKey == "" {
		return nil, errors.New("ANTHROPIC_API_KEY is not configured")
	}

	model := req.Model
	if model == "" {
		model = p.model
	}

	maxTokens := req.MaxTokens
	if maxTokens <= 0 {
		maxTokens = 4096
	}

	var systemPrompt string
	var messages []claudeMessage

	for _, m := range req.Messages {
		if m.Role == "system" {
			systemPrompt = m.Content
		} else {
			messages = append(messages, claudeMessage{
				Role:    m.Role,
				Content: m.Content,
			})
		}
	}

	payload := claudeReq{
		Model:       model,
		Messages:    messages,
		System:      systemPrompt,
		MaxTokens:   maxTokens,
		Temperature: req.Temperature,
	}

	bodyBytes, err := json.Marshal(payload)
	if err != nil {
		return nil, err
	}

	httpReq, err := http.NewRequestWithContext(ctx, http.MethodPost, "https://api.anthropic.com/v1/messages", bytes.NewReader(bodyBytes))
	if err != nil {
		return nil, err
	}

	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("x-api-key", p.apiKey)
	httpReq.Header.Set("anthropic-version", "2023-06-01")

	httpResp, err := p.httpClient.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("claude request error: %w", err)
	}
	defer httpResp.Body.Close()

	respBytes, err := io.ReadAll(httpResp.Body)
	if err != nil {
		return nil, fmt.Errorf("read claude response: %w", err)
	}

	if httpResp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("claude api status %d: %s", httpResp.StatusCode, string(respBytes))
	}

	var cResp claudeResp
	if err := json.Unmarshal(respBytes, &cResp); err != nil {
		return nil, fmt.Errorf("unmarshal claude response: %w", err)
	}

	if cResp.Error != nil {
		return nil, fmt.Errorf("claude error %s: %s", cResp.Error.Type, cResp.Error.Message)
	}

	var sb strings.Builder
	for _, block := range cResp.Content {
		if block.Type == "text" {
			sb.WriteString(block.Text)
		}
	}

	return &CompletionResponse{
		Provider: p.ID(),
		Model:    model,
		Content:  sb.String(),
		Usage: Usage{
			PromptTokens:     cResp.Usage.InputTokens,
			CompletionTokens: cResp.Usage.OutputTokens,
			TotalTokens:      cResp.Usage.InputTokens + cResp.Usage.OutputTokens,
		},
	}, nil
}
