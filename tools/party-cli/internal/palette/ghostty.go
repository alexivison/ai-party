package palette

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"

	"github.com/charmbracelet/lipgloss"
)

type derivedPalette struct {
	MasterRole            lipgloss.Color
	DividerBorder         lipgloss.Color
	PickerDividerLine     lipgloss.Color
	PickerVerticalDivider lipgloss.Color
	SelectedBoxBorder     lipgloss.Color
	SelectedRowBg         lipgloss.Color
	ActivityDim           lipgloss.Color
}

type ghosttyTheme struct {
	Bg      string
	Fg      string
	Palette map[int]string
}

func init() {
	p := resolveDerivedPalette(os.Getenv, userHomeDir(), runtime.GOOS, systemDarkAppearance, os.ReadFile, fileExists)
	MasterRole = p.MasterRole
	DividerBorder = p.DividerBorder
	PickerDividerLine = p.PickerDividerLine
	PickerVerticalDivider = p.PickerVerticalDivider
	SelectedBoxBorder = p.SelectedBoxBorder
	SelectedRowBg = p.SelectedRowBg
	ActivityDim = p.ActivityDim
	MasterRoleANSI = fgANSI(string(MasterRole))
	SelectedRowBgANSI = bgANSI(string(SelectedRowBg))
}

func resolveDerivedPalette(getenv func(string) string, home, goos string, darkAppearance func() bool, readFile func(string) ([]byte, error), exists func(string) bool) derivedPalette {
	p, _, _, ok := loadGhosttyDerived(getenv, home, goos, darkAppearance, readFile, exists)
	if !ok {
		return fallbackDerivedPalette()
	}
	return p
}

func loadGhosttyDerived(getenv func(string) string, home, goos string, darkAppearance func() bool, readFile func(string) ([]byte, error), exists func(string) bool) (derivedPalette, string, string, bool) {
	configPath := findGhosttyConfig(getenv, home, exists)
	if configPath == "" {
		return derivedPalette{}, "", "", false
	}
	configData, err := readFile(configPath)
	if err != nil {
		return derivedPalette{}, "", "", false
	}
	themeName, ok := parseConfiguredTheme(string(configData), selectDarkAppearance(goos, darkAppearance))
	if !ok {
		return derivedPalette{}, "", "", false
	}
	themePath := resolveThemePath(filepath.Dir(configPath), themeName, exists)
	if themePath == "" {
		return derivedPalette{}, configPath, themeName, false
	}
	themeData, err := readFile(themePath)
	if err != nil {
		return derivedPalette{}, configPath, themeName, false
	}
	theme, ok := parseGhosttyTheme(string(themeData))
	if !ok {
		return derivedPalette{}, configPath, themeName, false
	}
	p, ok := derivePalette(theme)
	return p, configPath, themeName, ok
}

func fallbackDerivedPalette() derivedPalette {
	return derivedPalette{
		MasterRole:            "#d0a647",
		DividerBorder:         "#444c56",
		PickerDividerLine:     "#1c2128",
		PickerVerticalDivider: "#555555",
		SelectedBoxBorder:     "#6e7681",
		SelectedRowBg:         "#161b22",
		ActivityDim:           "#555555",
	}
}

func findGhosttyConfig(getenv func(string) string, home string, exists func(string) bool) string {
	candidates := []string{}
	if dir := getenv("GHOSTTY_CONFIG_DIR"); dir != "" {
		candidates = append(candidates, filepath.Join(dir, "config"))
	}
	if dir := getenv("XDG_CONFIG_HOME"); dir != "" {
		candidates = append(candidates, filepath.Join(dir, "ghostty", "config"))
	}
	if home != "" {
		candidates = append(candidates, filepath.Join(home, ".config", "ghostty", "config"))
	}
	for _, path := range candidates {
		if exists(path) {
			return path
		}
	}
	return ""
}

func parseConfiguredTheme(data string, isDark bool) (string, bool) {
	for _, raw := range strings.Split(data, "\n") {
		line := strings.TrimSpace(strings.SplitN(raw, "#", 2)[0])
		key, value, ok := strings.Cut(line, "=")
		if !ok || strings.TrimSpace(key) != "theme" {
			continue
		}
		value = strings.Trim(strings.TrimSpace(value), `"'`)
		if value == "" {
			return "", false
		}
		if !strings.Contains(value, ":") {
			return value, true
		}
		light, dark := "", ""
		for _, part := range strings.Split(value, ",") {
			name, theme, ok := strings.Cut(strings.TrimSpace(part), ":")
			if !ok {
				continue
			}
			switch strings.TrimSpace(name) {
			case "light":
				light = strings.Trim(strings.TrimSpace(theme), `"'`)
			case "dark":
				dark = strings.Trim(strings.TrimSpace(theme), `"'`)
			}
		}
		if isDark && dark != "" {
			return dark, true
		}
		if !isDark && light != "" {
			return light, true
		}
		if dark != "" {
			return dark, true
		}
		return light, light != ""
	}
	return "", false
}

