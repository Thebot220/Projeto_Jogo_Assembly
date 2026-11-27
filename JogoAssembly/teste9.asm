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
FlushConsoleInputBuffer PROTO, hConsoleInput:DWORD
SetConsoleOutputCP PROTO, wCodePageID:DWORD

.const
	LARGURA_MAPA	EQU 29
	ALTURA_MAPA		EQU 13
	SUPORTE_TERMINAL EQU -11
    SUPORTE_ENTRADA EQU -10
    velocidade EQU -3
    TEMPO_PORTAL_REQ EQU 40

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
    portal1 db "O"
    portal2 db "0"
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
    personagem2 db "&"
    personagem2_x DWORD ?
    personagem2_y DWORD ?

    flecha db ">"
    flecha2 db "<"
    flecha_x DWORD ?
    flecha_y DWORD ?

    escudo db "-"
    hbescudo_x DWORD 0
    hbescudo_y DWORD 0

    reset1_x DWORD ?
    reset1_y DWORD ?
    reset2_x DWORD ?
    reset2_y DWORD ?

    linha DWORD ?
    coluna DWORD ?
    velocidadeAtual DWORD ?
    noAR DWORD ?    
    noAR2 DWORD ?

    escudoAtivo DWORD 0
    flechaAtiva DWORD 0

    temPortal1 DWORD 0
    temPortal2 DWORD 0
    tempoPortal1 DWORD 0
    tempoPortal2 DWORD 0


