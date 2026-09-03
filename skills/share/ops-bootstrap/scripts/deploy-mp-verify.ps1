#Requires -Version 5.1
$Helper = Join-Path $PSScriptRoot "helpers\deploy_mp_verify.ps1"
& $Helper @args
