::CONFIG ZipUrl=https://sfes26.sigicre.net/games.zip
::CONFIG DestName=芝浦祭2026_ゲーム

@echo off
setlocal EnableExtensions
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$p='%~f0'; $t=Join-Path $env:TEMP ('zip-sync-'+[guid]::NewGuid().ToString()+'.ps1'); $all=Get-Content -LiteralPath $p -Encoding UTF8; $config=@{}; foreach($line in $all) { if($line -match '^::CONFIG ZipUrl=(.*)$') { $config.ZipUrl=$Matches[1] } elseif($line -match '^::CONFIG DestName=(.*)$') { $config.DestName=$Matches[1] } }; $lines=$all | Where-Object { $_.StartsWith('::PS ') } | ForEach-Object { $_.Substring(5) }; if (-not $lines) { Write-Host 'Could not prepare the sync script.'; exit 1 }; $utf8=New-Object System.Text.UTF8Encoding($false); [System.IO.File]::WriteAllLines($t, [string[]]$lines, $utf8); try { & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $t -BatDir '%~dp0' -ZipUrl $config.ZipUrl -DestName $config.DestName; exit $LASTEXITCODE } finally { Remove-Item -LiteralPath $t -Force -ErrorAction SilentlyContinue }"
set "RC=%ERRORLEVEL%"
echo.
if not "%RC%"=="0" (
  echo Sync failed. The existing folder was left unchanged.
) else (
  echo Sync finished.
)
echo.
pause
endlocal & exit /b %RC%

::PS param([string]$BatDir, [string]$ZipUrl, [string]$DestName)
::PS
::PS $ErrorActionPreference = 'Stop'
::PS [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
::PS
::PS $batDir = $BatDir.TrimEnd('\')
::PS $dest = Join-Path $batDir $DestName
::PS $tempZip = Join-Path ([System.IO.Path]::GetTempPath()) ('zip-sync-' + [guid]::NewGuid().ToString() + '.zip')
::PS $staging = Join-Path ([System.IO.Path]::GetTempPath()) ('zip-sync-' + [guid]::NewGuid().ToString())
::PS
::PS try {
::PS   if ([string]::IsNullOrWhiteSpace($ZipUrl)) { throw 'ZipUrl is empty.' }
::PS   if ([string]::IsNullOrWhiteSpace($DestName) -or $DestName -match '[\\/:]') {
::PS     throw 'DestName must be a single folder name.'
::PS   }
::PS
::PS   Write-Host "Downloading: $ZipUrl"
::PS   Invoke-WebRequest -Uri $ZipUrl -OutFile $tempZip -UseBasicParsing
::PS   if (-not (Test-Path -LiteralPath $tempZip) -or (Get-Item -LiteralPath $tempZip).Length -eq 0) {
::PS     throw 'Download produced an empty file.'
::PS   }
::PS
::PS   New-Item -ItemType Directory -Path $staging | Out-Null
::PS   Write-Host 'Extracting...'
::PS   Expand-Archive -LiteralPath $tempZip -DestinationPath $staging -Force
::PS
::PS   if (Test-Path -LiteralPath $dest) {
::PS     $resolvedDest = (Resolve-Path -LiteralPath $dest).Path.TrimEnd('\')
::PS     $resolvedBat = (Resolve-Path -LiteralPath $batDir).Path.TrimEnd('\')
::PS     if (-not $resolvedDest.StartsWith($resolvedBat + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
::PS       throw 'Refusing to delete a folder outside the script directory.'
::PS     }
::PS     Write-Host "Replacing: $dest"
::PS     Remove-Item -LiteralPath $dest -Recurse -Force
::PS   } else {
::PS     Write-Host "Creating: $dest"
::PS   }
::PS
::PS   Move-Item -LiteralPath $staging -Destination $dest
::PS   $staging = $null
::PS   Write-Host 'Done.'
::PS   exit 0
::PS } catch {
::PS   Write-Host "Failed: $($_.Exception.Message)"
::PS   exit 1
::PS } finally {
::PS   if ($tempZip -and (Test-Path -LiteralPath $tempZip)) {
::PS     Remove-Item -LiteralPath $tempZip -Force -ErrorAction SilentlyContinue
::PS   }
::PS   if ($staging -and (Test-Path -LiteralPath $staging)) {
::PS     Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue
::PS   }
::PS }
