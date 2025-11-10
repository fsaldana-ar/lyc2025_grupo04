%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "y.tab.h"
#define MAX_POLACA 4096

int yystopparser = 0;
extern FILE *yyin;

int yyerror();
int yylex();

/* ============================
   Tabla de sÃ­mbolos
   ============================ */
typedef struct {
    char nombre[50];   // nombre de la variable o constante
    char tipo[10];     // "Int" | "Float" | "String" | "-" (no tipada aÃºn)
    char valor[50];    // valor (solo para constantes)
    int  longitud;     // longitud del string si aplica
} Simbolo;

Simbolo tabla[500];
int indiceTabla = 0;
/* Errores semÃ¡nticos acumulados */
int erroresSemanticos = 0;

/* CÃ³digo intermedio (polaca inversa) */
char codigoIntermedio[MAX_POLACA][256];
int  indiceCodigo = 0;

int pilaSaltos[MAX_POLACA];
int topePilaSaltos = -1;

/* GeneraciÃ³n de etiquetas y pilas para IF/WHILE */
int  nextEtiqueta = 1;
char pilaElse[100][16]; int topeElse = -1;
char pilaEnd [100][16]; int topeEnd  = -1;
char pilaIni [100][16]; int topeIni  = -1;
char pilaFin [100][16]; int topeFin  = -1;

int pilaNivelesIf[MAX_POLACA];
int topeNivelesIf = -1;

void pushSalto(int pos) { pilaSaltos[++topePilaSaltos] = pos; }
int popSalto() { return pilaSaltos[topePilaSaltos--]; }
int cantSaltos() { return topePilaSaltos + 1; }

void pushNivelIf() { pilaNivelesIf[++topeNivelesIf] = topePilaSaltos; }
int popNivelIf() { return pilaNivelesIf[topeNivelesIf--]; }


/* BÃºsqueda en tabla de sÃ­mbolos */
int idxSimbolo(const char* nombre) {
    for (int i = 0; i < indiceTabla; i++) {
        if (strcmp(tabla[i].nombre, nombre) == 0) return i;
    }
    return -1;
}
int existeSimbolo(const char* nombre) {
    return idxSimbolo(nombre) >= 0;
}
/* Construye el nombre mostrado para constantes String: "_Palabra1_Palabra2..." */
void nombreConstanteString(const char* valor, char* out, size_t outsz) {
    size_t j = 0;
    if (outsz == 0) return;
    if (j + 1 < outsz) out[j++] = '_';
    for (size_t i = 0; valor[i] != '\0' && j + 1 < outsz; i++) {
        char c = valor[i];
        if (c == ' ') out[j++] = '_';
        else out[j++] = c;
    }
    out[j] = '\0';
}

/* IDs pendientes de tipar en una declaraciÃ³n INIT {...} */
char idsPendientes[500][50];
int  cantIdsPendientes = 0;

void setTipoSimbolo(const char* nombre, const char* tipo) {
    int idx = idxSimbolo(nombre);
    if (idx >= 0) {
        strcpy(tabla[idx].tipo, tipo);
    }
}

const char* getTipoSimbolo(const char* nombre) {
    int idx = idxSimbolo(nombre);
    if (idx >= 0 && tabla[idx].tipo[0] != '\0') return tabla[idx].tipo;
    return "-";
}

void agregarVariable(const char* nombre) {
    if (existeSimbolo(nombre)) return;
    strcpy(tabla[indiceTabla].nombre, nombre);
    strcpy(tabla[indiceTabla].tipo, "");  /* mantenemos "-" para no romper Entrega 1 */
    strcpy(tabla[indiceTabla].valor, "");
    tabla[indiceTabla].longitud = 0;
    indiceTabla++;
}

/* Verifica si existe una constante con el mismo valor */
int existeConstante(const char* valor) {
    for (int i = 0; i < indiceTabla; i++) {
        if (tabla[i].valor[0] && strcmp(tabla[i].valor, valor) == 0) return 1;
    }
    return 0;
}

