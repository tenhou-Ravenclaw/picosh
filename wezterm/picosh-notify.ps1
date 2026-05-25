$val = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes('waiting'))
[Console]::Write([char]27 + "]1337;SetUserVar=picosh_waiting=$val" + [char]7)

$logDir = Join-Path $env:TEMP 'picosh'
New-Item -ItemType Directory -Force $logDir | Out-Null
$logFile = Join-Path $logDir 'notifications.log'

$time = Get-Date -Format 'HH:mm:ss'
$branch = git branch --show-current 2>$null
$repo = Split-Path -Leaf (git rev-parse --show-toplevel 2>$null) 2>$null
$context = if ($repo -and $branch) { " ($repo / $branch)" } else { '' }
Add-Content -Path $logFile -Value "[$time] Claude Code finished$context"
