# One-time setup. Run in PowerShell:  powershell -ExecutionPolicy Bypass -File .\setup.ps1
$ErrorActionPreference = 'Continue'  # git writes progress to stderr; check exit codes explicitly
Set-Location $PSScriptRoot
$repoName = 'daily-streak'

if (-not (Get-Command git -ErrorAction SilentlyContinue)) { winget install --id Git.Git -e --silent; Write-Host 'Git installed - close and reopen PowerShell, then run setup again.'; exit }
if (-not (Get-Command gh  -ErrorAction SilentlyContinue)) { winget install --id GitHub.cli -e --silent; Write-Host 'GitHub CLI installed - close and reopen PowerShell, then run setup again.'; exit }

gh auth status 2>$null
if ($LASTEXITCODE -ne 0) { gh auth login --web --git-protocol https }
gh auth setup-git

# Use GitHub's noreply email so commits are linked to your account (and count on the graph)
$login = gh api user --jq .login
$id    = gh api user --jq .id
git config --global --get user.name  | Out-Null; if ($LASTEXITCODE -ne 0) { git config --global user.name $login }

if (-not (Test-Path .git)) { git init -b main | Out-Null }
git config user.name  $login
git config user.email "$id+$login@users.noreply.github.com"

git add -A
git diff --cached --quiet
if ($LASTEXITCODE -ne 0) { git commit -m 'Initial commit' | Out-Null }

gh repo create $repoName --public --source . --remote origin --push

# Schedule: daily at 12:00 + at logon; if the PC was off, run as soon as possible
$ps      = (Get-Command powershell.exe).Source
$action  = New-ScheduledTaskAction -Execute $ps -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSScriptRoot\run-daily.ps1`"" -WorkingDirectory $PSScriptRoot
$triggers = @((New-ScheduledTaskTrigger -Daily -At 12:00), (New-ScheduledTaskTrigger -AtLogOn))
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RunOnlyIfNetworkAvailable
Register-ScheduledTask -TaskName 'DailyStreak' -Action $action -Trigger $triggers -Settings $settings -Force | Out-Null

Write-Host "`nDone. Test it now with:  Start-ScheduledTask -TaskName DailyStreak   (then check run.log)"
