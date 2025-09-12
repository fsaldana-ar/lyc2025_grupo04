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
    char tipo[10];     // siempre "-"
    char valor[50];    // valor (solo para constantes)
    int longitud;      // longitud del string si aplica
} Simbolo;

Simbolo tabla[500];
int indiceTabla = 0;

/* Lista temporal para variables sin tipo aún */
char idsPendientes[500][50];
int cantIdsPendientes = 0;

/* ============================
   Funciones auxiliares
   ============================ */
int existeSimbolo(const char* nombre) {
    for (int i = 0; i < indiceTabla; i++) {
        if (strcmp(tabla[i].nombre, nombre) == 0) {
            return 1; // ya existe
        }
    }
    return 0;
}

void agregarVariable(const char* nombre) {
    if (existeSimbolo(nombre)) return;
    strcpy(tabla[indiceTabla].nombre, nombre);
    strcpy(tabla[indiceTabla].tipo, "-");  
    strcpy(tabla[indiceTabla].valor, "");
    tabla[indiceTabla].longitud = 0;
    indiceTabla++;
}

// Verifica si existe una constante con el mismo valor
int existeConstante(const char* valor) {
    for (int i = 0; i < indiceTabla; i++) {
        if (strcmp(tabla[i].valor, valor) == 0) {
            return 1; // constante duplicada
        }
    }
    return 0;
}

