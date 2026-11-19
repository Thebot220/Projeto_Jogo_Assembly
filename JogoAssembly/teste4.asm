.386
.model flat, stdcall
.stack 4096

; Funções nativas do Windows (Win32 API)
ExitProcess PROTO, dwExitCode:DWORD
GetStdHandle PROTO, nStdHandle:DWORD
WriteConsoleA PROTO, hConsoleOutput:DWORD, lpBuffer:PTR BYTE, nNumberOfCharsToWrite:DWORD, lpNumberOfCharsWritten:PTR DWORD, lpReserved:PTR DWORD
Sleep PROTO, dwMilliseconds:DWORD
GetAsyncKeyState PROTO, vKey:DWORD
SetConsoleCursorPosition PROTO, hConsoleOutput:DWORD, dwCursorPosition:DWORD

.const
	LARGURA_MAPA	EQU 29
	ALTURA_MAPA		EQU 13
	SUPORTE_TERMINAL EQU -11
    velocidade EQU -3

.data
	mapa db 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
         db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
         db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
         db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 1
         db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1
         db 1, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
         db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1
         db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1
         db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 1, 1, 0, 0, 0, 0, 1, 0, 0, 1
         db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1
         db 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
         db 1, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1
         db 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1

    vazio db " "
    parede db "#"
    armadilha db "^"
    quebra_de_linha db 13, 10

    hConsole DWORD ?
    bytesEscritos DWORD ?

    personagem1 db "@"
    personagem1_x DWORD 2
    personagem1_y DWORD 11
    velocidadeAtual DWORD ?
    noAR DWORD ?

.code

    main PROC
        LOCAL linha: DWORD, coluna: DWORD

        INVOKE GetStdHandle, SUPORTE_TERMINAL
        mov hConsole, eax

        loopJogo:
            INVOKE SetConsoleCursorPosition, hConsole, 0

            frente:
                INVOKE GetAsyncKeyState, 44h
                and eax, 8000h
                jz tras
                inc personagem1_x

            tras:
                INVOKE GetAsyncKeyState, 41h
                and eax, 8000h
                jz pulo
                dec personagem1_x

            pulo:
                cmp noAR, 0
                jne gravidade
                INVOKE GetAsyncKeyState, 57h
                and eax, 8000h
                jz gravidade
                mov noAr, 1
                mov velocidadeAtual, velocidade
                mov ebx, velocidadeAtual
                add personagem1_y, ebx

            gravidade:
                mov eax, personagem1_y
                add eax, 1
                mov ebx, LARGURA_MAPA
                mul ebx
                add eax, personagem1_x
                mov bl, byte ptr [mapa + eax]
                cmp bl, 1
                je chao
                inc personagem1_y
                jmp desenho

                chao:
                    mov noAr, 0

            checaArmadilha:
                mov eax, personagem1_y
                mov ebx, LARGURA_MAPA
                mul ebx
                add eax, personagem1_x
                mov bl, byte ptr [mapa + eax]
                cmp bl, 2
                jne desenho

                mov personagem1_x, 2
                mov personagem1_y, 11
                mov noAR, 0


        desenho:
        mov linha, 0

        loopLinhas:

        mov coluna, 0

            loopColunas:
                mov eax, linha
                mov ebx, LARGURA_MAPA
                mul ebx
                add eax, coluna

                mov cl, byte ptr [mapa + eax]

                verificaColuna:
                    mov edx, personagem1_x
                    cmp coluna, edx
                    jne continua

                    verificaLinha:
                        mov edx, personagem1_y
                        cmp linha, edx
                        jne continua

                    imprimePersonagem:
                        INVOKE WriteConsoleA, hConsole, ADDR personagem1, 1, ADDR bytesEscritos, 0
                        jmp proximoTile

                continua:
                cmp cl, 1
                je imprimeParede

                cmp cl, 2
                je imprimeArmadilha

                imprimeVazio:
                    INVOKE WriteConsoleA, hConsole, ADDR vazio, 1, ADDR bytesEscritos, 0
                    jmp proximoTile

                imprimeArmadilha:
                    INVOKE WriteConsoleA, hConsole, ADDR armadilha, 1, ADDR bytesEscritos, 0
                    jmp proximoTile

                imprimeParede:
                    INVOKE WriteConsoleA, hConsole, ADDR parede, 1, ADDR bytesEscritos, 0
                    jmp proximoTile

                proximoTile:
                inc coluna
                cmp coluna, LARGURA_MAPA
                jl loopColunas

        INVOKE WriteConsoleA, hConsole, ADDR quebra_de_linha, 2, ADDR bytesEscritos, 0
        inc linha
        cmp linha, ALTURA_MAPA
        jl loopLinhas

        INVOKE Sleep, 50
        jmp loopJogo

        INVOKE ExitProcess, 0
    main ENDP

END main