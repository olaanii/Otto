package server

import (
	"net/http"
	"time"

	"otto-daemon/internal/llm"
)

// ProvidersResponse holds active and detected AI model providers.
type ProvidersResponse struct {
	Providers []llm.ProviderInfo `json:"providers"`
	Timestamp time.Time          `json:"timestamp"`
}

// HandleGetProviders serves GET /api/llm/providers.
func (s *Server) HandleGetProviders(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	var providers []llm.ProviderInfo
	if s.llmGateway != nil {
		providers = s.llmGateway.ListProviders(ctx)
	} else {
		providers = []llm.ProviderInfo{}
	}

	writeJSON(w, http.StatusOK, ProvidersResponse{
		Providers: providers,
		Timestamp: time.Now(),
	})
}
