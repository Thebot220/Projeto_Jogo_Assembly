.386
.model flat, stdcall
.stack 4096

; =========================================================================
; PROTÓTIPOS DA WIN32 API (Equivalentes às syscalls do Linux)
; =========================================================================
GetStdHandle PROTO, nStdHandle:DWORD
WriteConsoleA PROTO, hConsoleOutput:DWORD, lpBuffer:DWORD, nNumberOfCharsToWrite:DWORD, lpNumberOfCharsWritten:DWORD, lpReserved:DWORD
ExitProcess PROTO, dwExitCode:DWORD

.const
STD_OUTPUT_HANDLE EQU -11       ; Identificador para o console (stdout)

.data
msg             db "Salve, simpatia!", 10
len             EQU $ - msg     ; Tamanho da string calculado da mesma forma
bytesEscritos   DWORD ?
hConsole        DWORD ?

.code
main PROC
    ; 1. Obter o manipulador da tela (Equivalente ao descritor rdi = 1)
    INVOKE GetStdHandle, STD_OUTPUT_HANDLE
    mov hConsole, eax

    ; 2. Escrever a mensagem na tela (Equivalente ao sys_write / rax = 1)
    INVOKE WriteConsoleA, hConsole, ADDR msg, len, ADDR bytesEscritos, 0

    ; 3. Finalizar o programa com código 0 (Equivalente ao sys_exit / rax = 60)
    INVOKE ExitProcess, 0
main ENDP

END main