%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "y.tab.h"
#include <ctype.h>
#define MAX_POLACA 4096

int yystopparser = 0;
extern FILE *yyin;

int yyerror();
int yylex();
void generar_assembler(void);

/* ============================
    Tabla de simbolos
    ============================ */
typedef struct {
    char nombre[50];    // nombre de la variable o constante
    char tipo[10];      // "Int" | "Float" | "String" | "-" 
    char valor[50];     // valor (solo para constantes)
    int  longitud;      // longitud del string si aplica
} Simbolo;

Simbolo tabla[500];
int indiceTabla = 0;
/* Errores semanticos acumulados */
int erroresSemanticos = 0;


int convertirFechaYYYYMMDD(const char* fechaStr) {
    int dia, mes, anio;
    if (sscanf(fechaStr, "%d-%d-%d", &dia, &mes, &anio) == 3) {
        return (anio * 10000) + (mes * 100) + dia;
    }
    return 0; 
}


/* Codigo intermedio (polaca inversa) */
char codigoIntermedio[MAX_POLACA][256];
int  indiceCodigo = 0;

int pilaSaltos[MAX_POLACA];
int topePilaSaltos = -1;

int  nextEtiqueta = 1;
char pilaElse[100][16]; int topeElse = -1;
char pilaEnd [100][16]; int topeEnd  = -1;
char pilaIni [100][16]; int topeIni  = -1;
char pilaFin [100][16]; int topeFin  = -1;

int nivelIf[MAX_POLACA];
int topeNivelesIf = -1;

int nivelWhile[MAX_POLACA];
int topeNivelesWhile = -1;

int cantSaltos() { return topePilaSaltos + 1; }

void pushNivelIf() {
    nivelIf[++topeNivelesIf] = topePilaSaltos;
}
int popNivelIf() {
    int v = nivelIf[topeNivelesIf--];
    return v;
}

// --- WHILE ---

typedef struct { int limitePilaSaltos; int posInicio; } NivelWhile;
NivelWhile pilaNivelWhile[MAX_POLACA];
int topeNivelWhile = -1;

void pushNivelWhile(int posInicio) {
    pilaNivelWhile[++topeNivelWhile].limitePilaSaltos = topePilaSaltos;
    pilaNivelWhile[topeNivelWhile].posInicio = posInicio;
}

NivelWhile popNivelWhileStruct() {
    NivelWhile v = pilaNivelWhile[topeNivelWhile--];
    return v;
}

int popNivelWhile() {
    int v = nivelWhile[topeNivelesWhile--];
    return v;
}






// Agregar un token (string) al codigo intermedio; actualiza indiceCodigo
void agregarIntermedio(const char *valor) {
    strcpy(codigoIntermedio[indiceCodigo++], valor);
}


void agregarIntermedioInt(int valor) {
    char buf[32];
    sprintf(buf, "%d", valor);
    agregarIntermedio(buf);
}

int reservarSalto() {
    agregarIntermedio("_");
    int pos = indiceCodigo - 1;
    printf("RESERVAR: pos=%d\n", pos);
    return pos;
}

// Push/Pop en la pila de saltos
void pushSalto(int pos) {
    pilaSaltos[++topePilaSaltos] = pos;
    
}

int popSalto() {
    if (topePilaSaltos < 0) {
    
        return -1;
    }
    int pos = pilaSaltos[topePilaSaltos--];
    return pos;
}

// Completar salto: sustituye "_" por el número 'destino'
void completarSalto(int pos, int destino) {
    if (pos < 0 || pos >= MAX_POLACA) {
        printf("COMPLETAR: pos fuera de rango pos=%d destino=%d\n", pos, destino);
        return;
    }
    char buf[32];
    sprintf(buf, "%d", destino);
    strcpy(codigoIntermedio[pos], buf);
    printf("COMPLETAR: pos=%d destino=%d\n", pos, destino);
}







