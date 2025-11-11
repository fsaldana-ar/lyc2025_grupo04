.386
.MODEL FLAT, C
.STACK 100h
.DATA
a                                DD ?
b                                DD ?
e                                DD ?
f                                DD ?
g                                DD ?
h                                DD ?
c                                DD ?
d                                DD ?
i                                DD ?
j                                DD ?
nombre                           DB 100 DUP('$')
apellido                         DB 100 DUP('$')
fecha                            DD ?
_5                               DD 5
_3                               DD 3
_99_5                            DD 42C70000h
_5_0                             DD 40A00000h
_8_0                             DD 41000000h
_10                              DD 10
__2                              DD -2
_2                               DD 2
_0_2                             DD 3E4CCCCDh
_0_3                             DD 3E99999Ah
__0_5                            DD BF000000h
const_string_1                   DB "El valor de a es:$",0
const_string_2                   DB "a es mayor que b$",0
const_string_3                   DB "a es menor que b$",0
const_string_4                   DB "a es mayor o igual que b$",0
const_string_5                   DB "Incrementando a$",0
_1                               DD 1
const_string_6                   DB "Ciclo anidado$",0
const_string_7                   DB "Condicion AND verdadera$",0
const_string_8                   DB "Condicion OR verdadera$",0
const_string_9                   DB "Condicion NOT verdadera$",0
const_string_10                  DB "a es igual a 10$",0
_20250821                        DD 20250821
_gci_str_0                       DB "El valor de a es:$",0
_gci_str_1                       DB "a es mayor que b$",0
_gci_str_2                       DB "a es menor que b$",0
_gci_str_3                       DB "a es mayor o igual que b$",0
_gci_str_4                       DB "Incrementando a$",0
_gci_str_5                       DB "Ciclo anidado$",0
_gci_str_6                       DB "Condicion AND verdadera$",0
_gci_str_7                       DB "Condicion OR verdadera$",0
_gci_str_8                       DB "Condicion NOT verdadera$",0
_gci_str_9                       DB "a es igual a 10$",0
_0 DD 0
TOP DD 0
STK DD 256 DUP(?)
BUFNUM DB 7 DUP('$')

.CODE
START:
;--- PUSHD ---
PUSHD PROC
    MOV EBX,TOP
    SHL EBX,2
    MOV STK[EBX],EAX
    INC TOP
    RET
PUSHD ENDP
;--- POPD ---
POPD PROC
    DEC TOP
    MOV EBX,TOP
    SHL EBX,2
    MOV EAX,STK[EBX]
    RET
POPD ENDP
;--- POP2 ---
POP2 PROC
    CALL POPD
    PUSH EAX
    CALL POPD
    POP EBX
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
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_INT ENDP
	MOV EAX,_5
	CALL PUSHD
	MOV EAX,a
	CALL PUSHD
	CALL POPD
	MOV DWORD PTR a,EAX
	MOV EAX,a
	CALL PUSHD
	MOV EAX,_3
	CALL PUSHD
	CALL POP2
	ADD EAX,EBX
	CALL PUSHD
	MOV EAX,b
	CALL PUSHD
	CALL POPD
	MOV DWORD PTR b,EAX
	MOV EAX,_99_5
	CALL PUSHD
	MOV EAX,c
	CALL PUSHD
	CALL POPD
	MOV DWORD PTR c,EAX
	MOV EAX,_5_0
	CALL PUSHD
	MOV EAX,_8_0
	CALL PUSHD
	CALL POP2
	IMUL EAX,EBX
	CALL PUSHD
	MOV EAX,d
	CALL PUSHD
	CALL POPD
	MOV DWORD PTR d,EAX
	MOV EAX,_10
	CALL PUSHD
	MOV EAX,_3
	CALL PUSHD
	CALL POP2
	XCHG EAX,EBX
	CDQ
	IDIV EBX
	MOV EAX,EDX
	CALL PUSHD
	MOV EAX,a
	CALL PUSHD
	CALL POPD
	MOV DWORD PTR a,EAX
	MOV EAX,__2
	CALL PUSHD
	MOV EAX,e
	CALL PUSHD
	CALL POPD
	MOV DWORD PTR e,EAX
	MOV EAX,b
	CALL PUSHD
	MOV EAX,a
	CALL PUSHD
	CALL POP2
	SUB EBX,EAX
	MOV EAX,EBX
	CALL PUSHD
	MOV EAX,e
	CALL PUSHD
	CALL POP2
	IMUL EAX,EBX
	CALL PUSHD
	MOV EAX,_3
	CALL PUSHD
	CALL POP2
	SUB EBX,EAX
	MOV EAX,EBX
	CALL PUSHD
	MOV EAX,f
	CALL PUSHD
	CALL POPD
	MOV DWORD PTR f,EAX
	MOV EAX,b
	CALL PUSHD
	MOV EAX,a
	CALL PUSHD
	CALL POP2
	SUB EBX,EAX
	MOV EAX,EBX
	CALL PUSHD
	MOV EAX,e
	CALL PUSHD
	CALL POP2
	IMUL EAX,EBX
	CALL PUSHD
	MOV EAX,_3
	CALL PUSHD
	CALL POP2
	SUB EBX,EAX
	MOV EAX,EBX
	CALL PUSHD
	MOV EAX,g
	CALL PUSHD
	CALL POPD
	MOV DWORD PTR g,EAX
	MOV EAX,_2
	CALL PUSHD
	MOV EAX,_3
	CALL PUSHD
	CALL POP2
	IMUL EAX,EBX
	CALL PUSHD
	MOV EAX,h
	CALL PUSHD
	CALL POPD
	MOV DWORD PTR h,EAX
	MOV EAX,_0_2
	CALL PUSHD
	MOV EAX,_0_3
	CALL PUSHD
	CALL POP2
	SUB EBX,EAX
	MOV EAX,EBX
	CALL PUSHD
	MOV EAX,i
	CALL PUSHD
	CALL POPD
	MOV DWORD PTR i,EAX
	MOV EAX,__0_5
	CALL PUSHD
	MOV EAX,j
	CALL PUSHD
	CALL POPD
	MOV DWORD PTR j,EAX
	MOV EAX,a
	CALL PUSHD
	; READ no genera ASM
	MOV EAX, OFFSET _gci_str_0
	CALL PUSHD
	CALL POPD
	MOV EDX,EAX
	CALL PRINT_STR
	MOV EAX,a
	CALL PUSHD
	CALL POPD
	CALL PRINT_INT
	MOV EAX,a
	CALL PUSHD
	MOV EAX,b
	CALL PUSHD
	CALL POP2
	CMP EBX,EAX
	JLE L68
	MOV EAX, OFFSET _gci_str_1
	CALL PUSHD
	CALL POPD
	MOV EDX,EAX
	CALL PRINT_STR
