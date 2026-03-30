//go:build linux || darwin

package session

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/anthropics/ai-config/tools/party-cli/internal/state"
	"github.com/anthropics/ai-config/tools/party-cli/internal/tmux"
)

// C2: TOCTOU race — generateSessionID checks HasSession but not the manifest
// store. When another process creates a manifest between check and create,
// Start should retry with a different ID instead of failing.
func TestStart_RetriesOnIDCollision(t *testing.T) {
	t.Parallel()

	storeDir := t.TempDir()
	store, err := state.NewStore(storeDir)
	if err != nil {
		t.Fatal(err)
	}

	// Pre-create manifest for the base ID to simulate a concurrent process
	// claiming it between HasSession and Store.Create.
	if err := store.Create(state.Manifest{PartyID: "party-100"}); err != nil {
		t.Fatal(err)
	}

	runner := &testRunner{fn: func(_ context.Context, args ...string) (string, error) {
		if args[0] == "has-session" {
			return "", &tmux.ExitError{Code: 1} // no tmux session exists
		}
		return "", nil // all other tmux commands succeed
	}}

	svc := &Service{
		Store:       store,
		Client:      tmux.NewClient(runner),
		Now:         func() int64 { return 100 },
		RandSuffix:  func() int64 { return 42 },
		CLIResolver: func(string) (string, error) { return "echo noop", nil },
	}

	result, err := svc.Start(t.Context(), StartOpts{
		Cwd:    t.TempDir(),
		Layout: LayoutClassic,
	})
	if err != nil {
		t.Fatalf("Start should retry on ID collision, got: %v", err)
	}
	if result.SessionID == "party-100" {
		t.Error("should have generated a different session ID after collision")
	}
}

// W4: Cleanup script uses jq without checking availability.
// If jq is not on PATH, the worker-deregistration step silently fails,
// leaving stale entries in the parent manifest.
func TestWriteCleanupScript_ChecksJqAvailability(t *testing.T) {
	t.Parallel()

	dir := t.TempDir()
	path := filepath.Join(dir, "cleanup.sh")

	if err := writeCleanupScript(path, "/tmp/state", "party-test"); err != nil {
		t.Fatal(err)
	}

	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	script := string(data)

	// After fix: script should guard jq usage with an availability check.
	if !strings.Contains(script, "command -v jq") &&
		!strings.Contains(script, "which jq") &&
		!strings.Contains(script, "type jq") {
		t.Error("cleanup script should check for jq availability before using it")
	}
}
