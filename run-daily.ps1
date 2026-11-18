# Daily job: add one entry, commit, push. Safe to run multiple times a day.
$ErrorActionPreference = 'Continue'  # git writes progress to stderr; check exit codes explicitly
Set-Location $PSScriptRoot
$logFile = Join-Path $PSScriptRoot 'run.log'
function Log($m) { "$(Get-Date -Format 's')  $m" | Add-Content -Path $logFile }

try {
    # Get any entry the cloud job already added, so we don't duplicate it
    git pull --rebase --autostash 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { git rebase --abort 2>&1 | Out-Null; Log 'WARN: initial pull failed (offline?)' }

    $today    = Get-Date -Format 'yyyy-MM-dd'
    $logDir   = Join-Path $PSScriptRoot 'log'
    New-Item -ItemType Directory -Force $logDir | Out-Null
    $monthFile = Join-Path $logDir ((Get-Date -Format 'yyyy-MM') + '.md')

    $alreadyDone = (Test-Path $monthFile) -and (Select-String -Path $monthFile -Pattern "^## $today" -Quiet)
    if (-not $alreadyDone) {
        $tips = @(Get-Content (Join-Path $PSScriptRoot 'tips.txt') | Where-Object { $_.Trim() })
        $count = 0
        Get-ChildItem $logDir -Filter *.md | ForEach-Object {
            $count += @(Select-String -Path $_.FullName -Pattern '^## ').Count
        }
        $tip = $tips[$count % $tips.Count]

        if (-not (Test-Path $monthFile)) {
            Add-Content -Path $monthFile -Encoding utf8 -Value "# $(Get-Date -Format 'MMMM yyyy')`n"
        }
        Add-Content -Path $monthFile -Encoding utf8 -Value "## $today`n`nEntry #$($count + 1): $tip`n"
        Log "Added entry for $today"
    }

    git add -A
    git diff --cached --quiet
    if ($LASTEXITCODE -ne 0) {
        git commit -m "Daily entry $today" | Out-Null
        Log 'Committed'
    }

    git push 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        git pull --rebase --autostash 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { git rebase --abort 2>&1 | Out-Null; throw 'git pull failed' }
        git push 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'git push failed' }
    }
    Log 'Pushed OK'
}
catch {
    Log "ERROR: $_"
    exit 1
}
