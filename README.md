# picosh

WezTerm config package for AI-assisted terminal workflows on Windows.

Two features:
- **Image paste** — Ctrl+V with an image in clipboard saves it to a temp file and inserts the path
- **Tab glow** — the active tab pulses blue when Claude Code is waiting for your input

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

Copy these two files to your WezTerm config directory (`~/.config/wezterm/`):

- [`wezterm/wezterm.lua`](wezterm/wezterm.lua)
- [`wezterm/clipboard_image.ps1`](wezterm/clipboard_image.ps1)

## features

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

When Claude Code is waiting for your input (showing `? for shortcuts`), the tab title animates with a blue sine-wave pulse.

Detection: every 150 ms, WezTerm reads the last 5 lines of terminal output via `pane:get_lines_as_text(5)` and checks for the string `? for shortcuts`. When found, `format-tab-title` renders the tab in animated blue (`#4a__ff` where `__` oscillates).

## how it works

```
wezterm.lua
├── update-status (150ms interval)
│   └── get_lines_as_text(5) → match "? for shortcuts"
│       └── waiting_panes[pane_id] = true/false
├── format-tab-title
│   └── if waiting_panes[pane_id]: animate tab color (sine wave)
└── keys["Ctrl+V"]
    └── run_child_process(powershell -STA -File clipboard_image.ps1)
        ├── image found → send path to pane
        └── no image → PasteFrom Clipboard (normal paste)

clipboard_image.ps1 (must run in STA thread)
├── Clipboard::GetImage() → save PNG → print path
└── Clipboard::GetText(Html) → extract img src URL → download → print path
```

## files

```
picosh/
├── wezterm/
│   ├── wezterm.lua          ← main WezTerm config
│   └── clipboard_image.ps1  ← clipboard → file (requires STA)
└── scripts/
    ├── postinstall.js       ← npm postinstall: install WezTerm + copy configs
    └── preuninstall.js      ← npm preuninstall: remove copied configs
```

## requirements

- Windows 10/11
- [WezTerm](https://wezfurlong.org/wezterm/) (installed automatically by postinstall)
- PowerShell 5+ (built into Windows)

## background

Originally a Hyper terminal fork. Switched to WezTerm because Hyper had issues with PSReadLine (predictive completion and command history not working on Windows). WezTerm's Lua API makes both features clean and self-contained without needing to fork the terminal itself.
