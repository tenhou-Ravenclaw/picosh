#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$REPO     = 'tenhou-Ravenclaw/picosh'
$BRANCH   = 'master'
$RAW      = "https://raw.githubusercontent.com/$REPO/$BRANCH"
$CONFIG   = Join-Path $HOME '.config\wezterm'
$CLAUDE   = Join-Path $HOME '.claude\settings.json'

$FILES = @('picosh.lua', 'picosh-notify.ps1', 'clipboard_image.ps1')

function Test-WezTerm {
  $paths = @(
    (Join-Path $env:LOCALAPPDATA 'Programs\WezTerm\wezterm.exe'),
    'C:\Program Files\WezTerm\wezterm.exe'
  )
  return ($paths | Where-Object { Test-Path $_ }).Count -gt 0
}

function Install-WezTerm {
  Write-Host '[picosh] Installing WezTerm...'
  winget install wez.wezterm --silent
}

function Download-File($name) {
  $url  = "$RAW/wezterm/$name"
  $dest = Join-Path $CONFIG $name
  $bak  = "$dest.bak"
  if (Test-Path $dest) {
    Copy-Item $dest $bak -Force
    Write-Host "[picosh] Backed up $name"
  }
  Invoke-RestMethod $url -OutFile $dest
  Write-Host "[picosh] Installed $name"
}

function Set-WeztermLua {
  $lua = Join-Path $CONFIG 'wezterm.lua'
  if (-not (Test-Path $lua)) {
    $starter = Invoke-RestMethod "$RAW/wezterm/wezterm.lua"
    Set-Content $lua $starter -Encoding UTF8
    Write-Host '[picosh] Created wezterm.lua (starter template)'
  } else {
    $content = Get-Content $lua -Raw
    if ($content -notmatch "require\(['""]picosh['""]") {
      Write-Host '[picosh] wezterm.lua already exists. Add this line before "return config":'
      Write-Host ''
      Write-Host "  require('picosh').apply(config)"
      Write-Host ''
    }
  }
}

function Register-ClaudeHook {
  $script   = Join-Path $CONFIG 'picosh-notify.ps1'
  $command  = "powershell.exe -NoProfile -NonInteractive -File `"$script`""
  $dir      = Split-Path $CLAUDE
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }

  $settings = if (Test-Path $CLAUDE) {
    Get-Content $CLAUDE -Raw | ConvertFrom-Json
  } else {
    [pscustomobject]@{}
  }

  if (-not $settings.hooks) {
    $settings | Add-Member -NotePropertyName hooks -NotePropertyValue ([pscustomobject]@{})
  }
  if (-not $settings.hooks.Stop) {
    $settings.hooks | Add-Member -NotePropertyName Stop -NotePropertyValue @()
  }

  $already = $settings.hooks.Stop | Where-Object {
    $_.hooks | Where-Object { $_.command -like '*picosh-notify*' }
  }

  if (-not $already) {
    $entry = [pscustomobject]@{
      matcher = ''
      hooks   = @([pscustomobject]@{ type = 'command'; command = $command })
    }
    $settings.hooks.Stop += $entry
    $settings | ConvertTo-Json -Depth 10 | Set-Content $CLAUDE -Encoding UTF8
    Write-Host '[picosh] Registered Stop hook in ~/.claude/settings.json'
  } else {
    Write-Host '[picosh] Stop hook already registered'
  }
}

# ─── main ────────────────────────────────────────────────────────────────────

Write-Host '[picosh] Installing picosh...'
Write-Host ''

if (-not (Test-WezTerm)) { Install-WezTerm }

New-Item -ItemType Directory -Force $CONFIG | Out-Null
foreach ($f in $FILES) { Download-File $f }
Set-WeztermLua
Register-ClaudeHook

Write-Host ''
Write-Host '[picosh] Done! Launch WezTerm to start using picosh.'
