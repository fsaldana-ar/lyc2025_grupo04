:: Script para windows
flex Lexico.l
bison -dyv Sintactico.y

gcc.exe lex.yy.c y.tab.c -o lyc-compiler-1.0.0.exe

lyc-compiler-1.0.0.exe prueba.txt

@echo off
del lex.yy.c
del y.tab.c
del y.tab.h
del y.output

pause
