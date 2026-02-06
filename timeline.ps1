# Timeline shell history logger
# Logs every command with timestamp and metadata to ~/.timeline/shell_history.jsonl
# Used by the timeline CLI tool for daily activity tracking.

$timelineLogDir = Join-Path $env:USERPROFILE ".timeline"
$timelineLogPath = Join-Path $timelineLogDir "shell_history.jsonl"

# Ensure log directory exists
if (-not (Test-Path $timelineLogDir)) {
    New-Item -ItemType Directory -Path $timelineLogDir -Force | Out-Null
}

Set-PSReadLineOption -AddToHistoryHandler {
    param([string]$command)

    # Skip empty commands
    if ([string]::IsNullOrWhiteSpace($command)) {
        return $true
    }

    # Skip logging our own logging (prevent recursion)
    if ($command -like '*timeline*shell_history*') {
        return $true
    }

    try {
        $entry = @{
            timestamp = (Get-Date).ToString("o")
            command   = $command
            cwd       = (Get-Location).Path
            shell     = "pwsh"
            pid       = $PID
        } | ConvertTo-Json -Compress

        # Append to log file (thread-safe via mutex)
        $mutex = [System.Threading.Mutex]::new($false, "TimelineShellHistory")
        try {
            $mutex.WaitOne(1000) | Out-Null
            Add-Content -Path $script:timelineLogPath -Value $entry -Encoding utf8
        }
        finally {
            $mutex.ReleaseMutex()
        }
    }
    catch {
        # Never break the shell — silently fail
    }

    return $true
}
