<#
functions.ps1
Small interactive functions loaded from Microsoft.PowerShell_profile.ps1
#>

function repos { Set-Location "C:\repos" }

function Import-Profile {
    . $PROFILE
    Write-Host "Reloded"
}
Set-Alias -Name reload -Value Import-Profile


function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }

Set-Alias -Name back -Value Pop-Location

function ff { param($name) Get-ChildItem -Recurse -Filter "*$name*" -ErrorAction SilentlyContinue | Select-Object FullName }

function guid { (New-Guid).Guid.ToString() | Set-Clipboard }

function mkcd {
    param($path)
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    Set-Location $path
}
