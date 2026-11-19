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
CreateFileA PROTO, lpFileName:PTR BYTE, dwDesiredAccess:DWORD, dwShareMode:DWORD, lpSecurityAttributes:PTR DWORD, dwCreationDisposition:DWORD, dwFlagsAndAttributes:DWORD, hTemplateFile:DWORD
ReadFile PROTO, hFile:DWORD, lpBuffer:PTR BYTE, nNumberOfBytesToRead:DWORD, lpNumberOfBytesRead:PTR DWORD, lpOverlapped:PTR DWORD
CloseHandle PROTO, hObject:DWORD

.const
	LARGURA_MAPA	EQU 29
	ALTURA_MAPA		EQU 13
	SUPORTE_TERMINAL EQU -11
    velocidade EQU -3

.data
    nomeFase1 db "fase1.txt", 0
    hArquivo DWORD ?
    bytesLidos DWORD ?

    mapaBuffer db 1024 dup(0)
	mapa db 377 dup(0)

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

        INVOKE CreateFileA, ADDR nomeFase1, 80000000h, 1, 0, 3, 128, 0
        mov hArquivo, eax

        cmp eax, -1
        je erroArquivo

        INVOKE ReadFile, hArquivo, ADDR mapaBuffer, 512, ADDR bytesLidos, 0
        INVOKE CloseHandle, hArquivo

        mov esi, 0
        mov edi, 0

        lacoParser:
            cmp edi, 377
            jge fimParser

            mov al, byte ptr [mapaBuffer + esi]

            cmp al, 0
            je fimParser

            cmp al, 13
            je pulaCaractere

            cmp al, 10
            je pulaCaractere

            mov byte ptr [mapa + edi], al
            inc edi

            pulaCaractere:
                inc esi
                jmp lacoParser

            fimParser:

        jmp iniciaConsole

        erroArquivo: 
            INVOKE ExitProcess, 1

        iniciaConsole:
        INVOKE GetStdHandle, SUPORTE_TERMINAL
        mov hConsole, eax

        loopJogo:
            INVOKE SetConsoleCursorPosition, hConsole, 0

            direita:
                INVOKE GetAsyncKeyState, 44h
                and eax, 8000h
                jz esquerda

                mov eax, personagem1_y
                mov ebx, LARGURA_MAPA
                mul ebx
                mov ebx, personagem1_x
                add ebx, 1
                add eax, ebx
                mov bl, byte ptr [mapa + eax]
                cmp bl, '#'  
                je esquerda
                inc personagem1_x

            esquerda:
                INVOKE GetAsyncKeyState, 41h
                and eax, 8000h
                jz pulo

                mov eax, personagem1_y
                mov ebx, LARGURA_MAPA
                mul ebx
                mov ebx, personagem1_x
                sub ebx, 1
                add eax, ebx
                mov bl, byte ptr [mapa + eax]
                cmp bl, '#'
                je pulo
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
                cmp bl, '#'
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
                cmp bl, '^'
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
                cmp cl, '#'
                je imprimeParede

                cmp cl, '^'
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