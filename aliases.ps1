<#
aliases.ps1
Central place for interactive aliases. Loaded from Microsoft.PowerShell_profile.ps1
#>

Set-Alias lg lazygit
Set-Alias ld lazydocker

$env:DOCKER_HOST = "npipe:////./pipe/docker_engine"
Set-Alias docker podman
Set-Alias docker-compose podman-compose
