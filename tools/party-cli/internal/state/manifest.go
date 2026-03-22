// Package state provides manifest CRUD, locking, and session discovery.
package state

// Manifest represents a party session's persisted state.
// JSON field names match the existing bash manifest schema in session/party-lib.sh.
type Manifest struct {
	PartyID     string   `json:"party_id"`
	CreatedAt   string   `json:"created_at,omitempty"`
	UpdatedAt   string   `json:"updated_at,omitempty"`
	Title       string   `json:"title,omitempty"`
	Cwd         string   `json:"cwd,omitempty"`
	WindowName  string   `json:"window_name,omitempty"`
	ClaudeBin   string   `json:"claude_bin,omitempty"`
	CodexBin    string   `json:"codex_bin,omitempty"`
	AgentPath   string   `json:"agent_path,omitempty"`
	SessionType string   `json:"session_type,omitempty"`
	Workers     []string `json:"workers,omitempty"`
}
