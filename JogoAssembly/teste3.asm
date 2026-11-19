.386
.model flat, stdcall
.stack 4096

; Funções nativas do Windows (Win32 API)
ExitProcess PROTO, dwExitCode:DWORD
GetStdHandle PROTO, nStdHandle:DWORD
WriteConsoleA PROTO, hConsoleOutput:DWORD, lpBuffer:PTR BYTE, nNumberOfCharsToWrite:DWORD, lpNumberOfCharsWritten:PTR DWORD, lpReserved:PTR DWORD

.const
STD_OUTPUT_HANDLE EQU -11
LARGURA_MAPA      EQU 29
ALTURA_MAPA       EQU 13

.data
; Matriz do mapa (29x13): 
; 1 = Chão/Parede (#)
; 0 = Ar (Espaço em branco)
; 2 = Armadilha/Espinho (^)
mapa db 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
     db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
     db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
     db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 1
     db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1
     db 1, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
     db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1
     db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1
     db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 0, 0, 1
     db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1
     db 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
     db 1, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1
     db 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1

; Caracteres visuais para imprimir no console
charChao      db "#"
charAr        db " "
charArmadilha db "^"
charQuebra    db 13, 10 ; Quebra de linha (CRLF)

hConsole      DWORD ?
bytesEscritos DWORD ?

.code

; Função que percorre a matriz e imprime os caracteres no console
DesenharMapaConsole PROC
    LOCAL linha:DWORD, coluna:DWORD

    mov linha, 0

LoopLinhas:
    mov coluna, 0

LoopColunas:
    ; 1. Calcula o índice na memória: EAX = (linha * LARGURA_MAPA) + coluna
    mov eax, linha
    mov ebx, LARGURA_MAPA
    mul ebx
    add eax, coluna

    ; 2. Lê o valor do bloco na matriz
    mov bl, byte ptr [mapa + eax]

    ; 3. Decide qual caractere imprimir na tela
    cmp bl, 1
    je ImprimirChao

    cmp bl, 2
    je ImprimirArmadilha

    ; Se for 0 (Ar)
    INVOKE WriteConsoleA, hConsole, ADDR charAr, 1, ADDR bytesEscritos, 0
    jmp ProximoTile

ImprimirChao:
    INVOKE WriteConsoleA, hConsole, ADDR charChao, 1, ADDR bytesEscritos, 0
    jmp ProximoTile

ImprimirArmadilha:
    INVOKE WriteConsoleA, hConsole, ADDR charArmadilha, 1, ADDR bytesEscritos, 0

ProximoTile:
    inc coluna
    cmp coluna, LARGURA_MAPA
    jl LoopColunas

    ; Imprime uma quebra de linha ao terminar cada linha da matriz
    INVOKE WriteConsoleA, hConsole, ADDR charQuebra, 2, ADDR bytesEscritos, 0

    inc linha
    cmp linha, ALTURA_MAPA
    jl LoopLinhas

    ret
DesenharMapaConsole ENDP

; Ponto de entrada principal do programa
main PROC
    ; Obtém o identificador (handle) de saída da tela do console
    INVOKE GetStdHandle, STD_OUTPUT_HANDLE
    mov hConsole, eax

    ; Chama a função que varre a matriz e desenha o mapa
    CALL DesenharMapaConsole

    ; Encerra a execução de forma limpa
    INVOKE ExitProcess, 0
main ENDP

END main