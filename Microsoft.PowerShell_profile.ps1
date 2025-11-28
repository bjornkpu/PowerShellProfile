Set-PSReadLineKeyHandler -Key Ctrl+d -Function DeleteCharOrExit

# Load core profile scripts
$profileDir = Split-Path -Parent $PROFILE
$coreFiles = @('constants.ps1', 'aliases.ps1', 'functions.ps1') | ForEach-Object {
    Join-Path $profileDir $_
}
foreach ($f in $coreFiles) {
    if (Test-Path $f) { . $f }
}

Invoke-Expression (&starship init powershell)