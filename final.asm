.MODEL SMALL
.STACK 100h
.DATA
a                                DW ?
b                                DW ?
e                                DW ?
f                                DW ?
g                                DW ?
h                                DW ?
q                                DW ?
c                                DW ?
d                                DW ?
i                                DW ?
j                                DW ?
nombre                           DB 100 DUP('$')
apellido                         DB 100 DUP('$')
fecha                            DW ?
_5                               DW 5
_3                               DW 3
_99_5                            DW 995 ; 99.5
_5_0                             DW 50 ; 5.0
_8_0                             DW 80 ; 8.0
_10                              DW 10
__2                              DW -2
_2                               DW 2
_0_2                             DW 2 ; 0.2
_0_3                             DW 2 ; 0.3
__0_5                            DW -5 ; -0.5
_1                               DW 1
const_string_1                   DB "Ingrese el valor de a$"
const_string_2                   DB "El valor de a es:$"
const_string_3                   DB "a es mayor que b$"
const_string_4                   DB "a es menor que b$"
const_string_5                   DB "a es mayor o igual que b$"
const_string_6                   DB "Toque cualquier tecla para continuar$"
const_string_7                   DB "Incrementando a$"
_7                               DW 7
_9                               DW 9
const_string_8                   DB "incrementando b$"
const_string_9                   DB "Toque cualquier letra para continuar$"
_11                              DW 11
const_string_10                  DB "Condicion AND verdadera$"
const_string_11                  DB "Condicion OR verdadera$"
const_string_12                  DB "Condicion NOT verdadera$"
const_string_13                  DB "a es igual a 10$"
_20250121                        DW 65033 ; 20250121
const_string_14                  DB "Fecha:$"
_gci_str_0                       DB "Ingrese el valor de a$"
_gci_str_1                       DB "El valor de a es:$"
_gci_str_2                       DB "a es mayor que b$"
_gci_str_3                       DB "a es menor que b$"
_gci_str_4                       DB "a es mayor o igual que b$"
_gci_str_5                       DB "Toque cualquier tecla para continuar$"
_gci_str_6                       DB "Incrementando a$"
_gci_str_7                       DB "incrementando b$"
_gci_str_8                       DB "Toque cualquier letra para continuar$"
_gci_str_9                       DB "Condicion AND verdadera$"
_gci_str_10                      DB "Condicion OR verdadera$"
_gci_str_11                      DB "Condicion NOT verdadera$"
_gci_str_12                      DB "a es igual a 10$"
_gci_str_13                      DB "Fecha:$"
fecha_date_str                   DB "20250121$"
_0 DW 0
__ DW 0 ; fallback para simbolo placeholder
TOP DW 0
STK DW 256 DUP(?)
BUFNUM DB 7 DUP('$')
NEWLINE DB 13,10,'$'

.CODE
START:
    MOV AX,@DATA
    MOV DS,AX
    CALL MAIN
    MOV AX,4C00h
    INT 21h

;--- PUSH (16 bits) ---
PUSH_VAL PROC
    MOV BX,TOP
    SHL BX,1
    MOV STK[BX],AX
    INC TOP
    RET
PUSH_VAL ENDP
;--- POP (16 bits) ---
POP_VAL PROC
    DEC TOP
    MOV BX,TOP
    SHL BX,1
    MOV AX,STK[BX]
    RET
POP_VAL ENDP
;--- POP2 (16 bits) ---
POP2 PROC
    CALL POP_VAL
    PUSH AX
    CALL POP_VAL
    POP BX
    RET
POP2 ENDP
;--- PRINT_STR ---
PRINT_STR PROC
    MOV AH,09h
    INT 21h
    RET
PRINT_STR ENDP
;--- PRINT_INT ---
PRINT_INT PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI
    ; Limpiar buffer
    LEA DI,BUFNUM
    MOV CX,7
    MOV AL,'$'
    REP STOSB
    ; Convertir numero
    LEA DI,BUFNUM
    MOV CX,0
    CMP AX,0
    JGE PI_LOOP
    NEG AX
    PUSH AX
    MOV AL,'-'
    STOSB
    POP AX
PI_LOOP:
    XOR DX,DX
    MOV BX,10
    DIV BX
    ADD DL,'0'
    PUSH DX
    INC CX
    CMP AX,0
    JNE PI_LOOP
PI_OUT:
    POP AX
    MOV AL,AL
    STOSB
    LOOP PI_OUT
    MOV AL,'$'
    STOSB
    LEA DX,BUFNUM
    CALL PRINT_STR
    POP DI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_INT ENDP