/* Busqueda en tabla de si­mbolos */
int idxSimbolo(const char* nombre) {
    for (int i = 0; i < indiceTabla; i++) {
        if (strcmp(tabla[i].nombre, nombre) == 0) return i;
    }
    return -1;
}
int existeSimbolo(const char* nombre) {
    return idxSimbolo(nombre) >= 0;
}
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
    
  
     
    if (strcmp(tipo, "Int") == 0 || strcmp(tipo, "Float") == 0 || strcmp(tipo, "Date") == 0) {
        sprintf(nombreUnico, "_%s", valor);

        // Reemplazar puntos por guion bajo
        for (int k = 0; k < strlen(nombreUnico); k++)
            if (nombreUnico[k] == '.') nombreUnico[k] = '_';

    } else if (strcmp(tipo, "String") == 0) {
        static int contadorString = 1;
        sprintf(nombreUnico, "const_string_%d", contadorString++);
    } else {
        sprintf(nombreUnico, "const_%d", indiceTabla);
    }

    strcpy(tabla[indiceTabla].nombre, nombreUnico);
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

    /* Cálculo dinámico de anchos por contenido */
    int anchoNombre = (int)strlen("NOMBRE");
    int anchoTipo   = (int)strlen("TIPO");
    int anchoValor  = (int)strlen("VALOR");
    int anchoLong   = (int)strlen("LONGITUD");

    /* Mínimos agradables */
    if (anchoNombre < 30) anchoNombre = 30;
    if (anchoTipo   < 10) anchoTipo   = 10;
    if (anchoValor  < 10) anchoValor  = 10;
    if (anchoLong   < 8)  anchoLong   = 8;

    /* Recalcular anchos dinámicamente según contenido */
    for (int i = 0; i < indiceTabla; i++) {
        int esConst = (tabla[i].valor[0] != '\0');

        char tipoMostrar[50];
        if (strcmp(tabla[i].tipo, "-") == 0 || tabla[i].tipo[0] == '\0')
            strcpy(tipoMostrar, "");
        else
            strcpy(tipoMostrar, tabla[i].tipo);

        char nombreMostrar[256];
        if (esConst && strcmp(tabla[i].tipo, "String") == 0) {
            nombreConstanteString(tabla[i].valor, nombreMostrar, sizeof(nombreMostrar));
        } else {
            strncpy(nombreMostrar, tabla[i].nombre, sizeof(nombreMostrar) - 1);
            nombreMostrar[sizeof(nombreMostrar) - 1] = '\0';
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

    /* Separadores entre columnas */
    int sep12 = 1; /* NOMBRE - TIPO */
    int sep23 = 3; /* TIPO   - VALOR */
    int sep34 = 3; /* VALOR  - LONGITUD */

    int ancho_total = anchoNombre + sep12 + anchoTipo + sep23 + anchoValor + sep34 + anchoLong;

    /* Encabezado */
    for (int i = 0; i < ancho_total; i++) fprintf(f, "=");
    fprintf(f, "\n");
    fprintf(f, "%*s\n", (ancho_total + 30) / 2, "TABLA DE SIMBOLOS - LYC 2025");
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

    /* Contenido de la tabla */
    for (int i = 0; i < indiceTabla; i++) {
        int esConst = (tabla[i].valor[0] != '\0');

        char tipoMostrar[50];
        if (strcmp(tabla[i].tipo, "-") == 0 || tabla[i].tipo[0] == '\0')
            strcpy(tipoMostrar, "");
        else
            strcpy(tipoMostrar, tabla[i].tipo);

        char nombreMostrar[256];
        if (esConst && strcmp(tabla[i].tipo, "String") == 0) {
            nombreConstanteString(tabla[i].valor, nombreMostrar, sizeof(nombreMostrar));
        } else {
            strncpy(nombreMostrar, tabla[i].nombre, sizeof(nombreMostrar) - 1);
            nombreMostrar[sizeof(nombreMostrar) - 1] = '\0';
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

    
   
    char line[1024];
    line[0] = '\0'; 
    

    for (int i = 0; i < indiceCodigo; i++) {
        const char* tok = codigoIntermedio[i];
        fprintf(f, "%s\n", codigoIntermedio[i]);
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
/* * ==================================
 * == PASO 4: Añadir helper esDate ==
 * ==================================
 */
int esDate  (const char* t){ return strcmp(t,"Date")==0; }


void error_semantico(const char* msg){
    printf("ERROR SEMANTICO: %s\n", msg);
    erroresSemanticos++;
}

/* combinacion de tipos para + - * / */
void combinarTiposArith(const char* a, const char* b, char* out /*>=10*/, const char* op){
    if (esString(a) || esString(b) || esDate(a) || esDate(b)) {
        /* strings o fechas no permitidos en aritmética */
        char buf[128];
        sprintf(buf, "Operador %s no admite String ni Date", op);
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

/* Comparacion: num con num, o String==String / String!=String */
void validarComparacion(const char* a, const char* b, const char* op){
    if (esString(a) || esString(b)) {
        if (!(esString(a) && esString(b) && (strcmp(op,"==")==0 || strcmp(op,"!=")==0))) {
            error_semantico("Comparacion con String solo admite == o !=");
        }
        if (esDate(a) || esDate(b)) {
        if (!(esDate(a) && esDate(b) && 
              (strcmp(op,"==")==0 || strcmp(op,"!=")==0))) {
            error_semantico("Comparacion con Date solo admite == o != entre valores Date");
        }
        return;
    }
    } else if (!(esNumero(a) && esNumero(b))) {
        error_semantico("Error, comparacion Int con Tipo incompatible");
    }
}

%}

/* ============================
    Tokens y tipos
    ============================ */
%union {
    char cadena[50];
}

%token <cadena> CTE_INT CTE_FLOAT CTE_STR DATE
%token <cadena> CONVDATET 
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
/* Operadores logicos */
%token AND OR NOT
%token <cadena> ISZERO CONVDATE
%token GUION  /* separador '-' dentro de convDate */
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
    Reglas Sintacticas
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

/* ---------- Asignacion ---------- */
asignacion:
    ID ASIG expresion PYC {
        if (!existeSimbolo($1)) {
            printf("ADVERTENCIA: Variable '%s' no declarada con INIT\n", $1);
            agregarVariable($1);
        }

        /* ============================
           Chequeo de compatibilidad de tipos
           ============================ */
        const char* tvar = getTipoSimbolo($1);
        const char* texp = $3;

        if (strcmp(tvar, "-") != 0 && strcmp(texp, "-") != 0) {

            /* --- STRING vs NUMÉRICO --- */
            if (esString(tvar) != esString(texp)) {
                error_semantico("Asignacion de tipo incompatible (String vs numerico)");
            }

            /* --- DATE vs NUMÉRICO --- */
            else if (esDate(tvar) && !esDate(texp)) {
                char msg[128];
                sprintf(msg, "Asignacion de tipo incompatible: se esperaba Date pero se recibio %s", texp);
                error_semantico(msg);
            }
            else if (!esDate(tvar) && esDate(texp)) {
                char msg[128];
                sprintf(msg, "Asignacion de tipo incompatible: no se puede asignar un Date a una variable tipo %s", tvar);
                error_semantico(msg);
            }

            /* --- DATE vs STRING --- */
            else if (esDate(tvar) && esString(texp)) {
                error_semantico("Asignacion de tipo incompatible: no se puede asignar un String a un Date");
            }
            else if (esString(tvar) && esDate(texp)) {
                error_semantico("Asignacion de tipo incompatible: no se puede asignar un Date a un String");
            }
            
    
        }

        /* ============================
           Generación de código intermedio
           ============================ */
        agregarIntermedio($1);
        agregarIntermedio(":=");
        printf("     ID := Expresion es ASIGNACION\n");
    }

;


/* ---------- Expresiones aritmetricas ---------- */
expresion:
    termino             { printf("     Termino es Expresion\n"); strcpy($$, $1); }
  | expresion SUMA termino   {
        agregarIntermedio("+");
        combinarTiposArith($1,$3,$$,"+");
        printf("     Expresion+Termino es Expresion\n");
    }
  | expresion RESTA termino  {
        agregarIntermedio("-");
        combinarTiposArith($1,$3,$$,"-");
        printf("     Expresion-Termino es Expresion\n");
    }
;

termino:
    factor             { printf("     Factor es Termino\n"); strcpy($$, $1); }
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
        strcpy($$, getTipoSimbolo($1)); /* puede ser "-" si no tipada aun */
        printf("     ID es Factor\n");
        printf("     ID es Factor\n");
    }
  | CTE_INT {
        agregarConstante($1, "Int");
        agregarIntermedio($1);
        strcpy($$, "Int");
        printf("     CTE es Factor\n");
    }
  | CTE_FLOAT {
        agregarConstante($1, "Float");
        agregarIntermedio($1);
        strcpy($$, "Float");
        printf("     CTE es Factor\n");
    }
  | CTE_STR {
        agregarConstante($1, "String");
        agregarIntermedio($1);
        strcpy($$, "String");
        printf("     CTE es Factor\n");
    }
  | PAR_IZQ expresion PAR_DER { 
        strcpy($$, $2); 
        printf("     Expresion entre parentesis es Factor\n"); 
    }
 
| CONVDATE PAR_IZQ CONVDATET PAR_DER {
    int dia, mes, anio;

    /* Intentar parsear la cadena con el formato esperado */
    if (sscanf($3, "%d-%d-%d", &dia, &mes, &anio) != 3) {
        error_semantico("Formato de fecha invalido (se esperaba dd-mm-yyyy)");
        strcpy($$, "-");
    } else {
        /* --- Validación detallada --- */
        int diasEnMes[] = {0,31,28,31,30,31,30,31,31,30,31,30,31};

        /* Ajustar febrero si es año bisiesto */
        int esBisiesto = ((anio % 4 == 0 && anio % 100 != 0) || (anio % 400 == 0));
        if (esBisiesto) diasEnMes[2] = 29;

        int fechaValida = 1;
        if (anio < 1 || mes < 1 || mes > 12) {
            fechaValida = 0;
        } else if (dia < 1 || dia > diasEnMes[mes]) {
            fechaValida = 0;
        }

        /* Mostrar los valores recibidos */
        printf("convDate recibe -> dia=%d, mes=%d, anio=%d\n", dia, mes, anio);

        if (!fechaValida) {
            char msg[128];
            sprintf(msg, "Fecha invalida: %02d-%02d-%04d (fuera de rango o inexistente)", dia, mes, anio);
            error_semantico(msg);
            strcpy($$, "-");
        } else {
            /* Convertir la fecha al formato YYYYMMDD */
            int valorFechaNum = convertirFechaYYYYMMDD($3);
            char valorFechaStr[20];
            sprintf(valorFechaStr, "%d", valorFechaNum);

            printf("convDate convierte -> %s -> %s\n", $3, valorFechaStr);

            /* Guardar en la tabla de símbolos como constante tipo Date */
            agregarConstante(valorFechaStr, "Date");

            /* Agregar al código intermedio */
            agregarIntermedio(valorFechaStr);

            strcpy($$, "Date");
            printf("convDate(CONVDATET) es Factor (tipo Date)\n");
        }
    }
}



;

/* ---------- Condiciones ---------- */
condicion:
    comparacion { strcpy($$, $1); }

  | condicion AND condicion {
        printf("    Condicion AND Condicion es Condicion\n");
        strcpy($$, "Int");
    }

  | condicion  OR m_or condicion {
        int f2 = popSalto();
        int f1 = popSalto();
        completarSalto(f1, indiceCodigo);
        pushSalto(f2);
        printf("    Condicion OR Condicion es Condicion\n");
        strcpy($$, "Int");
    }

  | NOT condicion {
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

/* ---------- If / If-Else ---------- */
seleccion:
    IF m_if PAR_IZQ condicion PAR_DER bloque n_if %prec IFX
  | IF m_if PAR_IZQ condicion PAR_DER bloque m_else ELSE bloque n_ifelse
;


/* -------- Marcadores -------- */

m_if: {
    pushNivelIf();                // <--- marca el inicio del IF actual
    printf("    m_if: nuevo nivel de IF (nivel=%d)\n", topeNivelesIf);
}
;

m_else:
    /* empty */ {
        int posSaltoFalso = popSalto();       // saca el salto condicional pendiente
        agregarIntermedio("BI");              // salto incondicional al final
        int posBI = reservarSalto();          // reserva posición para BI
        pushSalto(posBI);                     // guarda BI para completarlo luego
        completarSalto(posSaltoFalso, indiceCodigo); // completa salto falso
    }
;

n_if:
    /* empty */ {
        printf("n_if ejecutada\n");
        int limite = popNivelIf();
        printf("n_if: limite=%d topeSaltos=%d\n", limite, topePilaSaltos);

        while (topePilaSaltos > limite) {
            int pos = popSalto();
            printf("n_if: completando salto en %d -> %d\n", pos, indiceCodigo);
            completarSalto(pos, indiceCodigo);
        }
    }
;

m_or:
    /* marcador que se ejecuta justo después de la primera condición */
    {
        // Insertar salto incondicional al bloque verdadero del OR
        int pos = popSalto();
        agregarIntermedio("BI");
        int posBI = reservarSalto();
        pushSalto(posBI);  // lo completaremos al final del if
        completarSalto(pos, indiceCodigo);
    }
;



n_ifelse:
    /* empty */ {
        int posBI = popSalto();
        completarSalto(posBI, indiceCodigo);
        printf("    IF(Condicion)Bloque ELSE Bloque es Seleccion\n");
    }
;




/* ---------- While ---------- */
/* Producción principal del while */
iteracion:
    WHILE m_while_i PAR_IZQ condicion PAR_DER m_while_b bloque n_while
;

/* m_while_i: marca inicio del while (guardar inicio y nivel) */
m_while_i:
{
    // --- INICIO DEL WHILE ---
    int posInicio = indiceCodigo; // guardamos la posición de inicio
    pushNivelWhile(posInicio);    // ahora le pasamos el índice de inicio
    printf("m_while: inicio del WHILE en %d\n", posInicio);
}
;

/* m_while_b: reservar salto falso para la condición (se ejecuta justo después de ']') */
m_while_b:
    /* empty */ {
        printf("m_while_b: topePilaSaltos=%d\n", topePilaSaltos);
    }
;

/* n_while: finalizar while: completar salto falso y generar BI vuelta a inicio */
n_while:
  /* empty */ {
      NivelWhile nivel = popNivelWhileStruct();
      int fin = indiceCodigo;

      int falso = popSalto(); // debe devolver la reserva hecha por la condicion
      completarSalto(falso, fin + 2);

      // Generar BI al inicio
      agregarIntermedio("BI");
      agregarIntermedioInt(nivel.posInicio);

      while (topePilaSaltos > nivel.limitePilaSaltos) {
          int pos = popSalto();
          completarSalto(pos, indiceCodigo);
      }

      printf("n_while: completado falso=%d->%d, BI a %d\n", falso, fin, nivel.posInicio);
  }
;




/* ---------- Bloques ---------- */
bloque:
    LLA_IZQ lista_sentencias LLA_DER { printf("     {Lista_sentencias} es Bloque\n"); }
;

/* ---------- Declaraciones ---------- */
declaracion:
    INIT LLA_IZQ lista_declaraciones LLA_DER { printf("     INIT{Lista_declaraciones} es Declaracion\n"); }
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
        printf("     Lista_ids:Tipo; es Declaracion_tipo\n");
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
  | DATE   { strcpy($$, "Date"); }
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
        printf("     READ(ID) es IO\n");
    }
  | WRITE PAR_IZQ expresion PAR_DER PYC {
        /* String, Int o Float, todos vÃ¡lidos */
        agregarIntermedio("WRITE");
        printf("     WRITE(Expresion) es IO\n");
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


    if (erroresSemanticos) {
        printf("\nCompilacion con ERRORES SEMANTICOS (%d)\n", erroresSemanticos);
        return 2;
    } else {
        printf("\nCompilacion OK\n");

        volcarTabla();
        volcarCodigoIntermedio();
        generar_assembler();

        return 0;
    }
}


typedef struct {
    char literal[256]; // ej: "El valor de a es:"
    char asm_name[64]; // ej: "_gci_str_1"
} GciStringMap;

GciStringMap gci_strings[100];
int gci_string_count = 0;

typedef struct {
    char varAsm[64];   // nombre ASM de la variable Date (p.ej., "fecha")
    char label[64];    // etiqueta ASM de la cadena (p.ej., "fecha_date_str")
    char value[32];    // contenido numerico en texto (p.ej., "20250821")
} DateStringMap;

DateStringMap date_strings[100];
int date_string_count = 0;

static const char* findDateLabelByVar(const char* varAsm) {
    for (int i = 0; i < date_string_count; i++) {
        if (strcmp(date_strings[i].varAsm, varAsm) == 0) return date_strings[i].label;
    }
    return NULL;
}

// Helper para verificar si un token es un operador
static int esOperadorAsm(const char* t) {
    const char* ops[] = {"+","-","*","/","%%",":=","READ","WRITE",
                         "BF","BI","CMP","BEQ","BNE","BGE","BLE",
                         "BGT","BLT","CONVDATE"};
    int n = (int)(sizeof(ops)/sizeof(ops[0]));
    for (int k=0;k<n;k++) if (strcmp(t, ops[k])==0) return 1;
    return 0;
}

// Verificar si un token es un string literal del GCI
int esGciLiteral(const char* tok) {
    if (idxSimbolo(tok) != -1) return 0; // Está en la tabla
    if (esOperadorAsm(tok)) return 0; // Es un operador
    if (tok[0] == '\0') return 0; // Vacío

    // Es un número?
    const char* p = tok;
    if (p[0] == '_') p++; 
    if (p[0] == '-') p++; 
    if (*p == '\0') return 0; 

    int es_num = 1;
    int has_dot = 0;
    for (; *p; p++) {
        if (*p == '.') {
            if (has_dot) { es_num = 0; break; } 
            has_dot = 1;
        } else if (!isdigit(*p)) {
            es_num = 0; 
            break;
        }
    }
    if (es_num && (tok[0] == '_' || tok[0] == '-') && tok[1] == '\0') return 0;
    if (es_num) return 0; // Es un número

    // No está en la tabla, no es operador, no es número.
    return 1;
}

//Obtener el tipo de un operando (Int, Float, String)
const char* getTipoOperando(const char* tok) {
    int idx = idxSimbolo(tok);
    if (idx != -1) {
        if(tabla[idx].tipo[0] != '\0')
            return tabla[idx].tipo;
        else
            return "Int"; // Asumir Int si no está tipado
    }
    
    if (esGciLiteral(tok)) {
        return "String"; // String literal del GCI
    }
    
    // Es una constante numérica?
    const char* p = tok;
    if (p[0] == '_') p++;
    if (p[0] == '-') p++;
    
    for (; *p; p++) {
        if (*p == '.') {
            return "Float"; // Contiene punto, es Float
        }
    }
    
    // Es el token "0" de ISZERO?
    if (strcmp(tok, "0") == 0) return "Int";

    return "Int"; // Default a Int (ej: "_5", "10")
}

void getValidAsmName(const char* tok, char* out) {
    char temp[64];
    int i = 0;

    // 1. Añadir prefijo '_' si no es alfa y no es '_'
    if (!isalpha(tok[0]) && tok[0] != '_') {
        temp[i++] = '_';
    }

    // 2. Copiar el resto del token
    strcpy(temp + i, tok);

    // 3. Reemplazar todos los caracteres no alfanuméricos (excepto '_') por '_'
    for (int k = 0; k < strlen(temp); k++) {
        if (!isalnum(temp[k]) && temp[k] != '_') {
            temp[k] = '_';
        }
    }
    strcpy(out, temp);
}


// --- FUNCIÓN GENERAR_ASSEMBLER  ---
void generar_assembler(void) {
    int esDestino[MAX_POLACA] = {0};

    for (int i = 0; i < indiceCodigo; i++) {
        const char *t = codigoIntermedio[i];
        if (!strcmp(t, "BF") || !strcmp(t, "BI") || !strcmp(t, "BEQ") ||
            !strcmp(t, "BNE") || !strcmp(t, "BGE") || !strcmp(t, "BLE") ||
            !strcmp(t, "BGT") || !strcmp(t, "BLT")) {
            if (i + 1 < indiceCodigo) {
                const char *nxt = codigoIntermedio[i + 1];
                int ok = 1;
                for (const char *p = nxt; *p; p++)
                    if (*p < '0' || *p > '9') { ok = 0; break; }
                if (ok)
                    esDestino[atoi(nxt)] = 1;
            }
        }
    }

    FILE *f = fopen("final.asm", "w");
    if (!f) {
        printf("No se pudo crear final.asm\n");
        return;
    }

    fprintf(f, ".MODEL SMALL\n");
    fprintf(f, ".STACK 100h\n");
    fprintf(f, ".DATA\n");

    // --- Variables y constantes (de la Tabla de Símbolos) ---
    for (int i = 0; i < indiceTabla; i++) {
        Simbolo s = tabla[i];
        char nombreAsm[64];
        getValidAsmName(s.nombre, nombreAsm);

        if (s.valor[0] == '\0') { // variable
            if (!strcmp(s.tipo, "Int") || !strcmp(s.tipo, "Float") || !strcmp(s.tipo, "Date") || s.tipo[0] == '\0') 
                fprintf(f, "%-32s DW ?\n", nombreAsm);
            else if (!strcmp(s.tipo, "String"))
                fprintf(f, "%-32s DB 100 DUP('$')\n", nombreAsm);
            else
                fprintf(f, "%-32s DW ?\n", nombreAsm);
        } else { // constante
            if (!strcmp(s.tipo, "Int") || !strcmp(s.tipo, "Date")) {
                long val = atol(s.valor);
                if (val > 65535 || val < -32768) {
                    int val16 = (int)(val % 65536);
                    fprintf(f, "%-32s DW %d ; %ld\n", nombreAsm, val16, val);
                } else {
                    fprintf(f, "%-32s DW %ld\n", nombreAsm, val);
                }
            }
            else if (!strcmp(s.tipo, "Float")) {
                // Para 16 bits, solo guardamos como entero (simplificado)
                double fval = atof(s.valor);
                int ival = (int)(fval * 10); // escala x10 para conservar 1 decimal
                fprintf(f, "%-32s DW %d ; %.1f\n", nombreAsm, ival, fval);
            }
            else if (!strcmp(s.tipo, "String"))
                fprintf(f, "%-32s DB \"%s$\"\n", nombreAsm, s.valor);
            else
                fprintf(f, "%-32s DW %s\n", nombreAsm, s.valor);
        }
    }

    // --- Detectar asignaciones a variables Date para imprimirlas como string ---
    date_string_count = 0;
    for (int i = 0; i + 2 < indiceCodigo; i++) {
        const char* tokVal = codigoIntermedio[i];
        const char* tokVar = codigoIntermedio[i+1];
        const char* tokOp  = codigoIntermedio[i+2];
        if (strcmp(tokOp, ":=") != 0) continue;
        const char* tipoDest = getTipoOperando(tokVar);
        if (strcmp(tipoDest, "Date") != 0) continue;
        int esNumero = 1;
        for (const char* p = tokVal; *p; p++) {
            if (!isdigit((unsigned char)*p)) { esNumero = 0; break; }
        }
        if (!esNumero) continue;
        char varAsm[64];
        getValidAsmName(tokVar, varAsm);
        char lbl[64];
        snprintf(lbl, sizeof(lbl), "%s_date_str", varAsm);
        if (date_string_count < 100) {
            strcpy(date_strings[date_string_count].varAsm, varAsm);
            strcpy(date_strings[date_string_count].label, lbl);
            strncpy(date_strings[date_string_count].value, tokVal, sizeof(date_strings[date_string_count].value)-1);
            date_strings[date_string_count].value[sizeof(date_strings[date_string_count].value)-1] = '\0';
            date_string_count++;
        }
    }

    gci_string_count = 0;
    for (int i = 0; i < indiceCodigo; i++) {
        const char* tok = codigoIntermedio[i];
        if (esGciLiteral(tok)) {
            int found = 0;
            for (int j = 0; j < gci_string_count; j++) {
                if (strcmp(gci_strings[j].literal, tok) == 0) {
                    found = 1;
                    break;
                }
            }
            if (!found && gci_string_count < 100) {
                strcpy(gci_strings[gci_string_count].literal, tok);
                sprintf(gci_strings[gci_string_count].asm_name, "_gci_str_%d", gci_string_count);
                fprintf(f, "%-32s DB \"%s$\"\n", gci_strings[gci_string_count].asm_name, tok);
                gci_string_count++;
            }
        }
    }

    for (int k = 0; k < date_string_count; k++) {
        fprintf(f, "%-32s DB \"%s$\"\n", date_strings[k].label, date_strings[k].value);
    }

    fprintf(f,
        "_0 DW 0\n"
        "__ DW 0 ; fallback para simbolo placeholder\n"
        "TOP DW 0\n"
        "STK DW 256 DUP(?)\n"
        "BUFNUM DB 7 DUP('$')\n"
        "NEWLINE DB 13,10,'$'\n\n"
        ".CODE\n"
        "START:\n"
        "    MOV AX,@DATA\n"
        "    MOV DS,AX\n"
        "    CALL MAIN\n"
        "    MOV AX,4C00h\n"
        "    INT 21h\n\n");

    fprintf(f,
        ";--- PUSH (16 bits) ---\n"
        "PUSH_VAL PROC\n"
        "    MOV BX,TOP\n"
        "    SHL BX,1\n"
        "    MOV STK[BX],AX\n"
        "    INC TOP\n"
        "    RET\n"
        "PUSH_VAL ENDP\n"
        ";--- POP (16 bits) ---\n"
        "POP_VAL PROC\n"
        "    DEC TOP\n"
        "    MOV BX,TOP\n"
        "    SHL BX,1\n"
        "    MOV AX,STK[BX]\n"
        "    RET\n"
        "POP_VAL ENDP\n"
        ";--- POP2 (16 bits) ---\n"
        "POP2 PROC\n"
        "    CALL POP_VAL\n"
        "    PUSH AX\n"
        "    CALL POP_VAL\n"
        "    POP BX\n"
        "    RET\n"
        "POP2 ENDP\n"
        ";--- PRINT_STR ---\n"
        "PRINT_STR PROC\n"
        "    MOV AH,09h\n"
        "    INT 21h\n"
        "    RET\n"
        "PRINT_STR ENDP\n"
        ";--- PRINT_INT ---\n"
        "PRINT_INT PROC\n"
        "    PUSH AX\n"
        "    PUSH BX\n"
        "    PUSH CX\n"
        "    PUSH DX\n"
        "    PUSH DI\n"
        "    ; Limpiar buffer\n"
        "    LEA DI,BUFNUM\n"
        "    MOV CX,7\n"
        "    MOV AL,'$'\n"
        "    REP STOSB\n"
        "    ; Convertir numero\n"
        "    LEA DI,BUFNUM\n"
        "    MOV CX,0\n"
        "    CMP AX,0\n"
        "    JGE PI_LOOP\n"
        "    NEG AX\n"
        "    PUSH AX\n"
        "    MOV AL,'-'\n"
        "    STOSB\n"
        "    POP AX\n"
        "PI_LOOP:\n"
        "    XOR DX,DX\n"
        "    MOV BX,10\n"
        "    DIV BX\n"
        "    ADD DL,'0'\n"
        "    PUSH DX\n"
        "    INC CX\n"
        "    CMP AX,0\n"
        "    JNE PI_LOOP\n"
        "PI_OUT:\n"
        "    POP AX\n"
        "    MOV AL,AL\n"
        "    STOSB\n"
        "    LOOP PI_OUT\n"
        "    MOV AL,'$'\n"
        "    STOSB\n"
        "    LEA DX,BUFNUM\n"
        "    CALL PRINT_STR\n"
        "    POP DI\n"
        "    POP DX\n"
        "    POP CX\n"
        "    POP BX\n"
        "    POP AX\n"
        "    RET\n"
        "PRINT_INT ENDP\n"
        ";--- PRINT_NEWLINE ---\n"
        "PRINT_NEWLINE PROC\n"
        "    PUSH DX\n"
        "    LEA DX,NEWLINE\n"
        "    CALL PRINT_STR\n"
        "    POP DX\n"
        "    RET\n"
        "PRINT_NEWLINE ENDP\n"
        ";--- READ_INT ---\n"
        "READ_INT PROC\n"
        "    PUSH BX\n"
        "    PUSH CX\n"
        "    PUSH DX\n"
        "    MOV BX,0\n"
        "    MOV CX,0\n"
        "RI_LOOP:\n"
        "    MOV AH,01h\n"
        "    INT 21h\n"
        "    CMP AL,13\n"
        "    JE RI_END\n"
        "    CMP AL,'-'\n"
        "    JNE RI_DIGIT\n"
        "    MOV CX,1\n"
        "    JMP RI_LOOP\n"
        "RI_DIGIT:\n"
        "    SUB AL,'0'\n"
        "    MOV AH,0\n"
        "    XCHG AX,BX\n"
        "    MOV DX,10\n"
        "    MUL DX\n"
        "    ADD BX,AX\n"
        "    JMP RI_LOOP\n"
        "RI_END:\n"
        "    MOV AX,BX\n"
        "    CMP CX,1\n"
        "    JNE RI_RET\n"
        "    NEG AX\n"
        "RI_RET:\n"
        "    POP DX\n"
        "    POP CX\n"
        "    POP BX\n"
        "    RET\n"
        "READ_INT ENDP\n\n"
        ";--- MAIN PROGRAM ---\n"
        "MAIN PROC\n");

    int skipNext = 0;
    for (int i = 0; i < indiceCodigo; i++) {
        if (skipNext) {
            skipNext = 0;
            continue;
        }
        
        if (esDestino[i]) fprintf(f, "L%d:\n", i);
        const char *tok = codigoIntermedio[i];


        if (i + 2 < indiceCodigo && !strcmp(codigoIntermedio[i+2], ":=")) {
            const char* valor = tok;
            const char* destino = codigoIntermedio[i+1];

         
            int valorIsNegNum = (valor[0] == '-' && strlen(valor) > 1 && isdigit((unsigned char)valor[1]));
            int valorIsOperand = (isalpha((unsigned char)valor[0]) || isdigit((unsigned char)valor[0]) || valor[0] == '_' || valorIsNegNum);
            int valorIsOperator = (!strcmp(valor, "+") || !strcmp(valor, "-") || !strcmp(valor, "*") || !strcmp(valor, "/") || !strcmp(valor, "%%"));
            int destinoIsId = (isalpha((unsigned char)destino[0]) || destino[0] == '_');

            if (valorIsOperand && !valorIsOperator && destinoIsId) {
                char nombreDest[64], nombreVal[64];
                getValidAsmName(destino, nombreDest);
                getValidAsmName(valor, nombreVal);
                fprintf(f, "\t; %s := %s\n", nombreDest, nombreVal);
                fprintf(f, "\tMOV AX,%s\n\tMOV %s,AX\n", nombreVal, nombreDest);
                i += 2; // Saltar valor, destino y :=
                continue;
            }
        }
        

        if (i + 4 < indiceCodigo && !strcmp(codigoIntermedio[i+4], ":=")) {
            const char* tok1 = codigoIntermedio[i];
            const char* tok2 = codigoIntermedio[i+1];
            const char* op   = codigoIntermedio[i+2];
            const char* destTok = codigoIntermedio[i+3];

            // Verificar que tok1 y tok2 son operandos (no operadores)
            int tok1IsOperand = (isalpha(tok1[0]) || isdigit(tok1[0]) || tok1[0] == '_' || tok1[0] == '-');
            int tok2IsOperand = (isalpha(tok2[0]) || isdigit(tok2[0]) || tok2[0] == '_' || tok2[0] == '-');
            int opIsValid = (!strcmp(op, "+") || !strcmp(op, "-") || !strcmp(op, "*") || !strcmp(op, "/") || !strcmp(op, "%%"));
            int destIsId = (isalpha(destTok[0]) || destTok[0] == '_');

            if (tok1IsOperand && tok2IsOperand && opIsValid && destIsId) {
                char val1[64], val2[64], dest[64];
                getValidAsmName(tok1, val1);
                getValidAsmName(tok2, val2);
                getValidAsmName(destTok, dest);

                fprintf(f, "\t; %s := %s %s %s\n", dest, val1, op, val2);
                fprintf(f, "\tMOV AX,%s\n", val1);

                // Deteccion de tipos para ajuste de escala en Float (x10)
                const char* t1 = getTipoOperando(tok1);
                const char* t2 = getTipoOperando(tok2);
                int bothFloat = (!strcmp(t1, "Float") && !strcmp(t2, "Float"));

                if (!strcmp(op, "+"))
                    fprintf(f, "\tADD AX,%s\n", val2);
                else if (!strcmp(op, "-"))
                    fprintf(f, "\tSUB AX,%s\n", val2);
                else if (!strcmp(op, "*"))
                {
                    fprintf(f, "\tIMUL %s\n", val2);
                    if (bothFloat) {
                        // Producto de dos floats (escala x10 -> x100). Re-normalizar dividiendo por 10.
                        fprintf(f, "\tCWD\n\tIDIV _10\n");
                    }
                }
                else if (!strcmp(op, "/") || !strcmp(op, "%%")) {
                    if (!strcmp(op, "/") && bothFloat) {
                        // División de floats: multiplicar numerador por 10 para mantener escala x10
                        fprintf(f, "\tIMUL _10\n");
                    }
                    fprintf(f, "\tCWD\n\tIDIV %s\n", val2);
                    if (!strcmp(op, "%%"))
                        fprintf(f, "\tMOV AX,DX\n");
                }

                fprintf(f, "\tMOV %s,AX\n", dest);
                i += 4; // Consumimos 5 tokens
                continue;
            }
        }

        // Aritmética
        if (!strcmp(tok, "+"))
            fprintf(f, "\tCALL POP2\n\tADD AX,BX\n\tCALL PUSH_VAL\n");
        else if (!strcmp(tok, "-"))
            fprintf(f, "\tCALL POP2\n\tSUB AX,BX\n\tCALL PUSH_VAL\n");
        else if (!strcmp(tok, "*"))
            fprintf(f, "\tCALL POP2\n\tIMUL BX\n\tCALL PUSH_VAL\n");
        else if (!strcmp(tok, "/"))
            fprintf(f, "\tCALL POP2\n\tCWD\n\tIDIV BX\n\tCALL PUSH_VAL\n");
        else if (!strcmp(tok, "%%"))
            fprintf(f, "\tCALL POP2\n\tCWD\n\tIDIV BX\n\tMOV AX,DX\n\tCALL PUSH_VAL\n");

        // Comparaciones
        else if (!strcmp(tok, "CMP"))
            fprintf(f, "\tCALL POP2\n\tCMP AX,BX\n");

        // Saltos
        else if (!strcmp(tok, "BF") || !strcmp(tok, "BEQ") || !strcmp(tok, "BNE") ||
                 !strcmp(tok, "BGE") || !strcmp(tok, "BLE") || !strcmp(tok, "BGT") ||
                 !strcmp(tok, "BLT") || !strcmp(tok, "BI")) {
            const char *dst = (i + 1 < indiceCodigo) ? codigoIntermedio[i + 1] : "0";
            int num = atoi(dst);
            if (!strcmp(tok, "BF")) fprintf(f, "\tCALL POP_VAL\n\tCMP AX,0\n\tJE L%d\n", num);
            else if (!strcmp(tok, "BEQ")) fprintf(f, "\tJE L%d\n", num);
            else if (!strcmp(tok, "BNE")) fprintf(f, "\tJNE L%d\n", num);
            else if (!strcmp(tok, "BGE")) fprintf(f, "\tJGE L%d\n", num);
            else if (!strcmp(tok, "BLE")) fprintf(f, "\tJLE L%d\n", num);
            else if (!strcmp(tok, "BGT")) fprintf(f, "\tJG L%d\n", num);
            else if (!strcmp(tok, "BLT")) fprintf(f, "\tJL L%d\n", num);
            else fprintf(f, "\tJMP L%d\n", num);
            i++;
        }

        // Asignación
        else if (!strcmp(tok, ":=")) {
            int back = i - 1;
            while (back >= 0 &&
                   !(isalpha(codigoIntermedio[back][0]) || codigoIntermedio[back][0] == '_'))
                back--;

            if (back >= 0) {
                char nombreValido[64];
                getValidAsmName(codigoIntermedio[back], nombreValido);
                fprintf(f, "\tCALL POP_VAL\n\tMOV %s,AX\n", nombreValido);
            } else fprintf(f, "\t; Ignorado destino no válido\n");
        }

        // WRITE
        else if (!strcmp(tok, "WRITE")) {
            const char* prev_tok = codigoIntermedio[i-1];
            const char* tipoOp = getTipoOperando(prev_tok);
            if (strcmp(tipoOp, "String") == 0) {
                fprintf(f, "\tCALL POP_VAL\n\tMOV DX,AX\n\tCALL PRINT_STR\n\tCALL PRINT_NEWLINE\n");
            }
            else if (strcmp(tipoOp, "Date") == 0) {
                // Imprimir la versión string del Date si la tenemos
                char varAsm[64];
                getValidAsmName(prev_tok, varAsm);
                const char* lbl = findDateLabelByVar(varAsm);
                fprintf(f, "\tCALL POP_VAL\n"); // equilibrar la pila
                if (lbl)
                    fprintf(f, "\tLEA DX,%s\n\tCALL PRINT_STR\n\tCALL PRINT_NEWLINE\n", lbl);
                else
                    fprintf(f, "\tCALL PRINT_INT\n\tCALL PRINT_NEWLINE\n");
            }
            else {
                fprintf(f, "\tCALL POP_VAL\n\tCALL PRINT_INT\n\tCALL PRINT_NEWLINE\n");
            }
        }

        // READ / CONVDATE
        else if (!strcmp(tok, "READ")) {
            fprintf(f, "\tCALL READ_INT\n");
            // La variable destino está en el token anterior al READ
            if (i > 0) {
                char nombreValido[64];
                getValidAsmName(codigoIntermedio[i-1], nombreValido);
                fprintf(f, "\tMOV %s,AX\n", nombreValido);
                fprintf(f, "\tCALL PRINT_NEWLINE\n");
            }
        }
        else if (!strcmp(tok, "CONVDATE"))
            fprintf(f, "\t; CONVDATE no genera ASM\n");

        // Operando
        else {
            int nextIsRead = (i + 1 < indiceCodigo && !strcmp(codigoIntermedio[i + 1], "READ"));
            if (nextIsRead) {
                continue;
            }
            
            char nombreValido[64];
            getValidAsmName(tok, nombreValido);
            char* gci_asm_name = NULL;
            if (esGciLiteral(tok)) {
                for (int j = 0; j < gci_string_count; j++)
                    if (strcmp(gci_strings[j].literal, tok) == 0)
                        gci_asm_name = gci_strings[j].asm_name;
            }
            if (gci_asm_name)
                fprintf(f, "\tLEA AX,%s\n\tCALL PUSH_VAL\n", gci_asm_name);
            else {
                const char* tipoOp = getTipoOperando(tok);
                
                if (strcmp(tipoOp, "String") == 0)
                    fprintf(f, "\tLEA AX,%s\n\tCALL PUSH_VAL\n", nombreValido);
                else 
                    fprintf(f, "\tMOV AX,%s\n\tCALL PUSH_VAL\n", nombreValido);
            }
        }
    }

    fprintf(f, "\n\tRET\nMAIN ENDP\nEND START\n");
    fclose(f);
    printf(" final.asm Generado Correctamente.\n");
}



int yyerror(void) {
    printf("Error Sintactico\n");
    exit(1);
}