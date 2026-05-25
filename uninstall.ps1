#Requires -Version 5.1
$CONFIG = Join-Path $HOME '.config\wezterm'
$CLAUDE = Join-Path $HOME '.claude\settings.json'
$FILES  = @('picosh.lua', 'picosh-notify.ps1', 'clipboard_image.ps1')

foreach ($f in $FILES) {
  $dest = Join-Path $CONFIG $f
  $bak  = "$dest.bak"
  if (Test-Path $dest) {
    Remove-Item $dest -Force
    Write-Host "[picosh] Removed $f"
    if (Test-Path $bak) {
      Rename-Item $bak $dest
      Write-Host "[picosh] Restored $f from backup"
    }
  }
}

if (Test-Path $CLAUDE) {
  $s = Get-Content $CLAUDE -Raw | ConvertFrom-Json
  if ($s.hooks -and $s.hooks.Stop) {
    $s.hooks.Stop = @($s.hooks.Stop | Where-Object {
      -not ($_.hooks | Where-Object { $_.command -like '*picosh-notify*' })
    })
    $s | ConvertTo-Json -Depth 10 | Set-Content $CLAUDE -Encoding UTF8
    Write-Host '[picosh] Unregistered Stop hook'
  }
}

Write-Host '[picosh] Uninstall complete.'
