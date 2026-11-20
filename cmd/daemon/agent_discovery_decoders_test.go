package main

import (
	"os"
	"path/filepath"
	"testing"
)

func TestDecodeClaudeProjectPath(t *testing.T) {
	home, err := os.UserHomeDir()
	if err != nil {
		t.Skip("no home dir")
	}
	clean := filepath.Clean(home)
	encoded := clean[:1] + "--" + filepath.ToSlash(clean[3:])
	if len(encoded) >= 4 {
		decoded, ok := DecodeClaudeProjectPath(encoded)
		if ok && decoded != "" {
			if _, statErr := os.Stat(decoded); statErr != nil {
				t.Errorf("decoded path does not exist: %s", decoded)
			}
		}
	}
}

func TestExtractPathsFromVscDb(t *testing.T) {
	tmpFile, err := os.CreateTemp("", "test_vsc_*.db")
	if err != nil {
		t.Fatal(err)
	}
	defer os.Remove(tmpFile.Name())

	tempDir := t.TempDir()
	escaped := filepath.ToSlash(tempDir)
	content := []byte(`{"entries":["file:///` + escaped + `","file:///nonexistent/path/123"]}`)
	_ = os.WriteFile(tmpFile.Name(), content, 0644)

	paths := ExtractPathsFromVscDb(tmpFile.Name())
	if paths == nil {
		paths = []string{}
	}
}
