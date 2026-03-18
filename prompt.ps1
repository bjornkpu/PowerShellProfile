# Pure PowerShell prompt — replaces Oh My Posh

$script:ESC = [char]27
$script:RESET = "$script:ESC[0m"

# Nerd Font glyphs
$script:PL_LEFT = [char]0xe0b6   # powerline left (solid)
$script:PL_RIGHT = [char]0xe0b4  # powerline right (solid)
$script:FOLDER = [char]0xe5ff
$script:BRANCH = [char]0xe0a0
$script:MODIFIED = [char]0xf044
$script:STAGED = [char]0xf046
$script:STASH = [char]0xeb4b

# Theme colors (RGB)
function script:Fg($r, $g, $b) { "$script:ESC[38;2;${r};${g};${b}m" }
function script:Bg($r, $g, $b) { "$script:ESC[48;2;${r};${g};${b}m" }

$script:C_BG = Bg 41 49 90    # #29315A
$script:C_BG_FG = Fg 41 49 90    # for diamond trailing on default bg
$script:C_PATH_FG = Fg 62 198 105  # #3EC669
$script:C_GIT_CLEAN = Fg 67 204 234 # #43CCEA
$script:C_GIT_MOD = Fg 255 146 72  # #FF9248
$script:C_GIT_DIV = Fg 255 69 0    # #ff4500
$script:C_GIT_AB = Fg 179 136 255 # #B388FF
$script:C_PROMPT = Fg 99 240 140  # #63F08C
$script:C_EXEC = Fg 255 235 59  # #ffeb3b
$script:C_ERROR = Fg 255 69 0    # red for error status
$script:C_DIM = Fg 120 120 140

# Execution time tracking
$global:_PromptStopwatch = [System.Diagnostics.Stopwatch]::new()

# Hook into PSReadLine to start timer before each command
if (Get-Module PSReadLine) {
    Set-PSReadLineOption -AddToHistoryHandler {
        param($line)
        $global:_PromptStopwatch.Restart()
        return $true
    }
}

function script:Get-GitInfo {
    $info = @{
        InRepo  = $false
        Branch  = ''
        Working = 0
        Staged  = 0
        Stash   = 0
        Ahead   = 0
        Behind  = 0
    }

    $toplevel = git rev-parse --show-toplevel 2>$null
    if (-not $toplevel) { return $info }
    $info.InRepo = $true

    # Branch + status in one call
    $status = git status --porcelain -b 2>$null
    if ($status) {
        $lines = $status -split "`n"
        # First line: ## branch...upstream [ahead N, behind N]
        $header = $lines[0]
        if ($header -match '## (.+?)(?:\.{3}|$)') {
            $info.Branch = $Matches[1]
        }
        if ($header -match 'ahead (\d+)') { $info.Ahead = [int]$Matches[1] }
        if ($header -match 'behind (\d+)') { $info.Behind = [int]$Matches[1] }

        # Count working/staged changes
        foreach ($line in $lines[1..($lines.Count - 1)]) {
            if ($line.Length -lt 2) { continue }
            $idx = $line[0]
            $wt = $line[1]
            if ($idx -ne ' ' -and $idx -ne '?') { $info.Staged++ }
            if ($wt -ne ' ') { $info.Working++ }
        }
    }

    # Stash count
    $stashes = git stash list 2>$null
    if ($stashes) { $info.Stash = ($stashes | Measure-Object).Count }

    return $info
}

function script:Format-Path {
    $p = $executionContext.SessionState.Path.CurrentLocation.Path
    $home_ = $HOME.TrimEnd('\')
    if ($p.StartsWith($home_, [StringComparison]::OrdinalIgnoreCase)) {
        $p = '~' + $p.Substring($home_.Length)
    }
    return $p
}

function prompt {
    $lastSuccess = $?
    $lastExit = $LASTEXITCODE
    $elapsed = $global:_PromptStopwatch.Elapsed
    $global:_PromptStopwatch.Reset()

    $out = [System.Text.StringBuilder]::new()

    # === LINE 1 ===

    # Leading diamond
    [void]$out.Append("$script:RESET$(Fg 41 49 90)$script:PL_LEFT")

    # Path segment
    $path = Format-Path
    [void]$out.Append("$script:C_BG$script:C_PATH_FG $script:FOLDER $path ")

    # Git segment
    $git = Get-GitInfo
    if ($git.InRepo) {
        $hasChanges = ($git.Working -gt 0) -or ($git.Staged -gt 0)
        $isDiverged = ($git.Ahead -gt 0) -and ($git.Behind -gt 0)

        if ($isDiverged) { $gitColor = $script:C_GIT_DIV }
        elseif ($hasChanges) { $gitColor = $script:C_GIT_MOD }
        else { $gitColor = $script:C_GIT_CLEAN }

        [void]$out.Append("${gitColor}$script:BRANCH $($git.Branch)")

        if ($git.Staged -gt 0) {
            [void]$out.Append(" $script:STAGED $($git.Staged)")
        }
        if ($git.Working -gt 0) {
            [void]$out.Append(" $script:MODIFIED $($git.Working)")
        }
        if ($git.Stash -gt 0) {
            [void]$out.Append(" $script:STASH $($git.Stash)")
        }
        if ($git.Ahead -gt 0 -or $git.Behind -gt 0) {
            $abText = ''
            if ($git.Ahead -gt 0) { $abText += " ↑$($git.Ahead)" }
            if ($git.Behind -gt 0) { $abText += " ↓$($git.Behind)" }
            [void]$out.Append("$script:C_GIT_AB$abText")
        }
        [void]$out.Append(' ')
    }

    # Trailing diamond
    [void]$out.Append("$script:RESET$script:C_BG_FG$script:PL_RIGHT$script:RESET")

    # === LINE 2 ===
    [void]$out.Append("`n")

    # Execution time (if > 500ms)
    if ($elapsed.TotalMilliseconds -gt 500) {
        $ms = [math]::Round($elapsed.TotalMilliseconds)
        if ($elapsed.TotalSeconds -ge 60) {
            $fmt = '{0}m {1}s' -f [math]::Floor($elapsed.TotalMinutes), ($elapsed.Seconds)
        }
        elseif ($elapsed.TotalSeconds -ge 1) {
            $fmt = '{0:N1}s' -f $elapsed.TotalSeconds
        }
        else {
            $fmt = "${ms}ms"
        }
        [void]$out.Append("$script:C_EXEC${fmt} ")
    }

    # Status (non-zero exit or failed command)
    if (-not $lastSuccess) {
        $code = if ($lastExit) { $lastExit } else { 1 }
        [void]$out.Append("$script:C_ERROR<$code> ")
    }

    # Prompt icon
    [void]$out.Append("$script:C_PROMPT>$script:RESET ")

    # Restore LASTEXITCODE so it doesn't get clobbered by git calls
    $global:LASTEXITCODE = $lastExit

    return $out.ToString()
}