void agregarConstante(const char* valor, const char* tipo) {
    if (existeConstante(valor)) return;

    char nombreUnico[50];
    if (strcmp(tipo, "Int") == 0 || strcmp(tipo, "Float") == 0) {
        sprintf(nombreUnico, "_%s", valor);
    } else if (strcmp(tipo, "String") == 0) {
        static int contadorString = 1;
        sprintf(nombreUnico, "const_string_%d", contadorString++);
    } else {
        sprintf(nombreUnico, "const_%d", indiceTabla);
    }

    strcpy(tabla[indiceTabla].nombre, nombreUnico);
    /* guardamos el tipo real para validaciones, aunque la impresiÃ³n muestre "-" */
    strcpy(tabla[indiceTabla].tipo, tipo);
    strcpy(tabla[indiceTabla].valor, valor);
    if (strcmp(tipo, "String") == 0)
        tabla[indiceTabla].longitud = (int)strlen(valor);
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

    /* CÃ¡lculo dinÃ¡mico de anchos por contenido */
    int anchoNombre = (int)strlen("NOMBRE");
    int anchoTipo   = (int)strlen("TIPO");
    int anchoValor  = (int)strlen("VALOR");
    int anchoLong   = (int)strlen("LONGITUD");

    /* mÃ­nimos agradables */
    if (anchoNombre < 30) anchoNombre = 30;
    if (anchoTipo   < 10) anchoTipo   = 10;
    if (anchoValor  < 10) anchoValor  = 10;
    if (anchoLong   < 8)  anchoLong   = 8;

    for (int i = 0; i < indiceTabla; i++) {
        int esConst = (tabla[i].valor[0] != '\0');

        char tipoMostrar[20];
        if (esConst) {
            if (strcmp(tabla[i].tipo, "Int") == 0) strcpy(tipoMostrar, "CTE_Int");
            else if (strcmp(tabla[i].tipo, "Float") == 0) strcpy(tipoMostrar, "CTE_Float");
            else if (strcmp(tabla[i].tipo, "String") == 0) strcpy(tipoMostrar, "CTE_String");
            else strcpy(tipoMostrar, "-");
        } else {
            strcpy(tipoMostrar, "-");
        }

        char nombreMostrar[256];
        if (esConst && strcmp(tabla[i].tipo, "String") == 0) {
            nombreConstanteString(tabla[i].valor, nombreMostrar, sizeof(nombreMostrar));
        } else {
            strncpy(nombreMostrar, tabla[i].nombre, sizeof(nombreMostrar)-1);
            nombreMostrar[sizeof(nombreMostrar)-1] = '\0';
        }

        char longitudStr[20];
        if (tabla[i].longitud > 0) sprintf(longitudStr, "%d", tabla[i].longitud);
        else strcpy(longitudStr, "-");

        int lenNombre = (int)strlen(nombreMostrar);
        int lenTipo   = (int)strlen(tipoMostrar);
        int lenValor  = esConst ? (int)strlen(tabla[i].valor) : 0;
        int lenLong   = (int)strlen(longitudStr);
        if (lenNombre > anchoNombre) anchoNombre = lenNombre;
        if (lenTipo   > anchoTipo)   anchoTipo   = lenTipo;
        if (lenValor  > anchoValor)  anchoValor  = lenValor;
        if (lenLong   > anchoLong)   anchoLong   = lenLong;
    }

    /* Separadores entre columnas: mantener 1 entre NOMBRE-TIPO y ampliar entre TIPO-VALOR y VALOR-LONGITUD */
    int sep12 = 1; /* NOMBRE - TIPO */
    int sep23 = 3; /* TIPO   - VALOR */
    int sep34 = 3; /* VALOR  - LONGITUD */

    int ancho_total = anchoNombre + sep12 + anchoTipo + sep23 + anchoValor + sep34 + anchoLong;

    for (int i = 0; i < ancho_total; i++) fprintf(f, "=");
    fprintf(f, "\n");
    fprintf(f, "%*s\n", (ancho_total + 30) / 2, "TABLA DE SÃ�MBOLOS - LYC 2025");
    for (int i = 0; i < ancho_total; i++) fprintf(f, "=");
    fprintf(f, "\n\n");

    fprintf(f, "%-*s%*s%-*s%*s%-*s%*s%-*s\n",
        anchoNombre, "NOMBRE",
        sep12, "",
        anchoTipo,   "TIPO",
        sep23, "",
        anchoValor,  "VALOR",
        sep34, "",
        anchoLong,   "LONGITUD");

    for (int i = 0; i < ancho_total; i++) fprintf(f, "-");
    fprintf(f, "\n");

    for (int i = 0; i < indiceTabla; i++) {
        int esConst = (tabla[i].valor[0] != '\0');

        char tipoMostrar[20];
        if (esConst) {
            if (strcmp(tabla[i].tipo, "Int") == 0) strcpy(tipoMostrar, "CTE_Int");
            else if (strcmp(tabla[i].tipo, "Float") == 0) strcpy(tipoMostrar, "CTE_Float");
            else if (strcmp(tabla[i].tipo, "String") == 0) strcpy(tipoMostrar, "CTE_String");
            else strcpy(tipoMostrar, "-");
        } else {
            strcpy(tipoMostrar, "-");
        }

        char nombreMostrar[256];
        if (esConst && strcmp(tabla[i].tipo, "String") == 0) {
            nombreConstanteString(tabla[i].valor, nombreMostrar, sizeof(nombreMostrar));
        } else {
            strncpy(nombreMostrar, tabla[i].nombre, sizeof(nombreMostrar)-1);
            nombreMostrar[sizeof(nombreMostrar)-1] = '\0';
        }

        char longitudStr[20];
        if (tabla[i].longitud > 0) sprintf(longitudStr, "%d", tabla[i].longitud);
        else strcpy(longitudStr, "-");

    fprintf(f, "%-*s%*s%-*s%*s%-*s%*s%-*s\n",
        anchoNombre, nombreMostrar,
        sep12, "",
        anchoTipo,   tipoMostrar,
        sep23, "",
        anchoValor,  esConst ? tabla[i].valor : "",
        sep34, "",
        anchoLong,   longitudStr);
    }

    fprintf(f, "\nTotal de entradas: %d\n", indiceTabla);
    fclose(f);
    printf("\n>> symbol-table.txt generado correctamente\n");
}

