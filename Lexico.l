%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "y.tab.h"
extern FILE *yyin;
int yyerror(void);

/* Contexto para convDate: dentro de sus paréntesis tratamos '-' como separador */
static int inConvDate = 0;
static int convDepth = 0;
%}

%option noyywrap
%option yylineno

DIGITO      [0-9]
LETRA       [a-zA-Z]
DATE		({DIGITO}{DIGITO}"-"{DIGITO}{DIGITO}"-"{DIGITO}{DIGITO}{DIGITO}{DIGITO})
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
"Date"			{ return DATE; }
"String"        { return STRING; }
"isZero"        { return ISZERO; }
"convDate"      { inConvDate = 1; convDepth = 0; return DATE; }
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
"-"             { return inConvDate ? GUION : RESTA; }
"*"             { return MULT; }
"/"             { return DIV; }
"%"             { return MOD; }

"("             { if (inConvDate) convDepth++; return PAR_IZQ; }
")"             { if (inConvDate && --convDepth <= 0) { inConvDate = 0; convDepth = 0; } return PAR_DER; }
"{"             { return LLA_IZQ; }
"}"             { return LLA_DER; }
"["             { return COR_IZQ; }
"]"             { return COR_DER; }
":"             { return DOS_PUNTOS; }
","             { return COMA; }
";"             { return PYC; }
"."             { return PUNTO; }

"#\+"([^#\n])*"\+#"   { /* ignorar comentario */ }

{CTE_INT} {
    long v = atol(yytext);

    /* Int de 16 bits con signo: rango -32768 a 32767 */
    if (v > 32767 || v < -32768) {
        printf("ERROR LEXICO: Constante entera fuera de rango (Int 16 bits): %s\n", yytext);
        exit(1);
    }

    printf("\nConstante Entera (Int 16 bits): %s\n", yytext);
    strcpy(yylval.cadena, yytext);
    return CTE_INT;
}

{CTE_FLOAT} {
    /* Float IEEE 754 simple precisión (aprox. ±3.4E38) */
    double val = atof(yytext);

    if (val > 3.4e38 || val < -3.4e38) {
        printf("ERROR LEXICO: Constante flotante fuera de rango (Float 32 bits): %s\n", yytext);
        exit(1);
    }

    /* Validar formato: separador decimal debe ser '.' */
    if (strchr(yytext, ',') != NULL) {
        printf("ERROR LEXICO: separador decimal inválido, use '.' en lugar de ',' (%s)\n", yytext);
        exit(1);
    }

    printf("\nConstante Real (Float 32 bits): %s\n", yytext);
    strcpy(yylval.cadena, yytext);
    return CTE_FLOAT;
}

{DATE} {
    /* Validar formato: debe tener el formato DD-MM-YYYY */
    int d, m, y;
	sscanf(yytext, "%2d-%2d-%4d", &d, &m, &y);
	if (d < 1 || d > 31 || m < 1 || m > 12) {
    	printf("ERROR LEXICO: Fecha invalida (%s)\n", yytext);
    	exit(1);
	}

    printf("\nConvdate (Convdate 32 bits): %s\n", yytext);
    strcpy(yylval.cadena, yytext);
    return DATE;
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
    printf("\nID detectado: %s\n", yytext);
    strcpy(yylval.cadena, yytext);
    return ID;
}

[ \t\r\n]+    { }
.             { printf("ERROR LEXICO: %s\n", yytext); exit(1); }

%%