;--- PRINT_NEWLINE ---
PRINT_NEWLINE PROC
    PUSH DX
    LEA DX,NEWLINE
    CALL PRINT_STR
    POP DX
    RET
PRINT_NEWLINE ENDP
;--- READ_INT ---
READ_INT PROC
    PUSH BX
    PUSH CX
    PUSH DX
    MOV BX,0
    MOV CX,0
RI_LOOP:
    MOV AH,01h
    INT 21h
    CMP AL,13
    JE RI_END
    CMP AL,'-'
    JNE RI_DIGIT
    MOV CX,1
    JMP RI_LOOP
RI_DIGIT:
    SUB AL,'0'
    MOV AH,0
    XCHG AX,BX
    MOV DX,10
    MUL DX
    ADD BX,AX
    JMP RI_LOOP
RI_END:
    MOV AX,BX
    CMP CX,1
    JNE RI_RET
    NEG AX
RI_RET:
    POP DX
    POP CX
    POP BX
    RET
READ_INT ENDP

;--- MAIN PROGRAM ---
MAIN PROC
	; a := _5
	MOV AX,_5
	MOV a,AX
	; b := a + _3
	MOV AX,a
	ADD AX,_3
	MOV b,AX
	; c := _99_5
	MOV AX,_99_5
	MOV c,AX
	; d := _5_0 * _8_0
	MOV AX,_5_0
	IMUL _8_0
	CWD
	IDIV _10
	MOV d,AX
	; a := _10 %% _3
	MOV AX,_10
	CWD
	IDIV _3
	MOV AX,DX
	MOV a,AX
	; e := __2
	MOV AX,__2
	MOV e,AX
	MOV AX,b
	CALL PUSH_VAL
	MOV AX,a
	CALL PUSH_VAL
	CALL POP2
	SUB AX,BX
	CALL PUSH_VAL
	MOV AX,e
	CALL PUSH_VAL
	CALL POP2
	IMUL BX
	CALL PUSH_VAL
	MOV AX,_3
	CALL PUSH_VAL
	CALL POP2
	SUB AX,BX
	CALL PUSH_VAL
	MOV AX,f
	CALL PUSH_VAL
	CALL POP_VAL
	MOV f,AX
	MOV AX,b
	CALL PUSH_VAL
	MOV AX,a
	CALL PUSH_VAL
	CALL POP2
	SUB AX,BX
	CALL PUSH_VAL
	MOV AX,e
	CALL PUSH_VAL
	CALL POP2
	IMUL BX
	CALL PUSH_VAL
	MOV AX,_3
	CALL PUSH_VAL
	CALL POP2
	SUB AX,BX
	CALL PUSH_VAL
	MOV AX,g
	CALL PUSH_VAL
	CALL POP_VAL
	MOV g,AX
	; h := _2 * _3
	MOV AX,_2
	IMUL _3
	MOV h,AX
	; i := _0_2 - _0_3
	MOV AX,_0_2
	SUB AX,_0_3
	MOV i,AX
	; j := __0_5
	MOV AX,__0_5
	MOV j,AX
	; q := _1
	MOV AX,_1
	MOV q,AX
	LEA AX,_gci_str_0
	CALL PUSH_VAL
	CALL POP_VAL
	MOV DX,AX
	CALL PRINT_STR
	CALL PRINT_NEWLINE
	CALL READ_INT
	MOV a,AX
	CALL PRINT_NEWLINE
	LEA AX,_gci_str_1
	CALL PUSH_VAL
	CALL POP_VAL
	MOV DX,AX
	CALL PRINT_STR
	CALL PRINT_NEWLINE
	MOV AX,a
	CALL PUSH_VAL
	CALL POP_VAL
	CALL PRINT_INT
	CALL PRINT_NEWLINE
	MOV AX,a
	CALL PUSH_VAL
	MOV AX,b
	CALL PUSH_VAL
	CALL POP2
	CMP AX,BX
	JLE L73
	LEA AX,_gci_str_2
	CALL PUSH_VAL
	CALL POP_VAL
	MOV DX,AX
	CALL PRINT_STR
	CALL PRINT_NEWLINE
L73:
	MOV AX,a
	CALL PUSH_VAL
	MOV AX,b
	CALL PUSH_VAL
	CALL POP2
	CMP AX,BX
	JGE L82
	LEA AX,_gci_str_3
	CALL PUSH_VAL
	CALL POP_VAL
	MOV DX,AX
	CALL PRINT_STR
	CALL PRINT_NEWLINE
	JMP L84