/* ============================
   CÃ³digo intermedio: helpers
   ============================ */
void agregarIntermedio(const char *valor) {
    strcpy(codigoIntermedio[indiceCodigo++], valor);
}

int reservarSalto() {
    agregarIntermedio("_");
    return indiceCodigo - 1;
}

void completarSalto(int pos, int destino) {
    sprintf(codigoIntermedio[pos], "%d", destino);
}

/* Helpers para volcado de código intermedio */
static int esOperadorTok(const char* t) {
    const char* ops[] = {"+","-","*","/","%%",":=","READ","WRITE",
                          "BF","BI","==","!=","<",">","<=",">=",
                          "AND","OR","NOT","CONVDATE"};
    int n = (int)(sizeof(ops)/sizeof(ops[0]));
    for (int k=0;k<n;k++) if (strcmp(t, ops[k])==0) return 1;
    return 0;
}
static int esEtiquetaTok(const char* t) {
    return (t[0]=='E' && t[1]=='T');
}
static void flush_line(FILE* f, char* buf) {
    if (buf[0] != '\0') {
        fprintf(f, "%s\n\n", buf);
        buf[0] = '\0';
    }
}
static void add_tok(char* buf, const char* tok) {
    if (buf[0] != '\0') strcat(buf, " ");
    strcat(buf, tok);
}

