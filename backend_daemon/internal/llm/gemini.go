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

// GeminiProvider connects to Google Gemini API (gemini-3.8-flash / gemini-2.5-flash).
type GeminiProvider struct {
	apiKey     string
	model      string
	httpClient *http.Client
}

// NewGeminiProvider initializes a Gemini provider using GEMINI_API_KEY environment variable.
func NewGeminiProvider(apiKey, model string) *GeminiProvider {
	if apiKey == "" {
		apiKey = os.Getenv("GEMINI_API_KEY")
	}
	if model == "" {
		model = os.Getenv("GEMINI_MODEL")
	}
	if model == "" {
		model = "gemini-3.8-flash"
	}

	return &GeminiProvider{
		apiKey: apiKey,
		model:  model,
		httpClient: &http.Client{
			Timeout: 60 * time.Second,
		},
	}
}

func (p *GeminiProvider) ID() string {
	return "gemini"
}

func (p *GeminiProvider) Name() string {
	return "Google Gemini"
}

func (p *GeminiProvider) IsAvailable(ctx context.Context) bool {
	return p.apiKey != ""
}

func (p *GeminiProvider) Info(ctx context.Context) ProviderInfo {
	return ProviderInfo{
		ID:          p.ID(),
		Name:        p.Name(),
		Type:        "cloud",
		IsAvailable: p.IsAvailable(ctx),
		Model:       p.model,
		Endpoint:    "https://generativelanguage.googleapis.com",
	}
}

type geminiPart struct {
	Text string `json:"text"`
}

type geminiContent struct {
	Role  string       `json:"role,omitempty"`
	Parts []geminiPart `json:"parts"`
}

type geminiReq struct {
	Contents          []geminiContent `json:"contents"`
	SystemInstruction *geminiContent  `json:"systemInstruction,omitempty"`
	GenerationConfig  map[string]any  `json:"generationConfig,omitempty"`
}

type geminiResp struct {
	Candidates []struct {
		Content struct {
			Parts []struct {
				Text string `json:"text"`
			} `json:"parts"`
		} `json:"content"`
		FinishReason string `json:"finishReason"`
	} `json:"candidates"`
	UsageMetadata struct {
		PromptTokenCount     int `json:"promptTokenCount"`
		CandidatesTokenCount int `json:"candidatesTokenCount"`
		TotalTokenCount      int `json:"totalTokenCount"`
	} `json:"usageMetadata"`
	Error *struct {
		Code    int    `json:"code"`
		Message string `json:"message"`
	} `json:"error,omitempty"`
}

func (p *GeminiProvider) Generate(ctx context.Context, req CompletionRequest) (*CompletionResponse, error) {
	if p.apiKey == "" {
		return nil, errors.New("GEMINI_API_KEY is not configured")
	}

	model := req.Model
	if model == "" {
		model = p.model
	}

	var contents []geminiContent
	var systemContent *geminiContent

	for _, m := range req.Messages {
		if m.Role == "system" {
			systemContent = &geminiContent{
				Parts: []geminiPart{{Text: m.Content}},
			}
		} else {
			role := "user"
			if m.Role == "assistant" {
				role = "model"
			}
			contents = append(contents, geminiContent{
				Role:  role,
				Parts: []geminiPart{{Text: m.Content}},
			})
		}
	}

	genConfig := make(map[string]any)
	if req.Temperature > 0 {
		genConfig["temperature"] = req.Temperature
	}
	if req.MaxTokens > 0 {
		genConfig["maxOutputTokens"] = req.MaxTokens
	}
	if req.JSONMode {
		genConfig["responseMimeType"] = "application/json"
	}

	payload := geminiReq{
		Contents:          contents,
		SystemInstruction: systemContent,
		GenerationConfig:  genConfig,
	}

	bodyBytes, err := json.Marshal(payload)
	if err != nil {
		return nil, err
	}

	url := fmt.Sprintf("https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s", model, p.apiKey)
	httpReq, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(bodyBytes))
	if err != nil {
		return nil, err
	}
	httpReq.Header.Set("Content-Type", "application/json")

	httpResp, err := p.httpClient.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("gemini request error: %w", err)
	}
	defer httpResp.Body.Close()

	respBytes, err := io.ReadAll(httpResp.Body)
	if err != nil {
		return nil, fmt.Errorf("read gemini response: %w", err)
	}

	if httpResp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("gemini api returned status %d: %s", httpResp.StatusCode, string(respBytes))
	}

	var gResp geminiResp
	if err := json.Unmarshal(respBytes, &gResp); err != nil {
		return nil, fmt.Errorf("unmarshal gemini response: %w", err)
	}

	if gResp.Error != nil {
		return nil, fmt.Errorf("gemini api error %d: %s", gResp.Error.Code, gResp.Error.Message)
	}

	if len(gResp.Candidates) == 0 || len(gResp.Candidates[0].Content.Parts) == 0 {
		return nil, errors.New("gemini returned no content candidates")
	}

	var sb strings.Builder
	for _, part := range gResp.Candidates[0].Content.Parts {
		sb.WriteString(part.Text)
	}

	return &CompletionResponse{
		Provider: p.ID(),
		Model:    model,
		Content:  sb.String(),
		Usage: Usage{
			PromptTokens:     gResp.UsageMetadata.PromptTokenCount,
			CompletionTokens: gResp.UsageMetadata.CandidatesTokenCount,
			TotalTokens:      gResp.UsageMetadata.TotalTokenCount,
		},
	}, nil
}
