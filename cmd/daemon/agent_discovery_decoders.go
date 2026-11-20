package main

import (
	"net/url"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

// DecodeClaudeProjectPath decodes Claude project dir names (e.g., C--Users-olani-Desktop-olani-Otto).
func DecodeClaudeProjectPath(encoded string) (string, bool) {
	if len(encoded) < 4 || encoded[1] != '-' || encoded[2] != '-' {
		return "", false
	}
	drive := strings.ToUpper(encoded[:1]) + `:\`
	tokens := strings.Split(encoded[3:], "-")
	candidate := drive

	for i := 0; i < len(tokens); i++ {
		tryPath := filepath.Join(candidate, tokens[i])
		if fi, err := os.Stat(tryPath); err == nil && fi.IsDir() {
			candidate = tryPath
			continue
		}
		merged := tokens[i]
		found := false
		for j := i + 1; j < len(tokens); j++ {
			merged += "-" + tokens[j]
			tryMerged := filepath.Join(candidate, merged)
			if fi, err := os.Stat(tryMerged); err == nil && fi.IsDir() {
				candidate = tryMerged
				i = j
				found = true
				break
			}
		}
		if !found {
			candidate = tryPath
		}
	}

	clean := filepath.Clean(candidate)
	if fi, err := os.Stat(clean); err == nil && fi.IsDir() {
		return clean, true
	}
	return "", false
}

var vscUriRegex = regexp.MustCompile(`file:///[a-zA-Z](?:%3A|:)/[^\s"'<>\x00-\x1F]+`)

// ExtractPathsFromVscDb extracts verified folder paths from VS Code / Cursor state.vscdb files.
func ExtractPathsFromVscDb(vscdbPath string) []string {
	content, err := os.ReadFile(vscdbPath)
	if err != nil {
		return nil
	}
	matches := vscUriRegex.FindAllString(string(content), -1)
	seen := make(map[string]bool)
	var paths []string

	for _, m := range matches {
		u, _ := url.PathUnescape(m)
		p := strings.TrimPrefix(u, "file:///")
		p = strings.ReplaceAll(p, "%3A", ":")
		p = strings.ReplaceAll(p, "%3a", ":")
		p = filepath.Clean(strings.ReplaceAll(p, "/", `\`))

		for len(p) > 3 {
			if fi, sErr := os.Stat(p); sErr == nil && fi.IsDir() {
				lower := strings.ToLower(p)
				if !seen[lower] {
					seen[lower] = true
					paths = append(paths, p)
				}
				break
			}
			idx := strings.LastIndexAny(p, `\ `)
			if idx <= 2 {
				break
			}
			p = p[:idx]
		}
	}
	return paths
}