void volcarCodigoIntermedio() {
    FILE *f = fopen("intermediate-code.txt", "w");
    if (!f) {
        printf("No se pudo abrir intermediate-code.txt\n");
        return;
    }

    /* fprintf(f, "==============================\n");
    fprintf(f, "CÃ“DIGO INTERMEDIO - POLACA INVERSA\n");
    fprintf(f, "==============================\n\n"); */
    /* Pretty print: instrucciÃ³n por lÃ­nea. Reglas:
       - ':=', 'READ', 'WRITE' terminan lÃ­nea.
       - 'BF' y 'BI' consumen la etiqueta siguiente y terminan lÃ­nea.
       - Etiquetas ET# van en una lÃ­nea sola.
       - Se agregan comillas a tokens con espacios (strings) para legibilidad. */
    char line[1024];
    line[0] = '\0';

    for (int i = 0; i < indiceCodigo; i++) {
        const char* tok = codigoIntermedio[i];

        fprintf(f, "[%d] %s\n", i, codigoIntermedio[i]);
        continue;
        /* Etiqueta aislada */
        if (esEtiquetaTok(tok)) {
            flush_line(f, line);
            fprintf(f, "%s\n\n", tok);
            continue;
        }

        /* BF/BI con su etiqueta siguiente */
        if ((strcmp(tok, "BF")==0 || strcmp(tok, "BI")==0) && (i+1) < indiceCodigo) {
            const char* et = codigoIntermedio[i+1];
            /* AÃ±adir el contenido de la lÃ­nea acumulada antes de BF si hay */
            if (line[0] != '\0') { fprintf(f, "%s\n\n", line); line[0]='\0'; }
            fprintf(f, "%s %s\n\n", tok, et);
            i++; /* Consumimos la etiqueta */
            continue;
        }

        /* Token posiblemente string: si no es operador y contiene espacios, lo mostramos con comillas */
        char shown[256];
        if (!esOperadorTok(tok)) {
            int needsQuotes = 0;
            for (const char* p = tok; *p; ++p) {
                if (*p==' ' || *p=='\t') { needsQuotes = 1; break; }
            }
            if (needsQuotes) {
            } else {
                snprintf(shown, sizeof(shown), "%s", tok);
            }
        } else {
            snprintf(shown, sizeof(shown), "%s", tok);
        }

        add_tok(line, shown);

        /* Fin de instrucciÃ³n: := / READ / WRITE */
        if (strcmp(tok, ":=")==0 || strcmp(tok, "READ")==0 || strcmp(tok, "WRITE")==0) {
            flush_line(f, line);
        }
    }

    /* Flush final si quedÃ³ algo */
    flush_line(f, line);

    fprintf(f, "Total de elementos: %d\n", indiceCodigo);
    fclose(f);
    printf("\n>> intermediate-code.txt generado correctamente\n");
}

/* ============================
   Etiquetas (IF / WHILE)
   ============================ */
void nuevaEtiqueta(char* out /* >=16 */) {
    sprintf(out, "ET%d", nextEtiqueta++);
}
void push(char pila[][16], int *tope, const char* et) {
    strcpy(pila[++(*tope)], et);
}
void pop (char pila[][16], int *tope, char* out) {
    if (*tope < 0) { out[0]='\0'; return; }
    strcpy(out, pila[(*tope)--]);
}

/* ============================
   Tipos y validaciones
   ============================ */
int esNumero(const char* t){ return (strcmp(t,"Int")==0 || strcmp(t,"Float")==0); }
int esEntero(const char* t){ return strcmp(t,"Int")==0; }
int esFloat (const char* t){ return strcmp(t,"Float")==0; }
int esString(const char* t){ return strcmp(t,"String")==0; }

void error_semantico(const char* msg){
    printf("ERROR SEMANTICO: %s\n", msg);
    erroresSemanticos++;
}

/* combinaciÃ³n de tipos para + - * / */
void combinarTiposArith(const char* a, const char* b, char* out /*>=10*/, const char* op){
    if (esString(a) || esString(b)) {
        /* strings no permitidos en aritmÃ©tica */
        char buf[128];
        sprintf(buf, "Operador %s no admite String", op);
        error_semantico(buf);
        strcpy(out, "-");
        return;
    }
    if (esFloat(a) || esFloat(b)) strcpy(out,"Float");
    else strcpy(out,"Int");
}

/* MOD solo Int */
void validarMod(const char* a, const char* b){
    if (!(esEntero(a) && esEntero(b))) {
        error_semantico("Operador % MOD requiere operandos Int");
    }
}

/* ComparaciÃ³n: num con num, o String==String / String!=String */
void validarComparacion(const char* a, const char* b, const char* op){
    if (esString(a) || esString(b)) {
        if (!(esString(a) && esString(b) && (strcmp(op,"==")==0 || strcmp(op,"!=")==0))) {
            error_semantico("Comparacion con String solo admite == o !=");
        }
    } else if (!(esNumero(a) && esNumero(b))) {
        error_semantico("Comparacion requiere operandos numericos o ambos String");
    }
}

%}

/* ============================
   Tokens y tipos
   ============================ */
%union {
    char cadena[50];
}

%token <cadena> CTE_INT CTE_FLOAT CTE_STR
%token <cadena> DATE
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
%token AND OR NOT
%token <cadena> ISZERO CONVDATE
%token GUION  /* separador '-' dentro de Date */
%token COMA PYC PUNTO