L82:
	LEA AX,_gci_str_4
	CALL PUSH_VAL
	CALL POP_VAL
	MOV DX,AX
	CALL PRINT_STR
	CALL PRINT_NEWLINE
L84:
	LEA AX,_gci_str_5
	CALL PUSH_VAL
	CALL POP_VAL
	MOV DX,AX
	CALL PRINT_STR
	CALL PRINT_NEWLINE
	CALL READ_INT
	MOV q,AX
	CALL PRINT_NEWLINE
L88:
	MOV AX,a
	CALL PUSH_VAL
	MOV AX,_10
	CALL PUSH_VAL
	CALL POP2
	CMP AX,BX
	JGE L119
	LEA AX,_gci_str_6
	CALL PUSH_VAL
	CALL POP_VAL
	MOV DX,AX
	CALL PRINT_STR
	CALL PRINT_NEWLINE
	; a := a + _1
	MOV AX,a
	ADD AX,_1
	MOV a,AX
	; b := _7
	MOV AX,_7
	MOV b,AX
L103:
	MOV AX,b
	CALL PUSH_VAL
	MOV AX,_9
	CALL PUSH_VAL
	CALL POP2
	CMP AX,BX
	JGE L117
	; b := b + _1
	MOV AX,b
	ADD AX,_1
	MOV b,AX
	LEA AX,_gci_str_7
	CALL PUSH_VAL
	CALL POP_VAL
	MOV DX,AX
	CALL PRINT_STR
	CALL PRINT_NEWLINE
	JMP L103
L117:
	JMP L88
L119:
	LEA AX,_gci_str_8
	CALL PUSH_VAL
	CALL POP_VAL
	MOV DX,AX
	CALL PRINT_STR
	CALL PRINT_NEWLINE
	CALL READ_INT
	MOV q,AX
	CALL PRINT_NEWLINE
	; b := _11
	MOV AX,_11
	MOV b,AX
	MOV AX,a
	CALL PUSH_VAL
	MOV AX,b
	CALL PUSH_VAL
	CALL POP2
	CMP AX,BX
	JGE L138
	MOV AX,c
	CALL PUSH_VAL
	MOV AX,d
	CALL PUSH_VAL
	CALL POP2
	CMP AX,BX
	JLE L138
	LEA AX,_gci_str_9
	CALL PUSH_VAL
	CALL POP_VAL
	MOV DX,AX
	CALL PRINT_STR
	CALL PRINT_NEWLINE
L138:
	MOV AX,a
	CALL PUSH_VAL
	MOV AX,b
	CALL PUSH_VAL
	CALL POP2
	CMP AX,BX
	JGE L145
	JMP L150
L145:
	MOV AX,c
	CALL PUSH_VAL
	MOV AX,d
	CALL PUSH_VAL
	CALL POP2
	CMP AX,BX
	JLE L152
L150:
	LEA AX,_gci_str_10
	CALL PUSH_VAL
	CALL POP_VAL
	MOV DX,AX
	CALL PRINT_STR
	CALL PRINT_NEWLINE
L152:
	MOV AX,a
	CALL PUSH_VAL
	MOV AX,b
	CALL PUSH_VAL
	CALL POP2
	CMP AX,BX
	JG L159
	LEA AX,_gci_str_11
	CALL PUSH_VAL
	CALL POP_VAL
	MOV DX,AX
	CALL PRINT_STR
	CALL PRINT_NEWLINE
L159:
	MOV AX,a
	CALL PUSH_VAL
	MOV AX,_10
	CALL PUSH_VAL
	CALL POP2
	SUB AX,BX
	CALL PUSH_VAL
	MOV AX,_0
	CALL PUSH_VAL
	CALL POP2
	CMP AX,BX
	JNE L168
	LEA AX,_gci_str_12
	CALL PUSH_VAL
	CALL POP_VAL
	MOV DX,AX
	CALL PRINT_STR
	CALL PRINT_NEWLINE
L168:
	; fecha := _20250121
	MOV AX,_20250121
	MOV fecha,AX
	LEA AX,_gci_str_13
	CALL PUSH_VAL
	CALL POP_VAL
	MOV DX,AX
	CALL PRINT_STR
	CALL PRINT_NEWLINE
	MOV AX,fecha
	CALL PUSH_VAL
	CALL POP_VAL
	LEA DX,fecha_date_str
	CALL PRINT_STR
	CALL PRINT_NEWLINE

	RET
MAIN ENDP
END START
