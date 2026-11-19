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
ReadConsoleA PROTO, hConsoleInput:DWORD, lpBuffer:PTR BYTE, nNumberOfCharsToRead:DWORD, lpNumberOfCharsRead:PTR DWORD, pInputControl:PTR DWORD
SetConsoleOutputCP PROTO, wCodePageID:DWORD

.const
	LARGURA_MAPA	EQU 29
	ALTURA_MAPA		EQU 13
	SUPORTE_TERMINAL EQU -11
    SUPORTE_ENTRADA EQU -10
    velocidade EQU -3

.data
    nomeFase1 db "fase1.txt", 0
    nomeFase2 db "fase2.txt", 0
    nomeFase3 db "fase3.txt", 0
    hArquivo DWORD ?
    bytesLidos DWORD ?

    mapaBuffer db 1024 dup(0)
	mapa db 377 dup(0)

    limparTela db 27, "[2J", 27, "[H", 0

    vazio db " "
    parede db "#"
    armadilha db "^"
    quebra_de_linha db 13, 10

    frases LABEL BYTE
    fraseEscolha db "Escolha o nível que deseja jogar",10
    fraseErro1 db "Essa escolha não é válida, tente novamente", 10

    hConsole DWORD ?
    bytesEscritos DWORD ?

    hEntrada DWORD ?
    selecaoBuffer db 4 dup(0)
    bytesLidosConsole DWORD ?

    personagem1 db "@"
    personagem1_x DWORD ?
    personagem1_y DWORD ?
    reset1_x DWORD ?
    reset1_y DWORD ?
    linha DWORD ?
    coluna DWORD ?
    velocidadeAtual DWORD ?
    noAR DWORD ?

.code

    main PROC
        INVOKE SetConsoleOutputCP, 65001    ; Muda o terminal para UTF-8

        INVOKE GetStdHandle, SUPORTE_TERMINAL
        mov hConsole, eax

        INVOKE GetStdHandle, SUPORTE_ENTRADA
        mov hEntrada, eax

        escolha:
        INVOKE WriteConsoleA, hConsole, ADDR fraseEscolha, SIZEOF fraseEscolha, ADDR bytesEscritos, 0

        INVOKE ReadConsoleA, hEntrada, ADDR selecaoBuffer, 3, ADDR bytesLidosConsole, 0

        cmp selecaoBuffer, '1'
        je fase1

        cmp selecaoBuffer, '2'
        je fase2

        cmp selecaoBuffer, '3'
        je fase3

        INVOKE WriteConsoleA, hConsole, ADDR fraseErro1, SIZEOF fraseErro1, ADDR bytesEscritos, 0
        jmp escolha

        fase1:
            mov edx, OFFSET nomeFase1
            mov personagem1_x, 2
            mov personagem1_y, 11
            mov reset1_x, 2
            mov reset1_y, 11
            jmp montarMapa

        fase2:
            mov edx, OFFSET nomeFase2
            mov personagem1_x, 1
            mov personagem1_y, 8
            mov reset1_x, 1
            mov reset1_y, 8
            jmp montarMapa

        fase3:
            mov edx, OFFSET nomeFase3
            mov personagem1_x, 15
            mov personagem1_y, 8
            mov reset1_x, 15
            mov reset1_y, 8

        montarMapa:
            INVOKE CreateFileA, edx, 80000000h, 1, 0, 3, 128, 0
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
                    jmp iniciaJogo

        erroArquivo: 
            INVOKE ExitProcess, 1

        iniciaJogo:
        INVOKE WriteConsoleA, hConsole, ADDR limparTela, 7, ADDR bytesEscritos, 0

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

                mov ebx, reset1_x
                mov ecx, reset1_y
                mov personagem1_x, ebx
                mov personagem1_y, ecx
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