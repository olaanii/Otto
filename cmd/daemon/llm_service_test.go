package main

import (
	"context"
	"testing"
	"time"
)

func TestDetectLocalClis(t *testing.T) {
	clis := DetectLocalClis()
	if len(clis) == 0 {
		t.Fatal("Expected at least one CLI tool in detection list")
	}

	foundAntigravity := false
	for _, c := range clis {
		if c.ID == "antigravity" {
			foundAntigravity = true
			if !c.Installed {
				t.Log("Antigravity binary not found in standard paths")
			}
		}
	}
	if !foundAntigravity {
		t.Error("Expected antigravity tool definition in DetectLocalClis")
	}
}

func TestTestCliConnectionNonExistent(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	ok, msg := TestCliConnection(ctx, "non_existent_cli_12345")
	if ok {
		t.Errorf("Expected failure for non-existent CLI, got ok=true: %s", msg)
	}
}
