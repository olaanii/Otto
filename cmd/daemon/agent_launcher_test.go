package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestLaunchAgentHandshakeURL(t *testing.T) {
	url := launchAgentHandshake("antigravity", "C:/test/repo", "token123")
	if !strings.Contains(url, "token=token123") || !strings.Contains(url, "agentId=antigravity") {
		t.Fatalf("Unexpected auth URL: %s", url)
	}
}

func TestProvisionOttoBridge(t *testing.T) {
	tmpDir := t.TempDir()
	provisionOttoBridge(tmpDir)

	rulePath := filepath.Join(tmpDir, ".agents", "rules", "otto.md")
	data, err := os.ReadFile(rulePath)
	if err != nil {
		t.Fatalf("Failed to read provisioned rule: %v", err)
	}
	if !strings.Contains(string(data), "http://localhost:3000") {
		t.Fatalf("Rule does not contain daemon address: %s", string(data))
	}
}
