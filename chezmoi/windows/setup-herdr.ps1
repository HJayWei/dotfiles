# Install herdr-app (with herdr-core) through scoop and add a WSL distro as a machine.
# Idempotent. Called by bootstrap.sh from WSL; nothing here needs administrator rights.
# ASCII only on purpose: Windows PowerShell 5.1 misreads UTF-8 files without a BOM.
param([Parameter(Mandatory = $true)][string]$Distro)
$ErrorActionPreference = 'Stop'

# Started from WSL the current directory is a UNC path, which cmd-based shims reject.
Set-Location $env:USERPROFILE
$scoop = Join-Path $env:USERPROFILE 'scoop'
$shims = Join-Path $scoop 'shims'
$env:PATH = "$shims;$env:PATH"

if (-not (Test-Path "$shims\scoop.cmd")) {
    Write-Host '==> Installing scoop'
    Invoke-RestMethod get.scoop.sh | Invoke-Expression
    Write-Host '    To use scoop in PowerShell: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser'
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host '==> Installing git (scoop buckets need it)'
    & "$shims\scoop.cmd" install main/git
}
if (-not (Test-Path "$scoop\buckets\extras")) { & "$shims\scoop.cmd" bucket add extras }
if (-not (Test-Path "$shims\herdr-app.exe")) { & "$shims\scoop.cmd" install extras/herdr-app }

# scoop's exit codes are unreliable: check what is actually there.
foreach ($exe in 'herdr-app.exe', 'hc.exe') {
    if (-not (Test-Path "$shims\$exe")) { throw "$exe is missing after scoop install" }
}

$machines = (& "$shims\hc.exe" machine ls --json | ConvertFrom-Json).machines
if ($machines | Where-Object { $_.name -eq 'wsl' }) {
    Write-Host "==> Machine 'wsl' already added"
} else {
    Write-Host "==> Adding $Distro as machine 'wsl'"
    # --cd ~ : otherwise new terminals open in /mnt/c
    & "$shims\hc.exe" machine add --via "wsl.exe -d $Distro --cd ~ -e sh -c" --name wsl --install
    if ($LASTEXITCODE -ne 0) { throw "hc machine add failed ($LASTEXITCODE)" }
}
Write-Host '==> herdr-app is ready. Pick the "glass" layout with ctrl+shift+l.'
