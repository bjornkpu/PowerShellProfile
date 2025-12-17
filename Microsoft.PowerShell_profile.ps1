# Load core profile scripts
$profileDir = Split-Path -Parent $PROFILE
$coreFiles = @('constants.ps1', 'aliases.ps1', 'functions.ps1') | ForEach-Object {
    Join-Path $profileDir $_
}
foreach ($f in $coreFiles) {
    if (Test-Path $f) { . $f }
}

if ($host.Name -eq 'ConsoleHost') {
    Import-Module PSReadLine

    # Wrap PSReadLine options in try-catch to handle unsupported environments
    try {
        Set-PSReadLineOption -PredictionSource History -ErrorAction Stop
        Set-PSReadLineOption -PredictionViewStyle ListView -ErrorAction Stop
    }
    catch {
        # Prediction features not supported in this environment (e.g., VS Code terminal)
    }

    Set-PSReadLineOption -EditMode Windows
    Set-PSReadLineKeyHandler -Key UpArrow -Function PreviousHistory
    Set-PSReadLineKeyHandler -Key DownArrow -Function NextHistory
    Set-PSReadLineKeyHandler -Key Ctrl+d -Function DeleteCharOrExit
    Set-PSReadLineKeyHandler -Key Alt+r -ScriptBlock {
        [Microsoft.PowerShell.PSConsoleReadLine]::ClearScreen()
        . $PROFILE
    }
    Set-PSReadLineKeyHandler -Key Ctrl+r -Function ReverseSearchHistory
    Set-PSReadLineKeyHandler -Key Ctrl+s -Function ForwardSearchHistory
}

# $env:PS_DEV_MODE = $true
$omp_config = $profileDir + "\oh-my-posh-themes\bkpuns.omp.json"
oh-my-posh init pwsh --config $omp_config | Invoke-Expression