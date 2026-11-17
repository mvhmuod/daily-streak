# daily-streak

A tiny automation that adds one dev tip to `log/YYYY-MM.md` every day,
commits it, and pushes it to GitHub — so the contribution graph stays filled.

- `run-daily.ps1` – the daily job (idempotent: runs at most once per day)
- `tips.txt` – the pool of tips it cycles through (add your own!)
- `setup.ps1` – one-time setup (creates the repo, schedules the job)