L68:
	MOV EAX,a
	CALL PUSHD
	MOV EAX,b
	CALL PUSHD
	CALL POP2
	CMP EBX,EAX
	JGE L77
	MOV EAX, OFFSET _gci_str_2
	CALL PUSHD
	CALL POPD
	MOV EDX,EAX
	CALL PRINT_STR
	JMP L79
L77:
	MOV EAX, OFFSET _gci_str_3
	CALL PUSHD
	CALL POPD
	MOV EDX,EAX
	CALL PRINT_STR
L79:
	MOV EAX,a
	CALL PUSHD
	MOV EAX,_10
	CALL PUSHD
	CALL POP2
	CMP EBX,EAX
	JGE L107
	MOV EAX, OFFSET _gci_str_4
	CALL PUSHD
	CALL POPD
	MOV EDX,EAX
	CALL PRINT_STR
	MOV EAX,a
	CALL PUSHD
	MOV EAX,_1
	CALL PUSHD
	CALL POP2
	ADD EAX,EBX
	CALL PUSHD
	MOV EAX,a
	CALL PUSHD
	CALL POPD
	MOV DWORD PTR a,EAX
L91:
	MOV EAX,b
	CALL PUSHD
	MOV EAX,_5
	CALL PUSHD
	CALL POP2
	CMP EBX,EAX
	JGE L105
	MOV EAX,b
	CALL PUSHD
	MOV EAX,_1
	CALL PUSHD
	CALL POP2
	ADD EAX,EBX
	CALL PUSHD
	MOV EAX,b
	CALL PUSHD
	CALL POPD
	MOV DWORD PTR b,EAX
	MOV EAX, OFFSET _gci_str_5
	CALL PUSHD
	CALL POPD
	MOV EDX,EAX
	CALL PRINT_STR
	JMP L91
L105:
	JMP L79
L107:
	MOV EAX,a
	CALL PUSHD
	MOV EAX,b
	CALL PUSHD
	CALL POP2
	CMP EBX,EAX
	JGE L119
	MOV EAX,c
	CALL PUSHD
	MOV EAX,d
	CALL PUSHD
	CALL POP2
	CMP EBX,EAX
	JLE L119
	MOV EAX, OFFSET _gci_str_6
	CALL PUSHD
	CALL POPD
	MOV EDX,EAX
	CALL PRINT_STR
L119:
	MOV EAX,a
	CALL PUSHD
	MOV EAX,b
	CALL PUSHD
	CALL POP2
	CMP EBX,EAX
	JGE L126
	JMP L131
L126:
	MOV EAX,c
	CALL PUSHD
	MOV EAX,d
	CALL PUSHD
	CALL POP2
	CMP EBX,EAX
	JLE L133
L131:
	MOV EAX, OFFSET _gci_str_7
	CALL PUSHD
	CALL POPD
	MOV EDX,EAX
	CALL PRINT_STR
L133:
	MOV EAX,a
	CALL PUSHD
	MOV EAX,b
	CALL PUSHD
	CALL POP2
	CMP EBX,EAX
	JG L140
	MOV EAX, OFFSET _gci_str_8
	CALL PUSHD
	CALL POPD
	MOV EDX,EAX
	CALL PRINT_STR
L140:
	MOV EAX,a
	CALL PUSHD
	MOV EAX,_10
	CALL PUSHD
	CALL POP2
	SUB EBX,EAX
	MOV EAX,EBX
	CALL PUSHD
	MOV EAX,_0
	CALL PUSHD
	CALL POP2
	CMP EBX,EAX
	JNE L149
	MOV EAX, OFFSET _gci_str_9
	CALL PUSHD
	CALL POPD
	MOV EDX,EAX
	CALL PRINT_STR
L149:
	MOV EAX,_20250821
	CALL PUSHD
	MOV EAX,fecha
	CALL PUSHD
	CALL POPD
	MOV DWORD PTR fecha,EAX
	MOV EAX,fecha
	CALL PUSHD
	CALL POPD
	CALL PRINT_INT

	MOV AX,4C00h
	INT 21h
END START
