# Script para ejecutar DOSBox y compilar/ejecutar final.asm
# Busca DOSBox en ubicaciones comunes

$dosboxPaths = @(
    "C:\Program Files (x86)\DOSBox-0.74-3\DOSBox.exe",
    "C:\Program Files\DOSBox-0.74-3\DOSBox.exe",
    "C:\Program Files (x86)\DOSBox-0.74\DOSBox.exe",
    "C:\Program Files\DOSBox-0.74\DOSBox.exe",
    "$env:LOCALAPPDATA\DOSBox\DOSBox.exe"
)

$dosboxExe = $null
foreach ($path in $dosboxPaths) {
    if (Test-Path $path) {
        $dosboxExe = $path
        break
    }
}

if ($dosboxExe -eq $null) {
    Write-Host "ERROR: No se encontro DOSBox." -ForegroundColor Red
    pause
    exit 1
}

# Crear archivo temporal de configuración para DOSBox
$projectPath = $PSScriptRoot
$confFile = Join-Path $projectPath "dosbox_temp.conf"

$confContent = @"
[autoexec]
@echo off
mount C "$projectPath"
C:
cls
echo ================================================
echo   Compilador LYC 2025 - Grupo 04
echo ================================================
echo.
echo Compilando con TASM...
asm\TASM\tasm final.asm
if errorlevel 1 goto error
echo.
echo Linkeando con TLINK...
asm\TASM\tlink final.obj
if errorlevel 1 goto error
echo.
echo Ejecutando programa...
echo.
final.exe
echo.
echo ================================================
goto fin
:error
echo ERROR en compilacion
:fin
"@

$confContent | Out-File -FilePath $confFile -Encoding ASCII

# Ejecutar DOSBox con la configuración
& $dosboxExe -conf $confFile

# Limpiar archivo temporal
Remove-Item $confFile -ErrorAction SilentlyContinue