/* Precedencias para resolver conflictos */
%nonassoc ELSE
%nonassoc IFX
%left OR
%left AND
%right NOT

%type <cadena> tipo
%type <cadena> expresion termino factor
%type <cadena> comparacion condicion

%%

/* ============================
   Reglas SintÃ¡cticas
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
  | condicion
;

/* ---------- AsignaciÃ³n ---------- */
asignacion:
    ID ASIG expresion PYC {
        if (!existeSimbolo($1)) {
            printf("ADVERTENCIA: Variable '%s' no declarada con INIT\n", $1);
            agregarVariable($1);
        }
        /* Chequeo de tipos: si la var tiene tipo y la expr tambiÃ©n, deben ser compatibles */
        const char* tvar = getTipoSimbolo($1);
        const char* texp = $3;
        if (strcmp(tvar,"-")!=0 && strcmp(texp,"-")!=0) {
            if (esString(tvar) != esString(texp)) {
                error_semantico("Asignacion de tipo incompatible (String vs numerico)");
            }
        }
        /* GeneraciÃ³n PI: <expr> ID := */
        agregarIntermedio($1);
        agregarIntermedio(":=");
        printf("    ID := Expresion es ASIGNACION\n");
    }
;

/* ---------- Expresiones aritmÃ©ticas ---------- */
expresion:
    termino                  { printf("    Termino es Expresion\n"); strcpy($$, $1); }
  | expresion SUMA termino   {
        agregarIntermedio("+");
        combinarTiposArith($1,$3,$$,"+");
        printf("    Expresion+Termino es Expresion\n");
    }
  | expresion RESTA termino  {
        agregarIntermedio("-");
        combinarTiposArith($1,$3,$$,"-");
        printf("    Expresion-Termino es Expresion\n");
    }
;

termino:
    factor                 { printf("    Factor es Termino\n"); strcpy($$, $1); }
  | termino MULT factor    {
        agregarIntermedio("*");
        combinarTiposArith($1,$3,$$,"*");
    }
  | termino DIV factor     {
        agregarIntermedio("/");
        combinarTiposArith($1,$3,$$,"/");
    }
  | termino MOD factor     {
        agregarIntermedio("%%");
        validarMod($1,$3);
        strcpy($$, "Int");
    }
;

factor:
    ID {
        if (!existeSimbolo($1)) {
            char buf[120]; sprintf(buf,"Uso de variable no declarada: %s",$1);
            error_semantico(buf);
            agregarVariable($1); /* para no cascaderizar errores */
        }
        agregarIntermedio($1);
        strcpy($$, getTipoSimbolo($1)); /* puede ser "-" si no tipada aÃºn */
        printf("    ID es Factor\n");
        printf("    ID es Factor\n");
    }
  | CTE_INT {
        agregarConstante($1, "Int");
        agregarIntermedio($1);
        strcpy($$, "Int");
        printf("    CTE es Factor\n");
    }
  | CTE_FLOAT {
        agregarConstante($1, "Float");
        agregarIntermedio($1);
        strcpy($$, "Float");
        printf("    CTE es Factor\n");
    }
  | CTE_STR {
        agregarConstante($1, "String");
        agregarIntermedio($1);
        strcpy($$, "String");
        printf("    CTE es Factor\n");
    }
  | PAR_IZQ expresion PAR_DER { 
  		strcpy($$, $2); 
  		printf("    Expresion entre parentesis es Factor\n"); 
  	}
  | CONVDATE PAR_IZQ DATE PAR_DER {
        /* d m a ya quedaron en PI por las reglas de expresion -> agrego operador */
        agregarConstante($3, "String");
        agregarIntermedio("DATE");
 
        strcpy($$, "String");
        printf("    convDate(DATE) es Factor\n");
    }
;

