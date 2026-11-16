package github

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

// PullRequest represents a GitHub pull request entity.
type PullRequest struct {
	ID        int64     `json:"id"`
	Number    int       `json:"number"`
	Title     string    `json:"title"`
	Body      string    `json:"body"`
	State     string    `json:"state"` // "open", "closed"
	IsDraft   bool      `json:"draft"`
	Merged    bool      `json:"merged"`
	Mergeable *bool     `json:"mergeable,omitempty"`
	HTMLURL   string    `json:"html_url"`
	HeadRef   string    `json:"head_ref"`
	BaseRef   string    `json:"base_ref"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// StackPRItem represents one link in a stacked PR chain.
type StackPRItem struct {
	Number  int    `json:"number"`
	Title   string `json:"title"`
	Branch  string `json:"branch"`
	IsCurr  bool   `json:"is_curr"`
	HTMLURL string `json:"html_url"`
}

// SyncClient provides GitHub REST API operations for stacked PRs.
type SyncClient struct {
	token      string
	owner      string
	repo       string
	baseURL    string
	httpClient *http.Client
}

// NewSyncClient creates an authenticated GitHub API client.
func NewSyncClient(token, owner, repo string) *SyncClient {
	if token == "" {
		token = os.Getenv("GITHUB_TOKEN")
	}
	baseURL := os.Getenv("GITHUB_API_URL")
	if baseURL == "" {
		baseURL = "https://api.github.com"
	}

	return &SyncClient{
		token:   token,
		owner:   owner,
		repo:    repo,
		baseURL: strings.TrimRight(baseURL, "/"),
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

func (c *SyncClient) sendRequest(ctx context.Context, method, endpoint string, payload any) ([]byte, int, error) {
	if c.token == "" {
		return nil, 0, errors.New("GITHUB_TOKEN is not configured")
	}

	var bodyReader io.Reader
	if payload != nil {
		data, err := json.Marshal(payload)
		if err != nil {
			return nil, 0, fmt.Errorf("marshal json payload: %w", err)
		}
		bodyReader = bytes.NewReader(data)
	}

	url := fmt.Sprintf("%s%s", c.baseURL, endpoint)
	req, err := http.NewRequestWithContext(ctx, method, url, bodyReader)
	if err != nil {
		return nil, 0, err
	}

	req.Header.Set("Authorization", "Bearer "+c.token)
	req.Header.Set("Accept", "application/vnd.github+json")
	req.Header.Set("X-GitHub-Api-Version", "2022-11-28")
	if payload != nil {
		req.Header.Set("Content-Type", "application/json")
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, 0, err
	}
	defer resp.Body.Close()

	respBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, resp.StatusCode, err
	}

	return respBytes, resp.StatusCode, nil
}

// CreateStackedPR creates a PR whose base is either the parent branch or main.
func (c *SyncClient) CreateStackedPR(ctx context.Context, title, body, headBranch, baseBranch string, draft bool) (*PullRequest, error) {
	if c.owner == "" || c.repo == "" {
		return nil, errors.New("GitHub repository owner and repo name must be configured")
	}

	endpoint := fmt.Sprintf("/repos/%s/%s/pulls", c.owner, c.repo)
	reqPayload := map[string]any{
		"title": title,
		"body":  body,
		"head":  headBranch,
		"base":  baseBranch,
		"draft": draft,
	}

	respBytes, status, err := c.sendRequest(ctx, http.MethodPost, endpoint, reqPayload)
	if err != nil {
		return nil, fmt.Errorf("create PR request error: %w", err)
	}

	if status != http.StatusCreated {
		return nil, fmt.Errorf("GitHub API returned status %d: %s", status, string(respBytes))
	}

	var raw struct {
		ID        int64     `json:"id"`
		Number    int       `json:"number"`
		Title     string    `json:"title"`
		Body      string    `json:"body"`
		State     string    `json:"state"`
		Draft     bool      `json:"draft"`
		Merged    bool      `json:"merged"`
		Mergeable *bool     `json:"mergeable"`
		HTMLURL   string    `json:"html_url"`
		Head      struct{ Ref string `json:"ref"` } `json:"head"`
		Base      struct{ Ref string `json:"ref"` } `json:"base"`
		CreatedAt time.Time `json:"created_at"`
		UpdatedAt time.Time `json:"updated_at"`
	}

	if err := json.Unmarshal(respBytes, &raw); err != nil {
		return nil, fmt.Errorf("unmarshal PR response: %w", err)
	}

	return &PullRequest{
		ID:        raw.ID,
		Number:    raw.Number,
		Title:     raw.Title,
		Body:      raw.Body,
		State:     raw.State,
		IsDraft:   raw.Draft,
		Merged:    raw.Merged,
		Mergeable: raw.Mergeable,
		HTMLURL:   raw.HTMLURL,
		HeadRef:   raw.Head.Ref,
		BaseRef:   raw.Base.Ref,
		CreatedAt: raw.CreatedAt,
		UpdatedAt: raw.UpdatedAt,
	}, nil
}

// UpdatePRBase retargets the base branch of an existing PR (crucial during restacks).
func (c *SyncClient) UpdatePRBase(ctx context.Context, prNumber int, newBase string) error {
	endpoint := fmt.Sprintf("/repos/%s/%s/pulls/%d", c.owner, c.repo, prNumber)
	payload := map[string]string{
		"base": newBase,
	}

	respBytes, status, err := c.sendRequest(ctx, http.MethodPatch, endpoint, payload)
	if err != nil {
		return err
	}
	if status != http.StatusOK {
		return fmt.Errorf("update PR base returned status %d: %s", status, string(respBytes))
	}

	return nil
}

// GetPRStatus queries real-time status of a single PR.
func (c *SyncClient) GetPRStatus(ctx context.Context, prNumber int) (*PullRequest, error) {
	endpoint := fmt.Sprintf("/repos/%s/%s/pulls/%d", c.owner, c.repo, prNumber)

	respBytes, status, err := c.sendRequest(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return nil, err
	}
	if status != http.StatusOK {
		return nil, fmt.Errorf("get PR returned status %d: %s", status, string(respBytes))
	}

	var raw struct {
		ID        int64     `json:"id"`
		Number    int       `json:"number"`
		Title     string    `json:"title"`
		Body      string    `json:"body"`
		State     string    `json:"state"`
		Draft     bool      `json:"draft"`
		Merged    bool      `json:"merged"`
		Mergeable *bool     `json:"mergeable"`
		HTMLURL   string    `json:"html_url"`
		Head      struct{ Ref string `json:"ref"` } `json:"head"`
		Base      struct{ Ref string `json:"ref"` } `json:"base"`
		CreatedAt time.Time `json:"created_at"`
		UpdatedAt time.Time `json:"updated_at"`
	}

	if err := json.Unmarshal(respBytes, &raw); err != nil {
		return nil, err
	}

	return &PullRequest{
		ID:        raw.ID,
		Number:    raw.Number,
		Title:     raw.Title,
		Body:      raw.Body,
		State:     raw.State,
		IsDraft:   raw.Draft,
		Merged:    raw.Merged,
		Mergeable: raw.Mergeable,
		HTMLURL:   raw.HTMLURL,
		HeadRef:   raw.Head.Ref,
		BaseRef:   raw.Base.Ref,
		CreatedAt: raw.CreatedAt,
		UpdatedAt: raw.UpdatedAt,
	}, nil
}

// FormatStackNavigationBody creates an interactive markdown table for stacked PRs.
func FormatStackNavigationBody(customBody string, stack []StackPRItem) string {
	var sb strings.Builder
	if customBody != "" {
		sb.WriteString(customBody)
		sb.WriteString("\n\n")
	}

	sb.WriteString("---\n")
	sb.WriteString("### 🥞 Otto Stacked PR Navigation\n\n")
	sb.WriteString("| # | Branch | Title | Status |\n")
	sb.WriteString("|---|---|---|---|\n")

	for i, item := range stack {
		prefix := ""
		if item.IsCurr {
			prefix = "👉 **Current** "
		}

		link := fmt.Sprintf("[#%d](%s)", item.Number, item.HTMLURL)
		if item.HTMLURL == "" {
			link = fmt.Sprintf("#%d", item.Number)
		}

		sb.WriteString(fmt.Sprintf("| %d | `%s` | %s%s | %s |\n",
			i+1, item.Branch, prefix, item.Title, link))
	}

	sb.WriteString("\n*Stacked by [Otto](https://github.com/otto-stack) atomic PR engine.*\n")
	return sb.String()
}
