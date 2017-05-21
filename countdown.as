
;===============================================================================
; ZONA I: Definicao de constantes
;         Pseudo-instrucao : EQU
;===============================================================================

; TEMPORIZACAO
DELAYVALUE      EQU     000Ah

; STACK POINTER
SP_INICIAL      EQU     FDFFh

; INTERRUPCOES
TAB_INT0        EQU     FE00h
TAB_INT1        EQU     FE01h
TAB_INT2        EQU     FE02h
TAB_INTTemp     EQU     FE0Fh

; TEMPORIZADOR
TempValor     	EQU    FFF6h ;Permite arrancar (colocando o bit menos significativo a 1) ou parar (colocando o bit menos significativo a 0) o temporizador
TempControlo  	EQU    FFF7h ;Permite indicar o número de intrevalos de 100ms ao fim do qual o temporizador gerará uma interrupção
Int15_mask    	EQU    8000h


; I/O a partir de FF00H
DISP7S1         EQU     FFF0h ; 1ª célula do display
DISP7S2         EQU     FFF1h ; 2ª célula do display
DISP7S3         EQU     FFF2h ; 3º célula do display
DISP7S4         EQU     FFF3h ; 3º célula do display
IO_CURSOR       EQU     FFFCh
IO_WRITE        EQU     FFFEh


;PREENCHE A POSIÇÃO 15 DA TABELA DE INTERRUPCOES
               ; ORIG     FE0Fh
               ; INIT15   WORD  CriaIntrevalo

MASCARA_INT 	EQU 	FFFAh
LIMPAR_JANELA   EQU     FFFFh

; Time position in memory
TIME 			EQU 	F000h                

;===============================================================================
; ZONA III: Codigo
;           conjunto de instrucoes Assembly, ordenadas de forma a realizar
;           as funcoes pretendidas
;===============================================================================


                ORIG    0000h
                JMP     start
 
LimpaJanela:    PUSH 	R2
                MOV  	R2, LIMPAR_JANELA
				MOV  	M[IO_CURSOR], R2
                POP 	R2
                RET


  ; Impressão do tempo      
PrintTime: 		push 	R1
				push 	R2
				push 	R3

				mov 	R1, M[TIME]
				mov 	R2, 60
				div 	R1, R2
				mov 	R3, 10
				div 	R1, R3
				mov 	M[DISP7S4], R1
				mov 	M[DISP7S3], R3
				mov 	R1, 10
				div 	R2, R1
				mov 	M[DISP7S2], R2
				mov 	M[DISP7S1], R1

				pop 	R3
				pop 	R2
				pop 	R1
				ret

	; Operação após um segundo 
AfterSecond: 	cmp 	M[TIME], R0
				br.np 	EndAS 	 	
				
				dec 	M[TIME]
				call 	PrintTime

				call 	StartTimer
                rti

EndAS:			mov 	M[TempControlo], R0
				rti

	; Inicia o temporizador
StartTimer: 	push 	R1

				mov  	R1, DELAYVALUE  ; 1 segundo
                mov  	M[TempValor], R1
                mov  	R1, 0001h   ; Arranca o temporizador
                mov  	M[TempControlo], R1

                pop 	R1
                ret

     ; Inicia a contagem de 2 minutos
StartClock: 	push 	R1

				mov 	R1, 240
				mov 	M[TIME], R1
				call 	StartTimer
				call 	PrintTime

				pop 	R1
				rti

	; Pára o cronometro
StopClock: 		mov 	M[TempControlo], R0
				rti

ContinueClock:  mov 	R1, 1
				mov 	M[TempControlo], R1
				rti

;===============================================================================
;                                Programa prinicipal
;===============================================================================

start:         	mov     R1, SP_INICIAL
                mov     SP, R1

				mov 	R1, AfterSecond
				mov 	M[TAB_INTTemp], R1
				call 	StartTimer

				mov 	R1, StartClock
				mov 	M[TAB_INT0], R1

				mov 	R1, StopClock
				mov 	M[TAB_INT1], R1

				mov 	R1, ContinueClock
				mov 	M[TAB_INT2], R1
				eni

stop: 			Br  	stop				