.code

    main PROC
        INVOKE SetConsoleOutputCP, 65001    ; Muda o terminal para UTF-8

        INVOKE GetStdHandle, SUPORTE_TERMINAL
        mov hConsole, eax

        INVOKE GetStdHandle, SUPORTE_ENTRADA
        mov hEntrada, eax

        escolha:
        mov temPortal1, 0
        mov temPortal2, 0
        mov tempoPortal1, 0
        mov tempoPortal2, 0

        mov noAr, 0
        mov noAr2, 0
        
        mov flechaAtiva, 0
        mov escudoAtivo, 0

        INVOKE FlushConsoleInputBuffer, hEntrada

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
            mov personagem2_x, 3
            mov personagem2_y, 11
            mov reset1_x, 2
            mov reset1_y, 11
            mov reset2_x, 3
            mov reset2_y, 11
            jmp montarMapa

        fase2:
            mov edx, OFFSET nomeFase2
            mov personagem1_x, 1
            mov personagem1_y, 8
            mov personagem2_x, 1
            mov personagem2_y, 8
            mov reset1_x, 1
            mov reset1_y, 8
            mov reset2_x, 2
            mov reset2_y, 8
            jmp montarMapa

        fase3:
            mov edx, OFFSET nomeFase3
            mov personagem1_x, 15
            mov personagem1_y, 8
            mov personagem2_x, 15
            mov personagem2_y, 8
            mov reset1_x, 15
            mov reset1_y, 8
            mov reset2_x, 16
            mov reset2_y, 8

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

                cmp al, 'O'
                jne checaP2NoMapa
                mov temPortal1, 1

                checaP2NoMapa:
                cmp al, '0'
                jne pulaCaractere
                mov temPortal2, 1

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
                jz direita2

                mov eax, personagem1_y
                mov ebx, LARGURA_MAPA
                mul ebx
                mov ebx, personagem1_x
                add ebx, 1
                add eax, ebx
                mov bl, byte ptr [mapa + eax]
                cmp bl, '#'
                je direita2
                inc personagem1_x

            direita2:
                INVOKE GetAsyncKeyState, 27h
                and eax, 8000h
                jz esquerda

                mov eax, personagem2_y
                mov ebx, LARGURA_MAPA
                mul ebx
                mov ebx, personagem2_x
                add ebx, 1
                add eax, ebx
                mov bl, byte ptr [mapa + eax]
                cmp bl, '#'
                je esquerda
                inc personagem2_x

            esquerda:
                INVOKE GetAsyncKeyState, 41h
                and eax, 8000h
                jz esquerda2

                mov eax, personagem1_y
                mov ebx, LARGURA_MAPA
                mul ebx
                mov ebx, personagem1_x
                sub ebx, 1
                add eax, ebx
                mov bl, byte ptr [mapa + eax]
                cmp bl, '#'
                je esquerda2
                dec personagem1_x

            esquerda2:
                INVOKE GetAsyncKeyState, 25h
                and eax, 8000h
                jz Arco

                mov eax, personagem2_y
                mov ebx, LARGURA_MAPA
                mul ebx
                mov ebx, personagem2_x
                sub ebx, 1
                add eax, ebx
                mov bl, byte ptr [mapa + eax]
                cmp bl, '#'
                je Arco
                dec personagem2_x

            Arco:
                INVOKE GetAsyncKeyState, 53h
                and eax, 8000h
                jz MoverFlecha

                cmp flechaAtiva, 0
                jne MoverFlecha

                flechaE:
                    INVOKE GetAsyncKeyState, 41h
                    and eax, 8000h
                    jz flechaD
                    mov flechaAtiva, -1
                    jmp iniciaFlecha

                flechaD:
                    INVOKE GetAsyncKeyState, 44h
                    and eax, 8000h
                    jz MoverFlecha
                    mov flechaAtiva, 1
                    jmp iniciaFlecha

                iniciaFlecha:
                    mov eax, personagem1_x
                    mov flecha_x, eax
                    mov eax, personagem1_y
                    mov flecha_y, eax

            MoverFlecha:
                cmp flechaAtiva, 0
                je EscudoBlock

                cmp flechaAtiva, -1
                je retrocederFlecha

                avancarFlecha:
                    mov eax, flecha_y
                    mov ebx, LARGURA_MAPA
                    mul ebx
                    mov ebx, flecha_x
                    add ebx, 1
                    add eax, ebx
                    mov bl, byte ptr [mapa + eax]
                    cmp bl, '#'
                    je desativacao
                    inc flecha_x
                    jmp EscudoBlock

                retrocederFlecha:
                    mov eax, flecha_y
                    mov ebx, LARGURA_MAPA
                    mul ebx
                    mov ebx, flecha_x
                    sub ebx, 1
                    add eax, ebx
                    mov bl, byte ptr [mapa + eax]
                    cmp bl, '#'
                    je desativacao
                    dec flecha_x
                    jmp EscudoBlock

                desativacao: 
                    mov flechaAtiva, 0
                    jmp EscudoBlock

            EscudoBlock:
                mov escudoAtivo, 0

                INVOKE GetAsyncKeyState, 28h
                and eax, 8000h
                jz pulo

                INVOKE GetAsyncKeyState, 26h
                and eax, 8000h
                jz pulo

                mov eax, personagem2_y
                cmp eax, 0
                je  sem_escudo              
                dec eax
                mov hbescudo_y, eax

                mov escudoAtivo, 1
                mov eax, personagem2_x
                mov hbescudo_x, eax
                jmp pulo

                sem_escudo:
                    mov escudoAtivo, 0
                    jmp pulo

            pulo:
                cmp noAR, 0
                jne pulo2
                INVOKE GetAsyncKeyState, 57h
                and eax, 8000h
                jz pulo2

                INVOKE GetAsyncKeyState, 53h
                and eax, 8000h
                jnz pulo2

                mov noAr, 1
                mov velocidadeAtual, velocidade
                mov ebx, velocidadeAtual
                add personagem1_y, ebx

            pulo2:
                cmp noAR2, 0
                jne gravidade
                INVOKE GetAsyncKeyState, 26h
                and eax, 8000h
                jz gravidade

                INVOKE GetAsyncKeyState, 28h
                and eax, 8000h
                jnz gravidade

                mov noAr2, 1
                mov velocidadeAtual, velocidade
                mov ebx, velocidadeAtual
                add personagem2_y, ebx

            gravidade:
                mov eax, personagem1_y
                add eax, 1
                mov ebx, LARGURA_MAPA
                mul ebx
                add eax, personagem1_x
                mov bl, byte ptr [mapa + eax]
                cmp bl, '#'
                je chao

                cmp escudoAtivo, 1
                jne cair

                mov eax, personagem1_x
                cmp eax, hbescudo_x
                jne cair

                mov eax, personagem1_y
                inc eax
                cmp eax, hbescudo_y
                je  chao

            cair:
                inc personagem1_y
                jmp gravidade2

            chao:
                mov noAr, 0

            gravidade2:
                mov eax, personagem2_y
                add eax, 1
                mov ebx, LARGURA_MAPA
                mul ebx
                add eax, personagem2_x
                mov bl, byte ptr [mapa + eax]
                cmp bl, '#'
                je chao2
                inc personagem2_y
                jmp checaArmadilha

                chao2:
                    mov noAr2, 0

            checaArmadilha:
                mov eax, personagem1_y
                mov ebx, LARGURA_MAPA
                mul ebx
                add eax, personagem1_x
                mov bl, byte ptr [mapa + eax]
                cmp bl, '^'
                jne checaArmadilha2

                mov ebx, reset1_x
                mov ecx, reset1_y
                mov personagem1_x, ebx
                mov personagem1_y, ecx
                mov noAR, 0

                mov ebx, reset2_x
                mov ecx, reset2_y
                mov personagem2_x, ebx
                mov personagem2_y, ecx
                mov noAR2, 0

            checaArmadilha2:
                mov eax, personagem2_y
                mov ebx, LARGURA_MAPA
                mul ebx
                add eax, personagem2_x
                mov bl, byte ptr [mapa + eax]
                cmp bl, '^'
                jne checaPlayer1Portal

                mov ebx, reset2_x
                mov ecx, reset2_y
                mov personagem2_x, ebx
                mov personagem2_y, ecx
                mov noAR2, 0
                
                mov ebx, reset1_x
                mov ecx, reset1_y
                mov personagem1_x, ebx
                mov personagem1_y, ecx
                mov noAR, 0

            checaPlayer1Portal:
                mov eax, personagem1_y
                mov ebx, LARGURA_MAPA
                mul ebx
                add eax, personagem1_x
                mov bl, byte ptr [mapa + eax]
                cmp bl, 'O'
                jne resetaTimer1
                inc tempoPortal1
                jmp checaPlayer2Portal

            resetaTimer1:
                    mov tempoPortal1, 0

            checaPlayer2Portal:
            mov eax, personagem2_y
            mov ebx, LARGURA_MAPA
            mul ebx
            add eax, personagem2_x
            mov bl, byte ptr [mapa + eax]
            cmp bl, '0'
            jne resetaTimer2
            inc tempoPortal2
            jmp avaliaCondicaoVitoria

            resetaTimer2:
                mov tempoPortal2, 0

            avaliaCondicaoVitoria:
                cmp temPortal1, 1
                jne somentePortal2

                cmp temPortal2, 1
                jne somentePortal1

                cmp tempoPortal1, TEMPO_PORTAL_REQ
                jl desenho
                cmp tempoPortal2, TEMPO_PORTAL_REQ
                jl desenho
                jmp voltaParaEscolha

                somentePortal1:
                    cmp tempoPortal1, TEMPO_PORTAL_REQ
                    jge voltaParaEscolha
                    jmp desenho

                somentePortal2:
                    cmp temPortal2, 1
                    jne desenho
                    cmp tempoPortal2, TEMPO_PORTAL_REQ
                    jge voltaParaEscolha
                    jmp desenho

                voltaParaEscolha:
                    INVOKE WriteConsoleA, hConsole, ADDR limparTela, 7, ADDR bytesEscritos, 0
                    jmp escolha



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
                    jne verificaColuna2

                    verificaLinha:
                        mov edx, personagem1_y
                        cmp linha, edx
                        jne verificaColuna2

                    imprimePersonagem:
                        INVOKE WriteConsoleA, hConsole, ADDR personagem1, 1, ADDR bytesEscritos, 0
                        jmp proximoTile
                        
                verificaColuna2:
                    mov edx, personagem2_x
                    cmp coluna, edx
                    jne verificaColunaEscudo

                    verificaLinha2:
                        mov edx, personagem2_y
                        cmp linha, edx
                        jne verificaColunaEscudo

                    imprimePersonagem2:
                        INVOKE WriteConsoleA, hConsole, ADDR personagem2, 1, ADDR bytesEscritos, 0
                        jmp proximoTile

                verificaColunaEscudo:
                    cmp escudoAtivo, 1
                    jne verificaColunaFlecha

                    mov edx, hbescudo_x
                    cmp coluna, edx
                    jne verificaColunaFlecha

                    verificaLinhaEscudo:
                        mov edx, hbescudo_y
                        cmp linha, edx
                        jne verificaColunaFlecha

                    imprimeEscudo:
                        INVOKE WriteConsoleA, hConsole, ADDR escudo, 1, ADDR bytesEscritos, 0
                        jmp proximoTile

                verificaColunaFlecha:
                    cmp flechaAtiva, 0
                    je continua

                    mov edx, flecha_x
                    cmp coluna, edx
                    jne continua

                    verificaLinhaFlecha:
                        mov edx, flecha_y
                        cmp linha, edx
                        jne continua

                    imprimeFlecha:
                        cmp flechaAtiva, -1
                        je imprimeFlechaE
                        INVOKE WriteConsoleA, hConsole, ADDR flecha, 1, ADDR bytesEscritos, 0
                        jmp proximoTile   
                        
                        imprimeFlechaE:
                            INVOKE WriteConsoleA, hConsole, ADDR flecha2, 1, ADDR bytesEscritos, 0
                            jmp proximoTile

                continua:
                cmp cl, '#'
                je imprimeParede

                cmp cl, '^'
                je imprimeArmadilha

                cmp cl, 'O'
                je imprimePortal1

                cmp cl, '0'
                je imprimePortal2

                imprimeVazio:
                    INVOKE WriteConsoleA, hConsole, ADDR vazio, 1, ADDR bytesEscritos, 0
                    jmp proximoTile

                imprimePortal1:
                    INVOKE WriteConsoleA, hConsole, ADDR portal1, 1, ADDR bytesEscritos, 0
                    jmp proximoTile

                imprimePortal2:
                    INVOKE WriteConsoleA, hConsole, ADDR portal2, 1, ADDR bytesEscritos, 0
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
