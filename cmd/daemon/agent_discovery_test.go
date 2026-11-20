package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestDiscoverAgentProjects(t *testing.T) {
	server := NewDaemonServer()
	projects := server.DiscoverAgentProjects("")
	if projects == nil {
		t.Fatal("expected non-nil discovered projects")
	}
}

func TestDiscoveredProjectsEndpoint(t *testing.T) {
	server := NewDaemonServer()
	mux := http.NewServeMux()
	server.RegisterIntegrationEndpoints(mux)

	req := httptest.NewRequest(http.MethodGet, "/api/agents/discovered-projects?agentId=cursor", nil)
	rr := httptest.NewRecorder()
	mux.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d", rr.Code)
	}

	var res map[string]any
	if err := json.Unmarshal(rr.Body.Bytes(), &res); err != nil {
		t.Fatal(err)
	}
	if res["ok"] != true {
		t.Errorf("expected ok: true, got %v", res["ok"])
	}
}