void agregarConstante(const char* valor, const char* tipo) {
    if (existeConstante(valor)) return;

    char nombreUnico[50];

    if (strcmp(tipo, "Int") == 0 || strcmp(tipo, "Float") == 0) {
       
        sprintf(nombreUnico, "_%s", valor);
    } 
    else if (strcmp(tipo, "String") == 0) {
       
        static int contadorString = 1;
        sprintf(nombreUnico, "const_string_%d", contadorString++);
    } 
    else {
        
        sprintf(nombreUnico, "const_%d", indiceTabla);
    }

    strcpy(tabla[indiceTabla].nombre, nombreUnico);
    strcpy(tabla[indiceTabla].tipo, "-");
    strcpy(tabla[indiceTabla].valor, valor);

    if (strcmp(tipo, "String") == 0)
        tabla[indiceTabla].longitud = strlen(valor);
    else
        tabla[indiceTabla].longitud = 0;

    indiceTabla++;
}

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

    for (int i = 0; i < ancho_total; i++) fprintf(f, "=");
    fprintf(f, "\n");
    fprintf(f, "%*s\n", (ancho_total + 30) / 2, "TABLA DE SÍMBOLOS - LYC 2025");
    for (int i = 0; i < ancho_total; i++) fprintf(f, "=");
    fprintf(f, "\n\n");

    fprintf(f, "%-*s %-*s %-*s %-*s\n",
            ANCHO_NOMBRE, "NOMBRE",
            ANCHO_TIPO,   "TIPO",
            ANCHO_VALOR,  "VALOR",
            ANCHO_LONG,   "LONGITUD");

    for (int i = 0; i < ancho_total; i++) fprintf(f, "-");
    fprintf(f, "\n");

    for (int i = 0; i < indiceTabla; i++) {
        char longitudStr[20];
        if (tabla[i].longitud > 0)
            sprintf(longitudStr, "%d", tabla[i].longitud);
        else
            strcpy(longitudStr, "-");

        fprintf(f, "%-*s %-*s %-*s %-*s\n",
                ANCHO_NOMBRE, tabla[i].nombre,
                ANCHO_TIPO,   "-",             
                ANCHO_VALOR,  tabla[i].valor,
                ANCHO_LONG,   longitudStr);
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
    lista_sentencias  { printf(" FIN\n"); }
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
    ID ASIG expresion PYC   { 
        if (!existeSimbolo($1)) {
            printf("ADVERTENCIA: Variable '%s' no declarada con INIT\n", $1);
            agregarVariable($1);
        }
        printf("    ID := Expresion es ASIGNACION\n"); 
    }
;

/* Expresiones aritméticas */
expresion:
    termino                  { printf("    Termino es Expresion\n"); }
  | expresion SUMA termino  { printf("    Expresion+Termino es Expresion\n"); }
  | expresion RESTA termino { printf("    Expresion-Termino es Expresion\n"); }
;

termino:
    factor                 { printf("    Factor es Termino\n"); }
  | termino MULT factor  { printf("     Termino*Factor es Termino\n"); }
  | termino DIV factor   { printf("     Termino/Factor es Termino\n"); }
  | termino MOD factor   { printf("     Termino%%Factor es Termino\n"); }
;

factor:
    ID   { printf("    ID es Factor\n"); }
  | CTE_INT   { 
        agregarConstante($1, "Int"); 
        printf("    CTE es Factor\n"); 
    } 
  | CTE_FLOAT { 
        agregarConstante($1, "Float"); 
        printf("    CTE es Factor\n"); 
    }
  | CTE_STR   { 
        agregarConstante($1, "String"); 
        printf("    CTE es Factor\n"); 
    }
  | PAR_IZQ expresion PAR_DER { printf("    Expresion entre parentesis es Factor\n"); }
  | CONVDATE PAR_IZQ expresion RESTA expresion RESTA expresion PAR_DER {
        char fechaStr[20];
        sprintf(fechaStr, "fecha_%d", indiceTabla);
        agregarVariable(fechaStr);
        printf("    convDate(Expresion-Expresion-Expresion) es Factor\n");
    }
;

/* Condiciones */
condicion:
    comparacion 
  | ISZERO PAR_IZQ expresion PAR_DER { printf("    ISZERO(Expresion) es Condicion\n"); }
  | condicion AND comparacion { printf("    Condicion AND Comparacion es Condicion\n"); }
  | condicion OR comparacion { printf("    Condicion OR Comparacion es Condicion\n"); }
  | NOT condicion { printf("    NOT Condicion es Condicion\n"); }
;

comparacion:
    expresion MENOR expresion { printf("    Expresion<Expresion es Comparacion\n"); }
  | expresion MAYOR expresion { printf("    Expresion>Expresion es Comparacion\n"); }
  | expresion MENOR_IG expresion { printf("    Expresion<=Expresion es Comparacion\n"); }
  | expresion MAYOR_IG expresion { printf("    Expresion>=Expresion es Comparacion\n"); }
  | expresion IGUAL expresion { printf("    Expresion==Expresion es Comparacion\n"); }
  | expresion DIST expresion { printf("    Expresion!=Expresion es Comparacion\n"); }
;

/* If / If-Else */
seleccion:
    IF PAR_IZQ condicion PAR_DER bloque { printf("    IF(Condicion)Bloque es Seleccion\n"); }
  | IF PAR_IZQ condicion PAR_DER bloque ELSE bloque { printf("    IF(Condicion)Bloque ELSE Bloque es Seleccion\n"); }
;

/* While */
iteracion:
    WHILE PAR_IZQ condicion PAR_DER bloque { printf("    WHILE(Condicion)Bloque es Iteracion\n"); }
;

/* Bloques de código */
bloque:
    LLA_IZQ lista_sentencias LLA_DER { printf("    {Lista_sentencias} es Bloque\n"); }
;

/* Declaraciones de variables */
declaracion:
    INIT LLA_IZQ lista_declaraciones LLA_DER { printf("    INIT{Lista_declaraciones} es Declaracion\n"); }
;

lista_declaraciones:
    declaracion_tipo 
  | lista_declaraciones declaracion_tipo 
;

declaracion_tipo:
    lista_ids DOS_PUNTOS tipo PYC {
        for (int i = 0; i < cantIdsPendientes; i++) {
            agregarVariable(idsPendientes[i]);
        }
        cantIdsPendientes = 0;
        printf("    Lista_ids:Tipo; es Declaracion_tipo\n");
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
    READ PAR_IZQ ID PAR_DER PYC  { printf("    READ(ID) es IO\n"); }
  | WRITE PAR_IZQ expresion PAR_DER PYC { printf("    WRITE(Expresion) es IO\n"); }
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
    volcarTabla();
    return 0;
}

int yyerror(void) {
    printf("Error Sintactico\n");
    exit(1);
}
