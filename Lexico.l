%{
#include <stdio.h>
#include <stdlib.h>

#include "y.tab.h"
FILE  *yyin;
int yylval;
char *yyltext;


int yyerror(void);

%}

%option noyywrap  
%option yylineno 

DIGITO			[0-9]
LETRA			[a-zA-Z]

CTE_INT		        {DIGITO}+
ID			{LETRA}({LETRA}|{DIGITO})*
SUMA			"+"
ASIG			"="
MULT			"*"
RESTA			"-"
DIV			    "/"
PAR_IZQ			"("
PAR_DER			")"
COR_IZQ			"["
COR_DER			"]"
IGUAL			"=="
IF              "IF"|"if"



%%

{CTE_INT}		{printf("\nConstante: %s\n", yytext);return CTE_INT;}
{ID}			{printf("\nIdentificador: %s\n", yytext);return ID;}
{SUMA}			{printf("\nSuma: %s\n", yytext);return SUMA;}
{ASIG}			{printf("\nAsignacion: %s\n", yytext);return ASIG;}
{MULT}			{printf("\nMultiplicacion: %s\n", yytext);return MULT;}
{RESTA}			{printf("\nResta: %s\n", yytext);return RESTA;}
{DIV}			{printf("\nDivision: %s\n", yytext);return DIV;}
{PAR_IZQ}		{printf("\nParAbre: %s\n", yytext);return PAR_IZQ;}
{PAR_DER}		{printf("\nParCierra: %s\n", yytext);return PAR_DER;}
{COR_IZQ}		{printf("\nCorAbre: %s\n", yytext);return COR_IZQ;}
{COR_DER}		{printf("\nCorCierra: %s\n", yytext);return COR_DER;}

"if"           		{ printf("\nIf: %s\n", yytext); return IF; }
"else"          	{ printf("\nElse: %s\n", yytext); return ELSE; }
"while"         	{ printf("\nWhile: %s\n", yytext); return WHILE; }
"for"           	{ printf("\nFor: %s\n", yytext); return FOR; }
"return"        	{ printf("\nReturn: %s\n", yytext); return RETURN; }
"int"           	{ printf("\nInt: %s\n", yytext); return INT; }
"float"         	{ printf("\nFloat: %s\n", yytext); return FLOAT; }
"char"          	{ printf("\nChar: %s\n", yytext); return CHAR; }
"void"          	{ printf("\nVoid: %s\n", yytext); return VOID; }
"=="            	{ printf("\nIgual: %s\n", yytext); return IGUAL; }
"!="            	{ printf("\nDistinto: %s\n", yytext); return DIST; }
"<="            	{ printf("\nMenorIgual: %s\n", yytext); return MENOR_IG; }
">="            	{ printf("\nMayorIgual: %s\n", yytext); return MAYOR_IG; }
"&&"            	{ printf("\nAndLogico: %s\n", yytext); return AND_LOG; }
"||"            	{ printf("\nOrLogico: %s\n", yytext); return OR_LOG; }
"++"            	{ printf("\nIncremento: %s\n", yytext); return INC; }
"--"            	{ printf("\nDecremento: %s\n", yytext); return DEC; }
'!'             	{ printf("\nNotLogico: %s\n", yytext); return NOT_LOG; }
'='             	{ printf("\nAsignacion: %s\n", yytext); return ASIG; }
'<'             	{ printf("\nMenor: %s\n", yytext); return MENOR; }
'>'             	{ printf("\nMayor: %s\n", yytext); return MAYOR; }
'+'             	{ printf("\nSuma: %s\n", yytext); return SUMA; }
'-'             	{ printf("\nResta: %s\n", yytext); return RESTA; }
'*'             	{ printf("\nMultiplicacion: %s\n", yytext); return MULT; }
'/'             	{ printf("\nDivision: %s\n", yytext); return DIV; }
'%'             	{ printf("\nModulo: %s\n", yytext); return MOD; }
','             	{ printf("\nComa: %s\n", yytext); return COMA; }
';'             	{ printf("\nPuntoComa: %s\n", yytext); return PYC; }


"\n"      		
"\t"
"\n\t"
" "             		
"\r\n"
.			 { printf( "ERROR LEXICO : Caracter no reconocido: %s\n", yytext ); exit (0);}


