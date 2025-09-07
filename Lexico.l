%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "y.tab.h"
FILE  *yyin;
char *yyltext;

int yyerror(void);

%}

%option noyywrap  
%option yylineno 


DIGITO      [0-9]
LETRA       [a-zA-Z]

CTE_INT     {DIGITO}+
CTE_FLOAT   ({DIGITO}+"."{DIGITO}*)|("."{DIGITO}+)
ID          {LETRA}({LETRA}|{DIGITO})*

%%


"if"            { printf("\nIf: %s\n", yytext); return IF; }
"else"          { printf("\nElse: %s\n", yytext); return ELSE; }
"while"         { printf("\nWhile: %s\n", yytext); return WHILE; }
"for"           { printf("\nFor: %s\n", yytext); return FOR; }
"return"        { printf("\nReturn: %s\n", yytext); return RETURN; }

"init"          { printf("\nInit: %s\n", yytext); return INIT; }
"read"          { printf("\nRead: %s\n", yytext); return READ; }
"write"         { printf("\nWrite: %s\n", yytext); return WRITE; }

"Int"           { printf("\nInt: %s\n", yytext); return INT; }
"Float"         { printf("\nFloat: %s\n", yytext); return FLOAT; }
"String"        { printf("\nString: %s\n", yytext); return STRING; }

"AND"           { printf("\nAnd: %s\n", yytext); return AND; }
"OR"            { printf("\nOr: %s\n", yytext); return OR; }
"NOT"           { printf("\nNot: %s\n", yytext); return NOT; }


"isZero"        { printf("\nIsZero: %s\n", yytext); return ISZERO; }
"convDate"      { printf("\nConvDate: %s\n", yytext); return CONVDATE; }


":="            { printf("\nAsignacion: %s\n", yytext); return ASIG; }
"=:"            { printf("\nAsignacion: %s\n", yytext); return ASIG; }


"+"             { printf("\nSuma: %s\n", yytext); return SUMA; }
"-"             { printf("\nResta: %s\n", yytext); return RESTA; }
"*"             { printf("\nMultiplicacion: %s\n", yytext); return MULT; }
"/"             { printf("\nDivision: %s\n", yytext); return DIV; }
"%"             { printf("\nModulo: %s\n", yytext); return MOD; }


"=="            { printf("\nIgual: %s\n", yytext); return IGUAL; }
"!="            { printf("\nDistinto: %s\n", yytext); return DIST; }
"<="            { printf("\nMenorIgual: %s\n", yytext); return MENOR_IG; }
">="            { printf("\nMayorIgual: %s\n", yytext); return MAYOR_IG; }
"<"             { printf("\nMenor: %s\n", yytext); return MENOR; }
">"             { printf("\nMayor: %s\n", yytext); return MAYOR; }


"&&"            { printf("\nAndLogico: %s\n", yytext); return AND_LOG; }
"||"            { printf("\nOrLogico: %s\n", yytext); return OR_LOG; }
"!"             { printf("\nNotLogico: %s\n", yytext); return NOT_LOG; }


"("             { printf("\nParAbre: %s\n", yytext); return PAR_IZQ; }
")"             { printf("\nParCierra: %s\n", yytext); return PAR_DER; }
"{"             { printf("\nLlaveAbre: %s\n", yytext); return LLA_IZQ; }
"}"             { printf("\nLlaveCierra: %s\n", yytext); return LLA_DER; }
"["             { printf("\nCorAbre: %s\n", yytext); return COR_IZQ; }
"]"             { printf("\nCorCierra: %s\n", yytext); return COR_DER; }
":"             { printf("\nDosPuntos: %s\n", yytext); return DOS_PUNTOS; }
","             { printf("\nComa: %s\n", yytext); return COMA; }
";"             { printf("\nPuntoComa: %s\n", yytext); return PYC; }

{CTE_INT} {
    long val = atol(yytext);
    if (val > 32767 || val < -32768) {
        printf("ERROR LEXICO: Constante entera fuera de rango: %s\n", yytext);
        exit(1);
    }
    printf("\nConstante Entera: %s\n", yytext);
    strcpy(yylval.cadena, yytext);  // Asigna el valor al union
    return CTE_INT;
}

{CTE_FLOAT} {
    printf("\nConstante Real: %s\n", yytext);
    strcpy(yylval.cadena, yytext);  // Asigna el valor al union
    return CTE_FLOAT;
}

\"([^\\"]|\\.)*\" {
    if (strlen(yytext) - 2 > 50) {
        printf("ERROR LEXICO: String demasiado largo: %s\n", yytext);
        exit(1);
    }
    printf("\nConstante String: %s\n", yytext);


    // Remover comillas y copiar el valor
    char valor[50];
    int j = 0;
    for (int i = 1; i < strlen(yytext) - 1; i++) {
        if (yytext[i] == '\\' && yytext[i+1] == '\"') {
            valor[j++] = '\"';
            i++;
        } else {
            valor[j++] = yytext[i];
        }
    }
    valor[j] = '\0';
    
    strcpy(yylval.cadena, valor);
    return CTE_STR;
}

{ID} {
    if (strlen(yytext) > 30) {
        printf("ERROR LEXICO: Identificador demasiado largo: %s\n", yytext);
        exit(1);
    }
    printf("\nIdentificador: %s\n", yytext);
    strcpy(yylval.cadena, yytext);  // Asigna el valor al union
    return ID;
}



"#\+"([^#\n])*"\+#"   { /* ignorar comentario */ }


[ \t\n\r]+      { /* ignorar */ }


.               { printf("ERROR LEXICO : Caracter no reconocido: %s\n", yytext); exit(0); }

%%
