# PowerShell Profile

Personal PowerShell profile with custom prompt, aliases, and utilities.

## Requirements

- [Oh My Posh](https://ohmyposh.dev/): `winget install JanDeDobbeleer.OhMyPosh`
- [PSReadLine](https://github.com/PowerShell/PSReadLine): `Install-Module PSReadLine`

## Structure

- [Microsoft.PowerShell_profile.ps1](Microsoft.PowerShell_profile.ps1) - Main profile entry point
- [constants.ps1](constants.ps1) - Environment variables
- [aliases.ps1](aliases.ps1) - Command aliases (lg, ld, docker→podman)
- [functions.ps1](functions.ps1) - Utility functions (repos, .., guid, mkcd, ff)
- [oh-my-posh-themes/](oh-my-posh-themes/) - Custom Oh My Posh themes
