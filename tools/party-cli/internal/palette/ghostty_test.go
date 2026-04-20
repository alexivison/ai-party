package palette

import (
	"os"
	"path/filepath"
	"testing"
)

func TestParseGhosttyTheme(t *testing.T) {
	t.Parallel()

	theme, ok := parseGhosttyTheme(`
background = #1c2128
foreground = #cdd9e5
palette = 0=#373e47
palette = 8=#768390
palette = 11=#d29922
`)
	if !ok {
		t.Fatal("expected theme parse to succeed")
	}
	if got := theme.Bg; got != "#1c2128" {
		t.Fatalf("background = %q, want #1c2128", got)
	}
	if got := theme.Fg; got != "#cdd9e5" {
		t.Fatalf("foreground = %q, want #cdd9e5", got)
	}
	if got := theme.Palette[11]; got != "#d29922" {
		t.Fatalf("palette[11] = %q, want #d29922", got)
	}
}

func TestParseConfiguredThemePlain(t *testing.T) {
	t.Parallel()

	got, ok := parseConfiguredTheme("font-size = 14\ntheme = GitHub Dark Dimmed\n", true)
	if !ok || got != "GitHub Dark Dimmed" {
		t.Fatalf("parseConfiguredTheme plain = (%q, %v), want (%q, true)", got, ok, "GitHub Dark Dimmed")
	}
}

func TestParseConfiguredThemeAppearanceSplit(t *testing.T) {
	t.Parallel()

	config := "theme = light:GitHub Light,dark:GitHub Dark Dimmed\n"
	if got, ok := parseConfiguredTheme(config, false); !ok || got != "GitHub Light" {
		t.Fatalf("light theme = (%q, %v), want (%q, true)", got, ok, "GitHub Light")
	}
	if got, ok := parseConfiguredTheme(config, true); !ok || got != "GitHub Dark Dimmed" {
		t.Fatalf("dark theme = (%q, %v), want (%q, true)", got, ok, "GitHub Dark Dimmed")
	}
}

func TestResolveDerivedPaletteMissingConfigFallsBack(t *testing.T) {
	t.Parallel()

	got := resolveDerivedPalette(func(string) string { return "" }, "", "darwin", func() bool { return true }, func(string) ([]byte, error) {
		t.Fatal("readFile should not be called when config is missing")
		return nil, nil
	}, func(string) bool { return false })

	if got != fallbackDerivedPalette() {
		t.Fatalf("fallback palette = %#v, want %#v", got, fallbackDerivedPalette())
	}
}

func TestMixHex(t *testing.T) {
	t.Parallel()

	if got, ok := mixHex("#1c2128", "#555555", 0.25); !ok || got != "#2a2e33" {
		t.Fatalf("mixHex divider = (%q, %v), want (%q, true)", got, ok, "#2a2e33")
	}
	if got, ok := mixHex("#1c2128", "#373e47", 0.5); !ok || got != "#2a3038" {
		t.Fatalf("mixHex selected row = (%q, %v), want (%q, true)", got, ok, "#2a3038")
	}
}

func TestLoadGhosttyDerivedFromConfig(t *testing.T) {
	t.Parallel()

	root := t.TempDir()
	configDir := filepath.Join(root, "ghostty")
	themesDir := filepath.Join(configDir, "themes")
	if err := os.MkdirAll(themesDir, 0o755); err != nil {
		t.Fatalf("mkdir themes: %v", err)
	}
	configPath := filepath.Join(configDir, "config")
	themePath := filepath.Join(themesDir, "dimmed")
	if err := os.WriteFile(configPath, []byte("theme = dimmed\n"), 0o644); err != nil {
		t.Fatalf("write config: %v", err)
	}
	if err := os.WriteFile(themePath, []byte("background = #1c2128\nforeground = #cdd9e5\npalette = 0=#373e47\npalette = 8=#768390\npalette = 11=#d29922\n"), 0o644); err != nil {
		t.Fatalf("write theme: %v", err)
	}

	p, usedConfig, themeName, ok := loadGhosttyDerived(
		func(key string) string {
			if key == "GHOSTTY_CONFIG_DIR" {
				return configDir
			}
			return ""
		},
		"",
		"darwin",
		func() bool { return true },
		os.ReadFile,
		fileExists,
	)
	if !ok {
		t.Fatal("expected derived palette to load")
	}
	if usedConfig != configPath {
		t.Fatalf("config path = %q, want %q", usedConfig, configPath)
	}
	if themeName != "dimmed" {
		t.Fatalf("theme name = %q, want dimmed", themeName)
	}
	if got := string(p.MasterRole); got != "#d29922" {
		t.Fatalf("master role = %q, want #d29922", got)
	}
	if got := string(p.PickerVerticalDivider); got != "#768390" {
		t.Fatalf("picker vertical divider = %q, want #768390", got)
	}
}
