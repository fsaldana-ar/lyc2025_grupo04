%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "y.tab.h"
extern FILE *yyin;
int yyerror(void);


%}

%option noyywrap
%option yylineno

DIGITO      [0-9]
LETRA       [a-zA-Z]
CONVDATET   ({DIGITO}{1,2}"-"{DIGITO}{1,2}"-"{DIGITO}{4})
CTE_INT     -?{DIGITO}+
CTE_FLOAT   -?({DIGITO}+"."{DIGITO}*)|("."{DIGITO}+)
ID          {LETRA}({LETRA}|{DIGITO})*

%%

"if"            { return IF; }
"else"          { return ELSE; }
"while"         { return WHILE; }
"init"          { return INIT; }
"read"          { return READ; }
"write"         { return WRITE; }
"Int"           { return INT; }
"Float"         { return FLOAT; }
"Date"          { return DATE; }
"String"        { return STRING; }
"isZero"        { return ISZERO; }
"convDate"      { return CONVDATE; } 
"AND"           { return AND; }
"OR"            { return OR; }
"NOT"           { return NOT; }
"and"           { return AND; }
"or"            { return OR; }
"not"           { return NOT; }

":="|"=:"       { return ASIG; }

"=="            { return IGUAL; }
"!="            { return DIST; }
"<="            { return MENOR_IG; }
">="            { return MAYOR_IG; }
"<"             { return MENOR; }
">"             { return MAYOR; }

"+"             { return SUMA; }
"-"             { return RESTA; } 
"*"             { return MULT; }
"/"             { return DIV; }
"%"             { return MOD; }

"("             { return PAR_IZQ; } 
")"             { return PAR_DER; } 
"{"             { return LLA_IZQ; }
"}"             { return LLA_DER; }
"["             { return COR_IZQ; }
"]"             { return COR_DER; }
":"             { return DOS_PUNTOS; }
","             { return COMA; }
";"             { return PYC; }
"."             { return PUNTO; }


#\+([-a-zA-Z0-9 _.,;:!¡¿?='"()<>/*+=:%{}\[\]]*)\+#
#\+([^#\n]*)                                    { printf("ERROR LEXICO: comentario sin cierre +# en linea %d\n", yylineno); exit(1); }
#\+([^a-zA-Z0-9 _.,;:!¡¿?='"()/*+\-=: \n#][^#\n]*)\+# { printf("ERROR LEXICO: comentario contiene caracteres inválidos en línea %d\n", yylineno); exit(1); }




{CTE_INT} {
    long v = atol(yytext);
    /* Int de 16 bits con signo: rango -32768 a 32767 */
    if (v > 32767 || v < -32768) {
        printf("ERROR LEXICO: Constante entera fuera de rango (Int 16 bits): %s\n", yytext);
        exit(1);
    }
    strcpy(yylval.cadena, yytext);
    return CTE_INT;
}

{CTE_FLOAT} {
    double val = atof(yytext);
    if (val > 3.4e38 || val < -3.4e38) {
        printf("ERROR LEXICO: Constante flotante fuera de rango (Float 32 bits): %s\n", yytext);
        exit(1);
    }
    if (strchr(yytext, ',') != NULL) {
        printf("ERROR LEXICO: separador decimal inválido, use '.' en lugar de ',' (%s)\n", yytext);
        exit(1);
    }
    strcpy(yylval.cadena, yytext);
    return CTE_FLOAT;
}

{CONVDATET} {
    int d, m, y;
    if (sscanf(yytext, "%d-%d-%d", &d, &m, &y) != 3 || y < 1000) {
        printf("ERROR LEXICO: Fecha debe tener formato DD-MM-YYYY (%s)\n", yytext);
        exit(1);
    }
    if (d < 1 || d > 31 || m < 1 || m > 12) {
        printf("ERROR LEXICO: Fecha invalida (dia o mes fuera de rango): %s\n", yytext);
        exit(1);
    }

    strcpy(yylval.cadena, yytext);
    return CONVDATET;
}


\"([^\\"]|\\.)*\" {
    int len = (int)strlen(yytext) - 2;
    if (len > 50) { printf("ERROR LEXICO: string largo\n"); exit(1); }
    char val[60]; int j=0;
    for (int i=1;i<(int)strlen(yytext)-1;i++){
        if(yytext[i]=='\\' && yytext[i+1]=='\"'){ val[j++]='\"'; i++; }
        else val[j++]=yytext[i];
    }
    val[j]='\0';
    strcpy(yylval.cadena,val);
    return CTE_STR;
}

{ID} {
    if(strlen(yytext)>30){ printf("ERROR LEXICO: id largo\n"); exit(1); }
    strcpy(yylval.cadena, yytext);
    return ID;
}

[ \t\r\n]+    { /* Ignorar espacios */ }
.             { printf("ERROR LEXICO: Caracter no reconocido '%s' en linea %d\n", yytext, yylineno); exit(1); }

%%

