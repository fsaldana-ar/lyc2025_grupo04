%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "y.tab.h"

int yystopparser = 0;
FILE *yyin;

int yyerror();
int yylex();

/* ============================
   Estructura de la tabla de símbolos
   ============================ */
typedef struct {
    char nombre[50];   // nombre de la variable o constante
    char tipo[10];     // Int, Float, String
    char valor[50];    // valor (solo para constantes)
    int longitud;      // longitud del nombre o del string
} Simbolo;

Simbolo tabla[500];
int indiceTabla = 0;

/* Lista temporal para variables sin tipo aún */
char idsPendientes[500][50];
int cantIdsPendientes = 0;

/* ============================
   Funciones auxiliares
   ============================ */
int existeSimbolo(const char* nombre, const char* tipo) {
    for (int i = 0; i < indiceTabla; i++) {
        if (strcmp(tabla[i].nombre, nombre) == 0 &&
            strcmp(tabla[i].tipo, tipo) == 0) {
            return 1; // ya existe
        }
    }
    return 0;
}

void agregarVariable(const char* nombre, const char* tipo) {
    if (existeSimbolo(nombre, tipo)) return;
    strcpy(tabla[indiceTabla].nombre, nombre);
    strcpy(tabla[indiceTabla].tipo, tipo);
    strcpy(tabla[indiceTabla].valor, "—");
    tabla[indiceTabla].longitud = strlen(nombre);
    indiceTabla++;
}

void agregarConstante(const char* valor, const char* tipo) {
    if (existeSimbolo(valor, tipo)) return;
    strcpy(tabla[indiceTabla].nombre, valor);
    strcpy(tabla[indiceTabla].tipo, tipo);
    strcpy(tabla[indiceTabla].valor, valor);
    tabla[indiceTabla].longitud = strlen(valor);
    indiceTabla++;
}

void volcarTabla() {
    FILE *f = fopen("symbol-table.txt", "w");
    if (!f) {
        printf("No se pudo abrir symbol-table.txt para escritura\n");
        return;
    }

    fprintf(f, "===============================\n");
    fprintf(f, " TABLA DE SÍMBOLOS - LYC 2025 \n");
    fprintf(f, "===============================\n\n");

    fprintf(f, "NOMBRE\t\tTIPODATO\tVALOR\t\tLONGITUD\n");
    fprintf(f, "---------------------------------------------------\n");

    for (int i = 0; i < indiceTabla; i++) {
        fprintf(f, "%s\t\t%s\t\t%s\t\t%d\n",
                tabla[i].nombre,
                tabla[i].tipo,
                tabla[i].valor,
                tabla[i].longitud);
    }

    fclose(f);
    printf("\n>> symbol-table.txt generado correctamente\n");
}
%}

/* ============================
   Tokens (del Lexer)
   ============================ */
%union {
    char cadena[50];
}

%token <cadena> CTE_INT CTE_FLOAT CTE_STR
%token <cadena> ID
%token ASIG
%token SUMA MULT RESTA DIV MOD
%token PAR_IZQ PAR_DER COR_IZQ COR_DER
%token LLA_IZQ LLA_DER DOS_PUNTOS
%token IF ELSE WHILE FOR RETURN
%token INIT READ WRITE
%token <cadena> INT FLOAT STRING
%token IGUAL DIST MENOR_IG MAYOR_IG
%token MENOR MAYOR
%token AND_LOG OR_LOG NOT_LOG
%token AND OR NOT
%token ISZERO CONVDATE
%token COMA PYC

%type <cadena> tipo

%%

/* ============================
   Reglas Sintácticas
   ============================ */

programa:
    lista_sentencias
;

lista_sentencias:
    sentencia
  | lista_sentencias sentencia
;

sentencia:
    asignacion
  | seleccion
  | iteracion
  | declaracion
  | io
;

/* Asignaciones */
asignacion:
    ID ASIG expresion PYC
        { printf("Regla: Asignacion -> ID := Expresion;\n"); }
;

/* Expresiones aritméticas */
expresion:
    termino
  | expresion SUMA termino
  | expresion RESTA termino
;

termino:
    factor
  | termino MULT factor
  | termino DIV factor
  | termino MOD factor   { printf("Regla: Termino -> Termino %% Factor\n"); }
;

factor:
    ID
  | CTE_INT   { agregarConstante($1, "Int"); }
  | CTE_FLOAT { agregarConstante($1, "Float"); }
  | CTE_STR   { agregarConstante($1, "String"); }
  | PAR_IZQ expresion PAR_DER
  | CONVDATE PAR_IZQ expresion RESTA expresion RESTA expresion PAR_DER
;

/* Condiciones */
condicion:
    comparacion
  | ISZERO PAR_IZQ expresion PAR_DER
  | condicion AND comparacion
  | condicion OR comparacion
  | NOT condicion
;

comparacion:
    expresion MENOR expresion
  | expresion MAYOR expresion
  | expresion MENOR_IG expresion
  | expresion MAYOR_IG expresion
  | expresion IGUAL expresion
  | expresion DIST expresion
;

/* If / If-Else */
seleccion:
    IF PAR_IZQ condicion PAR_DER bloque
  | IF PAR_IZQ condicion PAR_DER bloque ELSE bloque
;

/* While */
iteracion:
    WHILE PAR_IZQ condicion PAR_DER bloque
;

/* Bloques de código */
bloque:
    LLA_IZQ lista_sentencias LLA_DER
;

/* Declaraciones de variables */
declaracion:
    INIT LLA_IZQ lista_declaraciones LLA_DER
;

lista_declaraciones:
    declaracion_tipo
  | lista_declaraciones declaracion_tipo
;

declaracion_tipo:
    lista_ids DOS_PUNTOS tipo PYC {
        for (int i = 0; i < cantIdsPendientes; i++) {
            agregarVariable(idsPendientes[i], $3);
        }
        cantIdsPendientes = 0; // limpiar lista
        printf("Regla: Declaracion -> lista_ids : tipo;\n");
    }
;

lista_ids:
    ID { strcpy(idsPendientes[cantIdsPendientes++], $1); }
  | lista_ids COMA ID { strcpy(idsPendientes[cantIdsPendientes++], $3); }
;

tipo:
    INT    { strcpy($$, "Int"); }
  | FLOAT  { strcpy($$, "Float"); }
  | STRING { strcpy($$, "String"); }
;

/* Entrada/Salida */
io:
    READ PAR_IZQ ID PAR_DER PYC
  | WRITE PAR_IZQ expresion PAR_DER PYC
;

%%

/* ============================
   Funciones auxiliares
   ============================ */
int main(int argc, char *argv[]) {
    if((yyin = fopen(argv[1], "rt"))==NULL) {
        printf("\nNo se puede abrir el archivo de prueba: %s\n", argv[1]);
    } else {
        yyparse();
        fclose(yyin);
    }
    // Al finalizar, generar tabla
    volcarTabla();
    return 0;
}

int yyerror(void) {
    printf("Error Sintactico\n");
    exit(1);
}
