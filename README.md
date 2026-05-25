# picosh

WezTerm config package for AI-assisted terminal workflows on Windows.

Features:
- **Image paste** — Ctrl+V with an image in clipboard saves it to a temp file and inserts the path
- **Tab glow** — the active tab pulses blue when Claude Code is waiting for your input
- **Status bar** — shows current directory and git branch in the right status
- **Keyboard shortcuts** — tab/pane management without touching the mouse

## install

**PowerShell (recommended — no Node.js required):**

```powershell
irm https://raw.githubusercontent.com/tenhou-Ravenclaw/picosh/master/install.ps1 | iex
```

**npm:**

```sh
npm install -g picosh
```

**Uninstall:**

```powershell
irm https://raw.githubusercontent.com/tenhou-Ravenclaw/picosh/master/uninstall.ps1 | iex
```

### manual setup

Copy these files to your WezTerm config directory (`~/.config/wezterm/`):

- [`wezterm/picosh.lua`](wezterm/picosh.lua)
- [`wezterm/clipboard_image.ps1`](wezterm/clipboard_image.ps1)
- [`wezterm/picosh-notify.ps1`](wezterm/picosh-notify.ps1)

Then add this to your `wezterm.lua` before `return config`:

```lua
require('picosh').apply(config)
```

## features

### keyboard shortcuts

| Key | Action |
|-----|--------|
| Ctrl+T | New tab |
| Ctrl+W | Close pane (or tab if last pane) |
| Ctrl+Tab | Next tab |
| Ctrl+Shift+Tab | Previous tab |
| Ctrl+1~9 | Jump to tab by number |
| Ctrl+D | Split pane right |
| Ctrl+Shift+D | Split pane down |
| Alt+↑↓←→ | Move between panes |
| Ctrl+Z | Zoom/unzoom active pane |
| Ctrl+V | Paste image from clipboard |
| Ctrl+Shift+N | Open notification log |

### image paste

Press **Ctrl+V** when an image is in the clipboard. Instead of pasting nothing (or broken text), picosh:

1. Saves the image to `%TEMP%\picosh\clip_latest.png`
2. Inserts that file path into the terminal at the cursor

Works with:
- Screenshots (bitmap from clipboard)
- Images copied from browsers (downloads from `<img src>` URL in HTML clipboard)

If the clipboard contains plain text, normal paste behavior is preserved.

**Why the PowerShell script?** Windows clipboard requires an [STA thread](https://learn.microsoft.com/en-us/windows/win32/com/single-threaded-apartments) (`-STA` flag). WezTerm's Lua cannot access the clipboard directly, so it shells out to a PowerShell script with `-STA`.

### tab glow

When Claude Code is waiting for your input (showing `? for shortcuts`), the tab title animates with a blue sine-wave pulse and a `●` dot appears in the right status bar.

Detection: every 150 ms, WezTerm reads the last 5 lines of terminal output via `pane:get_lines_as_text(5)` and checks for the string `? for shortcuts`. A toast notification fires on the leading edge (idle → waiting transition).

Claude Code's `Stop` hook also sends an OSC 1337 `SetUserVar` signal via `picosh-notify.ps1`, which triggers the glow before the text is even visible.

### status bar

The right status shows the current directory name and git branch when inside a git repo.

```
picosh  master
```

Updates every 150 ms by parsing the PowerShell prompt (`PS C:\path>`) from terminal text.

### notification log

Press **Ctrl+Shift+N** to open a live log of Claude Code completions in a new tab.

Each entry shows timestamp, repo name, and branch:

```
[10:34:21] Claude Code finished (picosh / master)
```

## how it works

```
picosh.lua
├── user-var-changed (OSC 1337 SetUserVar from picosh-notify.ps1)
│   └── waiting_panes[pane_id] = true  (fires before text is visible)
├── update-status (150ms interval)
│   ├── get_lines_as_text(5) → match "? for shortcuts"
│   │   └── waiting_panes[pane_id] = true/false
│   ├── toast notification on idle→waiting transition
│   ├── get_lines_as_text(50) → parse PS prompt → git branch
│   └── set_right_status: "dir  branch" + animated ● when waiting
├── format-tab-title
│   └── if waiting_panes[pane_id]: animate tab color (sine wave)
└── keys
    ├── Ctrl+V → powershell -STA -File clipboard_image.ps1
    │   ├── image found → send path to pane
    │   └── no image → PasteFrom Clipboard (normal paste)
    ├── Ctrl+T / Ctrl+W / Ctrl+Tab / Ctrl+1~9 → tab management
    ├── Ctrl+D / Ctrl+Shift+D → split pane
    ├── Alt+arrows → move between panes
    ├── Ctrl+Z → zoom pane
    └── Ctrl+Shift+N → open notification log tab

picosh-notify.ps1 (Claude Code Stop hook)
├── Write OSC 1337 SetUserVar=picosh_waiting to stdout
└── Append to %TEMP%\picosh\notifications.log

clipboard_image.ps1 (must run in STA thread)
├── Clipboard::GetImage() → save PNG → print path
└── Clipboard::GetText(Html) → extract img src URL → download → print path
```

## files

```
picosh/
├── wezterm/
│   ├── picosh.lua           ← main module (require'd by wezterm.lua)
│   ├── wezterm.lua          ← starter template
│   ├── picosh-notify.ps1    ← Claude Code Stop hook → OSC signal + log
│   └── clipboard_image.ps1  ← clipboard → file (requires STA)
└── scripts/
    ├── postinstall.js       ← npm postinstall: copy configs + register hook
    └── preuninstall.js      ← npm preuninstall: remove configs + hook
```

## requirements

- Windows 10/11
- [WezTerm](https://wezfurlong.org/wezterm/) (installed automatically)
- PowerShell 5+ (built into Windows)

## background

Originally a Hyper terminal fork. Switched to WezTerm because Hyper had issues with PSReadLine (predictive completion and command history not working on Windows). WezTerm's Lua API makes all features clean and self-contained without needing to fork the terminal itself.
