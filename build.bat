@echo off
setlocal enableextensions

set EXE=lyc-compiler-2.0.0.exe

rem Generar lexer y parser
flex Lexico.l || goto :error
bison -dy Sintactico.y || goto :error

rem Compilar
gcc lex.yy.c y.tab.c -o %EXE% || goto :error

:cleanup
rem Borrar intermedios si existen
del /q /f lex.yy.c  2>nul
del /q /f y.tab.c   2>nul
del /q /f y.tab.h   2>nul
del /q /f y.output  2>nul

echo Compilacion completada: %EXE%
exit /b 0

:error
echo Error en la compilacion.
goto :cleanup