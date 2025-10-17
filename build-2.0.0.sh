## Script para Unix
echo "-------FLEX-------\n"
flex Lexico.l
echo "------BISON-------\n"
bison -dyv Sintactico.y
echo "-------GCC--------\n"
gcc lex.yy.c y.tab.c -o lyc-compiler-2.0.0
echo "----COMPILADOR----\n"
./lyc-compiler-2.0.0 test.txt
echo "-----ELIMINAR-----\n"
rm lex.yy.c
rm y.tab.c
rm y.output
rm y.tab.h
