$ErrorActionPreference = "Stop"

$buildLabel = Get-Date -Format "dd/MM/yyyy HH:mm"

Write-Host "Building SPAS web version V$buildLabel"
flutter build web --dart-define="SPAS_BUILD_LABEL=$buildLabel"
