## Script para Unix
echo "-------FLEX-------\n"
flex Lexico.l
echo "------BISON-------\n"
bison -dyv Sintactico.y
echo "-------GCC--------\n"
gcc lex.yy.c y.tab.c -o compilador
echo "----COMPILADOR----\n"
./compilador prueba.txt
echo "-----ELIMINAR-----\n"
./compilador prueba.txt
rm lex.yy.c
rm y.tab.c
rm y.output
rm y.tab.h
rm compilador
