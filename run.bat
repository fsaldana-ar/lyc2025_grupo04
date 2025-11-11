@echo off
REM ==========================================================
REM  Script de compilación y ejecución en DOSBox (TASM 4.1)
REM  Autor: Vale / Grupo LYC 2025
REM  Compatible con ASM 16 bits generado desde el compilador
REM ==========================================================

REM 1️⃣ Ir a la carpeta raíz del proyecto (donde está final.asm)
cd ..
echo Ejecutando en: %cd%

REM 2️⃣ Agregar temporalmente la carpeta TASM al PATH
set PATH=%~dp0TASM;%PATH%
echo PATH temporal seteado para incluir la carpeta TASM.

REM 3️⃣ Compilar con TASM (modo 16 bits, muestra errores)
tasm /zi /q final.asm
if errorlevel 1 (
    echo ❌ Error en compilacion con TASM.
    goto :fin
)

REM 4️⃣ Enlazar con TLINK
tlink /v final.obj
if errorlevel 1 (
    echo ❌ Error en linkeo con TLINK.
    goto :fin
)

REM 5️⃣ Ejecutar el programa
echo.
echo --- Ejecutando final.exe ---
final.exe
echo --- Fin de la ejecucion ---
echo.

REM 6️⃣ Limpieza opcional (archivos temporales)
if exist final.obj del /q final.obj
if exist final.map del /q final.map

:fin
echo.
pause