/* ---------- Condiciones ---------- */
condicion:
      comparacion { strcpy($$, $1); }

    | condicion AND condicion {
        // En un AND, ambos falsos deben saltar al mismo lugar
        int pos2 = popSalto(); // salto falso de la segunda condición
        int pos1 = popSalto(); // salto falso de la primera condición

        printf("    Condicion AND Condicion es Condicion\n");
        strcpy($$, "Int");
    }

    

    | condicion OR condicion {
            // Si la primera es verdadera → salta al final del OR
            int pos = popSalto();
            agregarIntermedio("BI");
            completarSalto(pos, indiceCodigo);
            printf("    Condicion OR Condicion es Condicion\n");
            strcpy($$, "Int");
    }

    | NOT condicion {
            // Invierte el operador de salto anterior
            int pos = popSalto();
            char *op = codigoIntermedio[pos - 1];
            if      (strcmp(op,"BGE")==0) strcpy(codigoIntermedio[pos-1],"BLT");
            else if (strcmp(op,"BLE")==0) strcpy(codigoIntermedio[pos-1],"BGT");
            else if (strcmp(op,"BGT")==0) strcpy(codigoIntermedio[pos-1],"BLE");
            else if (strcmp(op,"BLT")==0) strcpy(codigoIntermedio[pos-1],"BGE");
            else if (strcmp(op,"BEQ")==0) strcpy(codigoIntermedio[pos-1],"BNE");
            else if (strcmp(op,"BNE")==0) strcpy(codigoIntermedio[pos-1],"BEQ");
            pushSalto(pos);
            printf("    NOT Condicion es Condicion\n");
            strcpy($$, "Int");
    }

    | ISZERO PAR_IZQ expresion PAR_DER {
            agregarIntermedio("0");
            agregarIntermedio("CMP");
            agregarIntermedio("BNE");
            int p = reservarSalto();
            pushSalto(p);
            strcpy($$, "Int");
            printf("    ISZERO(Expresion) es Condicion\n");
    }
;


comparacion:
    expresion MENOR expresion {
        validarComparacion($1,$3,"<");
        agregarIntermedio("CMP");
        agregarIntermedio("BGE");
        int p = reservarSalto();
        pushSalto(p);
        strcpy($$, "Int");
    }
  | expresion MAYOR expresion {
        validarComparacion($1,$3,">");
        agregarIntermedio("CMP");
        agregarIntermedio("BLE");
        int p = reservarSalto();
        pushSalto(p);
        strcpy($$, "Int");
    }
  | expresion MENOR_IG expresion {
        validarComparacion($1,$3,"<=");
        agregarIntermedio("CMP");
        agregarIntermedio("BGT");
        int p = reservarSalto();
        pushSalto(p);
        strcpy($$, "Int");
    }
  | expresion MAYOR_IG expresion {
        validarComparacion($1,$3,">=");
        agregarIntermedio("CMP");
        agregarIntermedio("BLT");
        int p = reservarSalto();
        pushSalto(p);
        strcpy($$, "Int");
    }
  | expresion IGUAL expresion {
        validarComparacion($1,$3,"==");
        agregarIntermedio("CMP");
        agregarIntermedio("BNE");
        int p = reservarSalto();
        pushSalto(p);
        strcpy($$, "Int");
    }
  | expresion DIST expresion {
        validarComparacion($1,$3,"!=");
        agregarIntermedio("CMP");
        agregarIntermedio("BEQ");
        int p = reservarSalto();
        pushSalto(p);
        strcpy($$, "Int");
    }
;

condicion_fin:
    /* empty */ {
        while (topeSaltos >= 0) {
            int pos = popSalto();
            completarSalto(pos, indiceCodigo);
        }
    }
;

if_sentencia:
    IF PAR_IZQ condicion PAR_DER condicion_fin bloque if_fin
;

if_fin:
    /* empty */ {
        int pos = popSalto();
        completarSalto(pos, indiceCodigo);
    }
;

/* ---------- If / If-Else ---------- */
/* ---------- If / If-Else ---------- */
seleccion:
    /* IF (cond) {bloque}  =>  <cond> BF idxElse  <bloque>  idxElse */
    IF PAR_IZQ condicion PAR_DER m_if bloque n_if %prec IFX
  | /* IF (cond) {bloque} ELSE {bloque} =>
       <cond> BF idxElse  <bloque_then> BI idxEnd  idxElse  <bloque_else>  idxEnd */
    IF PAR_IZQ condicion PAR_DER m_if bloque m_else ELSE bloque n_ifelse
;

/* -------- Marcadores -------- */

m_if: {
    pushNivelIf();                // <--- marca el inicio del IF actual
    printf("    m_if: nuevo nivel de IF (nivel=%d)\n", topeNivelesIf);
}

