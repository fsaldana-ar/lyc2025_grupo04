%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "y.tab.h"

int yystopparser = 0;
extern FILE *yyin;

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
    strcpy(tabla[indiceTabla].valor, "");
    /* Aca adaptamos con la longitud de toda la variable 
    tabla[indiceTabla].longitud = strlen(nombre);
    */
    tabla[indiceTabla].longitud = 0;
    indiceTabla++;
}
// Verifica si existe una constante con el mismo valor y tipo
int existeConstante(const char* valor, const char* tipo) {
    for (int i = 0; i < indiceTabla; i++) {
        if (strcmp(tabla[i].tipo, tipo) == 0 &&
            strcmp(tabla[i].valor, valor) == 0) {
            return 1; // constante duplicada
        }
    }
    return 0;
}

void agregarConstante(const char* valor, const char* tipo) {
    // Verificar si ya existe constante con mismo valor y tipo
    if (existeConstante(valor, tipo)) return;
    // Crear nombre único para constantes
    char nombreUnico[50];
    sprintf(nombreUnico, "const_%s_%d", tipo, indiceTabla);
    
    strcpy(tabla[indiceTabla].nombre, nombreUnico);
    strcpy(tabla[indiceTabla].tipo, tipo);
    strcpy(tabla[indiceTabla].valor, valor);
    tabla[indiceTabla].longitud = strlen(valor);
    indiceTabla++;
}

/*
void volcarTabla() {
    FILE *f = fopen("symbol-table.txt", "w");
    if (!f) {
        printf("No se pudo abrir symbol-table.txt para escritura\n");
        return;
    }

    fprintf(f, "=====================================================\n");
    fprintf(f, "               TABLA DE SÍMBOLOS - LYC 2025          \n");
    fprintf(f, "=====================================================\n\n");

    fprintf(f, "%-50s %-10s %-50s %-10s\n", "NOMBRE", "TIPO", "VALOR", "LONGITUD");
    fprintf(f, "-----------------------------------------------------\n");

    for (int i = 0; i < indiceTabla; i++) {
        /* Acá arma la tabla mostrando todo
        
        fprintf(f, "%-15s %-10s %-20s %-10d\n",
                tabla[i].nombre,
                tabla[i].tipo,
                tabla[i].valor,
                tabla[i].longitud);
        }
    }

    fprintf(f, "\nTotal de entradas: %d\n", indiceTabla);
    fclose(f);
    printf("\n>> symbol-table.txt generado correctamente\n");
}*/
void volcarTabla() {
    FILE *f = fopen("symbol-table.txt", "w");
    if (!f) {
        printf("No se pudo abrir symbol-table.txt para escritura\n");
        return;
    }

    const int ANCHO_NOMBRE = 50;
    const int ANCHO_TIPO   = 10;
    const int ANCHO_VALOR  = 50;
    const int ANCHO_LONG   = 10;

    int ancho_total = ANCHO_NOMBRE + ANCHO_TIPO + ANCHO_VALOR + ANCHO_LONG + 3; 
    // +3 por los espacios entre columnas

    // Encabezado
    for (int i = 0; i < ancho_total; i++) fprintf(f, "=");
    fprintf(f, "\n");
    fprintf(f, "%*s\n", (ancho_total + 30) / 2, "TABLA DE SÍMBOLOS - LYC 2025");
    for (int i = 0; i < ancho_total; i++) fprintf(f, "=");
    fprintf(f, "\n\n");

    // Títulos
    fprintf(f, "%-*s %-*s %-*s %-*s\n",
            ANCHO_NOMBRE, "NOMBRE",
            ANCHO_TIPO,   "TIPO",
            ANCHO_VALOR,  "VALOR",
            ANCHO_LONG,   "LONGITUD");

    for (int i = 0; i < ancho_total; i++) fprintf(f, "-");
    fprintf(f, "\n");

    // Contenido
    for (int i = 0; i < indiceTabla; i++) {
        if (strcmp(tabla[i].tipo, "String") == 0) {
            fprintf(f, "%-*s %-*s %-*s %*d\n",
                    ANCHO_NOMBRE, tabla[i].nombre,
                    ANCHO_TIPO,   "",
                    ANCHO_VALOR,  tabla[i].valor,
                    ANCHO_LONG,   tabla[i].longitud);
        } else {
            fprintf(f, "%-*s %-*s %-*s %*d\n",
                    ANCHO_NOMBRE, tabla[i].nombre,
                    ANCHO_TIPO,   "",
                    ANCHO_VALOR,  tabla[i].valor,
                    ANCHO_LONG,   0);
        }
    }

    fprintf(f, "\nTotal de entradas: %d\n", indiceTabla);
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
    asignacion  { printf("Sentencia -> Asignacion\n"); }
  | seleccion   { printf("Sentencia -> Seleccion\n"); }
  | iteracion   { printf("Sentencia -> Iteracion\n"); }
  | declaracion { printf("Sentencia -> Declaracion\n"); }
  | io
;

/* Asignaciones */
asignacion:
    ID ASIG expresion PYC {
        // Verificar si la variable fue declarada
        if (!existeSimbolo($1, "Int") && !existeSimbolo($1, "Float") && 
            !existeSimbolo($1, "String") && !existeSimbolo($1, "Date")) {
            printf("ADVERTENCIA: Variable '%s' no declarada con INIT\n", $1);
            // Opcional: agregarla automáticamente con tipo inferido
            agregarVariable($1, "Int"); // Asumimos Int por defecto
        }
        printf("Asignacion -> ID := Expresion;\n"); 
    }
;

/* Expresiones aritméticas */
expresion:
    termino                  { printf("Expresion -> Termino\n"); }
  | expresion SUMA termino  { printf("Expresion -> Expresion + Termino\n"); }
  | expresion RESTA termino { printf("Expresion -> Expresion - Termino\n"); }
;

termino:
    factor
  | termino MULT factor  { printf("Termino -> Termino * Factor\n"); }
  | termino DIV factor   { printf("Termino -> Termino %/ Factor\n"); }
  | termino MOD factor   { printf("Termino -> Termino %% Factor\n"); }
;

factor:
    ID
  | CTE_INT   { agregarConstante($1, "Int"); }
  | CTE_FLOAT { agregarConstante($1, "Float"); }
  | CTE_STR   { agregarConstante($1, "String"); }
  | PAR_IZQ expresion PAR_DER
  | CONVDATE PAR_IZQ expresion RESTA expresion RESTA expresion PAR_DER {
        // Crear un nombre único para la fecha convertida
        char fechaStr[20];
        sprintf(fechaStr, "fecha_%d", indiceTabla);
        agregarVariable(fechaStr, "Date");
        printf("Regla: ConvDate procesada\n");
    }
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