func resolveThemePath(configDir, themeName string, exists func(string) bool) string {
	if filepath.IsAbs(themeName) && exists(themeName) {
		return themeName
	}
	candidate := filepath.Join(configDir, "themes", themeName)
	if exists(candidate) {
		return candidate
	}
	return ""
}

func parseGhosttyTheme(data string) (ghosttyTheme, bool) {
	theme := ghosttyTheme{Palette: make(map[int]string)}
	for _, raw := range strings.Split(data, "\n") {
		line := strings.TrimSpace(raw)
		switch {
		case strings.HasPrefix(line, "background"):
			if _, value, ok := strings.Cut(line, "="); ok {
				theme.Bg = strings.ToLower(strings.TrimSpace(value))
			}
		case strings.HasPrefix(line, "foreground"):
			if _, value, ok := strings.Cut(line, "="); ok {
				theme.Fg = strings.ToLower(strings.TrimSpace(value))
			}
		case strings.HasPrefix(line, "palette"):
			_, value, ok := strings.Cut(line, "=")
			if !ok {
				continue
			}
			idxText, hex, ok := strings.Cut(strings.TrimSpace(value), "=")
			if !ok {
				continue
			}
			idx, err := strconv.Atoi(strings.TrimSpace(idxText))
			if err != nil {
				continue
			}
			theme.Palette[idx] = strings.ToLower(strings.TrimSpace(hex))
		}
	}
	_, ok0 := theme.Palette[0]
	_, ok8 := theme.Palette[8]
	_, ok11 := theme.Palette[11]
	return theme, theme.Bg != "" && theme.Fg != "" && ok0 && ok8 && ok11
}

func derivePalette(theme ghosttyTheme) (derivedPalette, bool) {
	divider, ok := mixHex(theme.Bg, theme.Palette[8], 0.25)
	if !ok {
		return derivedPalette{}, false
	}
	selectedBg, ok := mixHex(theme.Bg, theme.Palette[0], 0.5)
	if !ok {
		return derivedPalette{}, false
	}
	return derivedPalette{
		MasterRole:            lipgloss.Color(theme.Palette[11]),
		DividerBorder:         lipgloss.Color(divider),
		PickerDividerLine:     lipgloss.Color(theme.Bg),
		PickerVerticalDivider: lipgloss.Color(theme.Palette[8]),
		SelectedBoxBorder:     lipgloss.Color(theme.Palette[8]),
		SelectedRowBg:         lipgloss.Color(selectedBg),
		ActivityDim:           lipgloss.Color(theme.Palette[8]),
	}, true
}

func mixHex(a, b string, mix float64) (string, bool) {
	ar, ag, ab, ok := parseHex(a)
	if !ok {
		return "", false
	}
	br, bg, bb, ok := parseHex(b)
	if !ok {
		return "", false
	}
	blend := func(x, y uint8) uint8 { return uint8(float64(x) + (float64(y)-float64(x))*mix + 0.5) }
	return fmt.Sprintf("#%02x%02x%02x", blend(ar, br), blend(ag, bg), blend(ab, bb)), true
}

func parseHex(s string) (uint8, uint8, uint8, bool) {
	if len(s) != 7 || s[0] != '#' {
		return 0, 0, 0, false
	}
	v, err := strconv.ParseUint(s[1:], 16, 32)
	if err != nil {
		return 0, 0, 0, false
	}
	return uint8(v >> 16), uint8(v >> 8), uint8(v), true
}

func fgANSI(hex string) string {
	r, g, b, _ := parseHex(hex)
	return fmt.Sprintf("\033[38;2;%d;%d;%dm", r, g, b)
}

func bgANSI(hex string) string {
	r, g, b, _ := parseHex(hex)
	return fmt.Sprintf("\033[48;2;%d;%d;%dm", r, g, b)
}

func selectDarkAppearance(goos string, darkAppearance func() bool) bool {
	if goos != "darwin" {
		return true
	}
	return darkAppearance()
}

func systemDarkAppearance() bool {
	out, err := exec.Command("defaults", "read", "-g", "AppleInterfaceStyle").Output()
	return err == nil && strings.TrimSpace(string(out)) == "Dark"
}

func userHomeDir() string {
	home, _ := os.UserHomeDir()
	return home
}

func fileExists(path string) bool {
	info, err := os.Stat(path)
	return err == nil && !info.IsDir()
}