m_else:
    /* empty */ {
        int posSaltoFalso = popSalto();       // saca el salto condicional pendiente
        agregarIntermedio("BI");              // salto incondicional al final
        int posBI = reservarSalto();          // reserva posición para BI
        completarSalto(posSaltoFalso, indiceCodigo); // completa salto falso
        pushSalto(posBI);                     // guarda BI para completarlo luego
    }
;

n_if: {
    int limite = popNivelIf();    // <--- recupera el nivel de inicio del IF
    while (topePilaSaltos > limite) {
        int pos = popSalto();
        completarSalto(pos, indiceCodigo);
        printf("    n_if: completado salto en %d -> %d\n", pos, indiceCodigo);
    }
}

n_ifelse:
    /* empty */ {
        int posBI = popSalto();
        completarSalto(posBI, indiceCodigo);
        printf("    IF(Condicion)Bloque ELSE Bloque es Seleccion\n");
    }
;




/* ---------- While ---------- */
/* while (cond) {bloque} =>
   ETini  <cond> BF ETfin  <bloque> BI ETini  ETfin */
iteracion:
    WHILE m_while_i PAR_IZQ condicion PAR_DER m_while_b bloque n_while
;

m_while_i:
    /* empty */ {
        char etIni[16];
        char etFin[16];
        nuevaEtiqueta(etIni);
        nuevaEtiqueta(etFin);
        push(pilaIni, &topeIni, etIni);
        push(pilaFin, &topeFin, etFin);
        /* Materializamos etiqueta de inicio del ciclo */
        agregarIntermedio(etIni);
    }
;

m_while_b:
    /* empty */ {
        char etFin[16];
        /* Tras evaluar la condiciÃ³n, salto por falso al fin */
        pop(pilaFin, &topeFin, etFin);
        push(pilaFin, &topeFin, etFin); /* lo volvemos a poner para usarlo al final */
        agregarIntermedio(etFin);
    }
;

n_while:
    /* empty */ {
        char etIni[16];
        char etFin[16];
        pop(pilaIni, &topeIni, etIni);
        pop(pilaFin, &topeFin, etFin);
        /* Salta al inicio y materializa el fin */
        agregarIntermedio("BI");
        agregarIntermedio(etIni);
        agregarIntermedio(etFin);
        printf("    WHILE(Condicion)Bloque es Iteracion\n");
    }
;

/* ---------- Bloques ---------- */
bloque:
    LLA_IZQ lista_sentencias LLA_DER { printf("    {Lista_sentencias} es Bloque\n"); }
;

/* ---------- Declaraciones ---------- */
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
            const char* id = idsPendientes[i];
            if (existeSimbolo(id)) {
                char buf[120]; sprintf(buf,"Redeclaracion de variable: %s", id);
                error_semantico(buf);
            } else {
                agregarVariable(id);
            }
            setTipoSimbolo(id, $3); /* guardamos tipo real para validar */
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

/* ---------- Entrada / Salida ---------- */
io:
    READ PAR_IZQ ID PAR_DER PYC  {
        if (!existeSimbolo($3)) {
            char buf[120]; sprintf(buf,"READ sobre variable no declarada: %s", $3);
            error_semantico(buf);
            agregarVariable($3);
        }
        agregarIntermedio($3);
        agregarIntermedio("READ");
        printf("    READ(ID) es IO\n");
    }
  | WRITE PAR_IZQ expresion PAR_DER PYC {
        /* String, Int o Float, todos vÃ¡lidos */
        agregarIntermedio("WRITE");
        printf("    WRITE(Expresion) es IO\n");
    }
;

%%

/* ============================
   Funciones auxiliares
   ============================ */
int main(int argc, char *argv[]) {
    if (argc < 2) {
        printf("Uso: %s <archivo_prueba>\n", argv[0]);
        return 1;
    }
    if((yyin = fopen(argv[1], "rt"))==NULL) {
        printf("\nNo se puede abrir el archivo de prueba: %s\n", argv[1]);
    } else {
        yyparse();
        fclose(yyin);
    }
    volcarTabla();
    volcarCodigoIntermedio();

    if (erroresSemanticos) {
        printf("\nCompilacion completa con ERRORES SEMANTICOS (%d)\n", erroresSemanticos);
        return 2;
    } else {
        printf("\nCompilacion semantica OK\n");
        return 0;
    }
}

int yyerror(void) {
    printf("Error Sintactico\n");
    exit(1);
}