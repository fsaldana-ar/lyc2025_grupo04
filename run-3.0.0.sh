## Script para Unix
echo "-------FLEX-------\n"
flex Lexico.l
echo "------BISON-------\n"
bison -dyv Sintactico.y
echo "-------GCC--------\n"
gcc lex.yy.c y.tab.c -o lyc-compiler-3.0.0
echo "----COMPILADOR----\n"
./lyc-compiler-3.0.0 test.txt
rm lyc-compiler-3.0.0
rm lex.yy.c
rm y.tab.c
rm y.output
rm y.tab.h
