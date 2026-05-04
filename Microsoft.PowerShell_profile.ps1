# Load core profile scripts
$profileDir = $PSScriptRoot
$coreFiles = @('constants.ps1', 'aliases.ps1', 'functions.ps1', 'timeline.ps1', 'prompt.ps1') | ForEach-Object {
    Join-Path $profileDir $_
}
foreach ($f in $coreFiles) {
    if (Test-Path $f) { . $f }
}

# Load environment variables (not in version control)
$envFile = Join-Path $profileDir 'env.ps1'
if (Test-Path $envFile) { . $envFile }

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
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
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

$scriptblock = {
    param($wordToComplete, $commandAst, $cursorPosition)
    $Env:_TOBB_COMPLETE = "complete_powershell"
    $Env:_TYPER_COMPLETE_ARGS = $commandAst.ToString()
    $Env:_TYPER_COMPLETE_WORD_TO_COMPLETE = $wordToComplete
    tobb | ForEach-Object {
        $commandArray = $_ -Split ":::"
        $command = $commandArray[0]
        $helpString = $commandArray[1]
        [System.Management.Automation.CompletionResult]::new(
            $command, $command, 'ParameterValue', $helpString)
    }
    $Env:_TOBB_COMPLETE = ""
    $Env:_TYPER_COMPLETE_ARGS = ""
    $Env:_TYPER_COMPLETE_WORD_TO_COMPLETE = ""
}
Register-ArgumentCompleter -Native -CommandName tobb -ScriptBlock $scriptblock
