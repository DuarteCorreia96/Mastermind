;===============================================================================
; Programa mastermind.as
;
; Descricao: Jogo Mastermind
;
; Autor: 	Duarte Correia
;			João Guterres
;
; Data: 30/04/2017 				Ultima Alteracao:09/05/2017 
;===============================================================================

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
TAB_INT3        EQU     FE03h   
TAB_INT4        EQU     FE04h
TAB_INT5        EQU     FE05h   
TAB_INT6        EQU     FE06h
TAB_INT7        EQU     FE07h
TAB_INT8        EQU     FE08h
TAB_INT9        EQU     FE09h

TAB_INTA        EQU     FE0Ah 
TAB_INTB        EQU     FE0Bh  
TAB_INTC        EQU     FE0Ch
TAB_INTD        EQU     FE0Dh
TAB_INTE        EQU     FE0Eh

TAB_INTTemp     EQU     FE0Fh

MASCARA_INT		EQU		FFFAh


; TEMPORIZADOR
TempValor     	EQU    	FFF6h ;Permite arrancar (colocando o bit menos significativo a 1) ou parar (colocando o bit menos significativo a 0) o temporizador
TempControlo  	EQU    	FFF7h ;Permite indicar o número de intrevalos de 100ms ao fim do qual o temporizador gerará uma interrupção
Int15_mask    	EQU    	8000h

; I/O a partir de FF00H
DISP7S1         EQU     FFF0h
DISP7S2         EQU     FFF1h
DISP7S3         EQU     FFF2h
DISP7S4         EQU     FFF3h
LCD_WRITE		EQU		FFF5h
LCD_CURSOR		EQU		FFF4h	
LEDS            EQU     FFF8h
INTERRUPTORES   EQU     FFF9h
IO_CURSOR       EQU     FFFCh
IO_WRITE        EQU     FFFEh

LIMPAR_JANELA   EQU     FFFFh

; Posições Iniciais para print
XY_INICIAL      EQU     0205h
XY_CODE			EQU		0102h
XY_CODES		EQU 	0108h
XY_JOGADA		EQU		0002h
XY_TEMP  		EQU  	000Fh

XY_INTRO        EQU     0922h
XY_MENUINFO     EQU     0202h
XY_MENUSTART    EQU     0227h

; Valor para o pseudo-aleatório
MASCARA			EQU		1001110000010110b
BIT0			EQU 	0001h 

; Valor para mudar de linha 
NLINHA			EQU		0100h
NLINHA4         EQU     0400h

; ASCII chars
FIM_TEXTO       EQU     0
INI				EQU		45		; '-'

; Constantes de definição do Jogo
JOGADA_SIZE		EQU		4		; Tamanho do Código (substituida por SIZEC)
JOGADA_TOTAL	EQU		10		; Número de Jogadas máximo (max 22, default 10)
COLORS 			EQU 	6		; Numero de cores
MAX_PLAYERS 	EQU 	3 		; Número máximo de jogadores

; Posições de memória reservadas
NALEA           EQU     D000h   ; Numero aleatório 
NALEA_SET		EQU 	D001h 	; Dá set no número aleatório a diferente de 0
JCOUNTER        EQU     D002h   ; Counter da Jogada (em que subn vai a jogada a ser escolhida)
TIMEC           EQU     D003h   ; Tempo escolhido
TIME            EQU     D004h   ; Timer
SIZEC           EQU     D005h   ; Tamanho da chave        
DISABLE_PLAY 	EQU 	D006h   ; Enable or disable play
MENU 			EQU 	D007h   ; On menu and not on menu
PLAYC           EQU     D008h   ; Numero de jogadares

; Posições de memória para jogadas 
JOGADA_INI		EQU		C000h

;===============================================================================
; ZONA II: Definicao de variaveis
;          Pseudo-instrucoes : WORD - palavra (16 bits)
;                              STR  - sequencia de caracteres.
;          Cada caracter ocupa 1 palavra
;===============================================================================

                ORIG    8000h
VarTextoCode    STR     'CODE:', FIM_TEXTO
VarTextoJoga	STR		'Jogada: ', FIM_TEXTO
VarTextoConfirm	STR		'Confirmar?', FIM_TEXTO
VarTextoCClean	STR		'          ', FIM_TEXTO
VarTextoVitoria	STR		'Win!', FIM_TEXTO

VarTextoIntro1  STR     'MASTERMIND', FIM_TEXTO
VarTextoIntro2  STR     '*** ACOMP ***', FIM_TEXTO

TextoMenuInfo   STR     'Info:', FIM_TEXTO
TextoMenuSele   STR     'Select', FIM_TEXTO
TextoMenuTime   STR     'time:', FIM_TEXTO
TextoTimeopc    STR     '1   2   4', FIM_TEXTO

TextoMenuSize   STR     'key size:', FIM_TEXTO
TextoSizeopc    STR     '4   5   6', FIM_TEXTO

TextoMenuPlay   STR     'players:', FIM_TEXTO 
TextoPlayopc    STR     '1   2   3', FIM_TEXTO

TextoCheckBox   STR     '[ ]', FIM_TEXTO

TextoStatsPlay 	STR 	'Jogador:', FIM_TEXTO

;===============================================================================
; ZONA III: Codigo
;           conjunto de instrucoes Assembly, ordenadas de forma a realizar
;           as funcoes pretendidas
;===============================================================================

                ORIG    0000h
                JMP     inicio

;===============================================================================
; LimpaJanela: Rotina que limpa a janela de texto.
;               Entradas: --
;               Saidas: ---
;               Efeitos: ---
;===============================================================================

LimpaJanela:    PUSH R2
                MOV  R2, LIMPAR_JANELA
				MOV  M[IO_CURSOR], R2
                POP  R2
                RET

;===============================================================================
; EscString: Rotina que efectua a escrita de uma cadeia de caracter, terminada
;            pelo caracter FIM_TEXTO, na janela de texto numa posicao 
;            especificada. Pode-se definir como terminador qualquer caracter 
;            ASCII. 
;               Entradas: pilha - posicao para escrita do primeiro carater 
;                         pilha - apontador para o inicio da "string"
;               Saidas: ---
;               Efeitos: ---
;===============================================================================

EscString: 		push 	R1
				push 	R2
				push 	R3

				mov     R2, M[SP+6]   ; Apontador para inicio da "string"
                mov     R3, M[SP+5]   ; Localizacao do primeiro carater
Ciclo:          mov     M[IO_CURSOR], R3
                mov     R1, M[R2]
                cmp     R1, FIM_TEXTO
                br.z    FimEsc
                call    EscCar
                inc     R2
                inc     R3
                br      Ciclo

FimEsc:         pop 	R3
                pop 	R2
                pop 	R1
		        retn    2   ; Actualiza STACK


;===============================================================================
; EscCar: Rotina que efectua a escrita de um caracter para o ecran.
;         O caracter pode ser visualizado na janela de texto.
;               Entradas: R1 - Caracter a escrever
;               Saidas: ---
;               Efeitos: alteracao da posicao de memoria M[IO]
;===============================================================================

EscCar:         MOV     M[IO_WRITE], R1
                RET       

;===============================================================================
; IniciaJogadas: Inicia ou faz reset das jogadas para escrita posterior no
;					na janela de texto
;               Entradas: --- 														
;               Saidas: ---
;               Efeitos: Inicia as posições para as jogadas a '-' e jogada a '1'
;===============================================================================

IniciaJogadas:	push 	R1
				push 	R2
				push 	R3

				mov 	R1,	1
				mov 	R2, JOGADA_INI		
				mov 	M[R2], R1
				call 	ResetJogada

				pop 	R3
				pop 	R2
				pop 	R1
				ret	

	; Subrotinas do IniciaJogadas 

ResetJogada: 	mov 	R1, INI
				mov 	R2, JOGADA_INI
				mov 	R3, M[SIZEC]	
				inc 	R2	
IniciaChar:		mov 	M[R2],  R1
				inc 	R2
				dec 	R3
				cmp 	R3, R0
				br.nz	IniciaChar	

;===============================================================================
; PrintTabuleiro: Faz print do tabuleiro do jogo na janela de texto
;               Entradas: ---
;               Saidas: --- 														
;               Efeitos: Imprime o tabuleiro inteiro
;===============================================================================

PrintTabuleiro:	push 	R1
				push 	R2
				push 	R3
				push 	R4
				push 	R5

				push    VarTextoJoga
				push 	XY_JOGADA         
PrintTextoJoga: call    EscString
                call 	PrintN
                push 	VarTextoCode
                push 	XY_CODE
PrintTextoCode: call 	EscString
				mov 	R1, 49
				mov 	R2, XY_INICIAL	
				mov	 	R4, JOGADA_TOTAL
				mov 	R5, 48

				; Verifica se é maior que 10
PrintJ:			cmp 	R1, 58
				br.z  	IncDezena 
				cmp 	R5, 48
				br.nz 	PrintDeze
				
				; Impressão normal para valores inferiores a 10
Continue:		mov 	R3, R2
				mov 	M[IO_CURSOR], R3
				mov 	M[IO_WRITE] , R1
				call 	PrintConst

				; Prepara nova linha e verifica se já foram impressas todas
				inc 	R1
				add 	R2, NLINHA
				dec 	R4
				cmp 	R4, R0
				br.nz 	PrintJ 

				pop 	R5
				pop 	R4
				pop 	R3
				pop 	R2
				pop 	R1
				ret 				

	; subrotinas do PrintTabuleiro
					
				; Aumenta dezenas e faz reset a algarismo menos significativo
IncDezena:		inc 	R5
				mov 	R1, 48

				; Imprime algarismo das dezenas
PrintDeze:		mov 	R3, R2
				dec 	R3
				mov     M[IO_CURSOR], R3
				mov 	M[IO_WRITE], R5
				br 		Continue	

				; Faz impressão dos caracteres constantes do tabuleiro
PrintConst: 	push 	R1
				push 	R2

				mov 	R1, ':'
				mov 	R2, '|'
				inc 	R3
				mov 	M[IO_CURSOR], R3
				mov 	M[IO_WRITE] , R1
				add 	R3, 2
				add 	R3, M[SIZEC]
				add 	R3, M[SIZEC]
				mov 	M[IO_CURSOR], R3
				mov 	M[IO_WRITE] , R2

				pop 	R2
				pop 	R1
				ret 				

;===============================================================================
; PrintN: Faz print do numero de jogada atual no tabuleiro de jogo
;			 até 99 depois dá reset
;               Entradas: ---
;               Saidas: ---
;               Efeitos: Actualiza o número da jogada na janela de texto
;===============================================================================

PrintN:   		push 	R1
				push 	R2
				push 	R3

BPrintN:		mov 	R1, R0
				mov 	R2, 000Ah
            	mov 	R3, M[JOGADA_INI]
TesteN:        	cmp 	R3, 10
	   	    	br.n 	ContinueN
	   	    	inc 	R1
            	sub 	R3, 10
            	br 		TesteN
ContinueN:     	cmp		R1, R0
				br.z   	EndN
				cmp 	R1, 9
				br.p	ResetN
				add 	R1, 48
				mov 	M[IO_CURSOR], R2
				mov 	M[IO_WRITE], R1
				inc 	R2
EndN:			add 	R3, 48
                mov 	M[IO_CURSOR], R2
				mov 	M[IO_WRITE],  R3

				pop 	R3
				pop 	R2
				pop 	R1
				ret

	; subrotina para reset após 99
	
ResetN:			mov 	R1, 1
				mov 	M[JOGADA_INI], R1
				mov 	R2, 000Bh
				mov 	M[IO_CURSOR], R2
				mov 	M[IO_WRITE], R0
				jmp 	BPrintN			

;===============================================================================
; IncN: Incrementa o numero da jogada
;               Entradas: ---
;               Saidas: ---
;               Efeitos: Incrementa o valor da jogada para a jogada seguinte
;===============================================================================

IncN:			push 	R1

				mov 	R1, M[JOGADA_INI]
				inc 	R1
				mov 	M[JOGADA_INI], R1

				pop 	R1
				ret			

;===============================================================================
; SetCursor: Retorna o cursor na linha da jogada atual
;               Entradas: ---
;               Saidas:  R2 na posição a imprimir a jogada 														
;               Efeitos: Põe o cursor no lugar inicial de impressão
;===============================================================================

SetCursor:		push	R1
				push 	R3

				mov 	R1, JOGADA_INI
				mov 	R2, XY_INICIAL
				mov		R3, M[JOGADA_INI]
ContinueSetC:	cmp 	R3, 1
				br.z 	EndSetC
				add 	R2, NLINHA
				dec 	R3
				br	 	ContinueSetC

EndSetC:		add 	R2, 3
				
				pop 	R3
				pop 	R1 
				ret

;===============================================================================
; Print jogada: Faz print do tabuleiro do jogo na janela de texto
;               Entradas: --- 														
;               Saidas: ---
;               Efeitos: Imprime a jogada selecionada por R1 na posição R2
;===============================================================================

PrintJogada:	push 	R1
				push 	R2
				push 	R3
				push 	R4
				push 	R5

				call 	SetCursor
				mov  	R1, JOGADA_INI
				inc 	R1
				mov 	R4, M[SIZEC]
				mov 	R5, 2
 
CicloPJ:		mov 	R3, M[R1]
				mov 	M[IO_CURSOR], R2
				mov 	M[IO_WRITE],  R3
				inc 	R1
				add 	R2, 2 
				dec  	R4
				cmp 	R4, R0 
				br.nz	CicloPJ

				add 	R2, 2
				mov 	R4, M[SIZEC]
				dec  	R5
				cmp 	R5, R0 
				br.nz	CicloPJ				

				pop 	R5
				pop 	R4
				pop 	R3
				pop 	R2
				pop 	R1
				ret 

;===============================================================================
; GeraCode: Gera Code e guarda-o na memória
;               Entradas: ---
;               Saidas: ---
;               Efeitos: ---
;===============================================================================

GeraCode: 		push 	R1
				push 	R2
				push 	R3
				push 	R4
				push 	R5

				mov 	R4, M[SIZEC]
				mov 	R5, JOGADA_INI

NovoCode:		mov 	R1, COLORS	
				mov 	R2, M[NALEA] 
				mov 	R3, R2
 				and 	R3, BIT0
 				cmp 	R3, R0
 				br.z 	Igual
 				xor 	R2, MASCARA
Igual:			ror 	R2, 1
				mov 	M[NALEA], R2
				div 	R2, R1
				add 	R1, 49
				dec 	R5
				mov 	M[R5], R1
				dec 	R4
				cmp 	R4, R0
				br.nz 	NovoCode

				pop 	R5
				pop 	R4
				pop 	R3
				pop 	R2
				pop 	R1
				ret

;===============================================================================
; Print Code: Faz print do code do jogo na janela de texto
;               Entradas: ---
;               Saidas: ---
;               Efeitos: Imprime a jogada selecionada por R1 na posição R2
;===============================================================================

PrintCode:		push 	R1
				push 	R2
				push 	R3
				push  	R4

				cmp 	M[MENU], R0
                br.nz 	MenuPC

				mov 	R1, JOGADA_INI
				mov 	R2, XY_CODES 
				mov 	R4, M[SIZEC]
 
CicloPrinC:		dec 	R1
				mov 	R3, M[R1]
				mov 	M[IO_CURSOR], R2
				mov 	M[IO_WRITE],  R3
				add 	R2, 2 
				dec 	R4
				cmp 	R4, R0
				br.nz	CicloPrinC

MenuPC:			pop 	R4
				pop 	R3
				pop 	R2
				pop 	R1				
				ret

;===============================================================================
; ConfirmaJogada: Incrementa a jogada e escreve na janela de texto
;               Entradas: ---
;               Saidas: --- 														
;               Efeitos: ---
;===============================================================================

ConfirmaJogada: push 	R1

				cmp 	M[MENU], R0
                jmp.nz 	MenuCJ

				call 	StopClock

				; Confirma o tamanho da jogada
				mov 	R1, M[JCOUNTER]
				cmp 	R1, M[SIZEC]
				jmp.n   EndCJ

				; Confirma se abaixo do tempo  
				cmp 	M[TIME], R0
				call.np DisablePlay 

				cmp 	M[DISABLE_PLAY], R0
				br.z    EndCJ 

				; Faz avaliação da Jogada
				call 	AvaliaJogada

				; Imprime Jogada atual
				call 	PrintJogada

				cmp 	M[DISABLE_PLAY], R0
				br.z    EndCJ 

				; Passa para a próxima jogada 			
				call	IncN
				mov 	R1, M[JOGADA_INI]
				cmp 	R1, JOGADA_TOTAL
				call.p	PrintN 

				; Faz reset para a próxima jogada
EndCJ:			mov 	M[JCOUNTER], R0
				call 	ResetJogada
				call 	CleanConfirm
				call 	PrintJogaTemp

				; Confirma se abaixo da jogada total
				mov 	R1, M[JOGADA_INI]
				dec 	R1
				cmp 	R1, JOGADA_TOTAL
				call.z	DisablePlay 

MenuCJ:			pop 	R1
				rti

	; Subrotina do ConfirmaJogada 

CleanConfirm: 	push 	R1
				push 	R2

				mov 	R2, XY_TEMP
				mov 	R1, M[SIZEC]
				shla 	R1, 1
				add 	R2, R1
				add 	R2, 4
				push    VarTextoCClean
				push 	R2
				call 	EscString

				pop 	R2
				pop 	R1 
				ret 

DisablePlay: 	mov 	M[DISABLE_PLAY], R0
				call 	PrintCode
				ret

EnablePlay: 	push 	R1
				mov 	R1, 1
				mov 	M[DISABLE_PLAY], R1
				pop 	R1
				ret

;===============================================================================
; FazJogadax: Botões de seleção da chave
;               Entradas: ---
;               Saidas: ---
;               Efeitos: ---
;===============================================================================

FazJogada1:	  	push 	R1
				mov 	R1, '1'
				call 	SaveJogada
				pop 	R1		 
				rti		

FazJogada2:	  	push 	R1
				mov 	R1, '2'
				call 	SaveJogada	
				pop 	R1		 
				rti		

FazJogada3:	  	push 	R1
				mov 	R1, '3'
				call 	SaveJogada
				pop 	R1			 
				rti		

FazJogada4:	  	push 	R1
				mov 	R1, '4'
				call 	SaveJogada
				pop 	R1			 
				rti		

FazJogada5:	  	push 	R1
				mov 	R1, '5'
			 	call 	SaveJogada
			 	pop 	R1
				rti

FazJogada6:	  	push 	R1
				mov 	R1, '6'
				call 	SaveJogada	
				pop 	R1		 
				rti		


		; Subrotinas dos FazJogadax
SaveJogada:		push   	R1
				push 	R2
				push 	R3

				cmp 	M[MENU], R0
                br.nz 	MenuSJ

				mov 	R2, JOGADA_INI
				inc 	M[JCOUNTER]
				mov 	R3, M[JCOUNTER]
CheckSize:		cmp 	R3, M[SIZEC]
				br.np 	ContinueSJ 
				sub 	R3, M[SIZEC]
				br 		CheckSize 	 
ContinueSJ:		add 	R2, R3
				mov 	M[R2], R1
				call	PrintJogaTemp

MenuSJ:			pop 	R3
				pop 	R2
				pop 	R1
				ret

;===============================================================================
; PrintJogadaTemp: Faz print da jogada temporaria na janela de texto
;               Entradas: ---
;               Saidas: ---
;               Efeitos: ---
;===============================================================================

PrintJogaTemp:	push 	R1
				push 	R2
				push 	R3 
				push 	R4
				push 	R5
				push 	R6

				mov   	R2, XY_TEMP
				mov 	R3, M[SIZEC]

				mov 	R4, JOGADA_INI 
CicloPJT:		inc 	R4
				mov  	R1, M[R4]
				mov	 	M[IO_CURSOR], R2
				mov  	M[IO_WRITE],  R1
				add  	R2, 2

				dec 	R3
				cmp 	R3, R0 
				br.nz	CicloPJT

				mov 	R5, M[SIZEC]
				dec 	R5
				mov 	R6, M[JCOUNTER]
				cmp 	R6, R5
				br.np   EndPJT
				add 	R2, 4
				push    VarTextoConfirm
				push 	R2
				call 	EscString

EndPJT:			pop 	R6
				pop 	R5
				pop 	R4
				pop 	R3
				pop 	R2
				pop 	R1
				ret 

;===============================================================================
; AvaliaJogada: Avalia a jogada com o código
;               Entradas: ---
;               Saidas: ---
;               Efeitos: ---
;===============================================================================							

AvaliaJogada: 	push 	R1
				push 	R2
				push 	R3
				push 	R4
				push 	R5
				push 	R6
				push 	R7

				call 	CopyCode
				; Posições 	R1-> Jogada
				;			R2-> Código para verificar
				;			R3-> Counter da avaliação
				mov 	R1, JOGADA_INI
				mov 	R2, JOGADA_INI		
				sub 	R2, M[SIZEC]
				mov 	R3, JOGADA_INI 	
				add  	R3, M[SIZEC]

				; Counter do ciclo Exterior
				mov 	R4, M[SIZEC] 

				; Counter de P's
				mov 	R5, R0

	; Set Pretos
CicloPreto:		inc 	R1
				dec  	R2

				; If (M[R1] != M[R2]) <=> If(Jogada[i] != Chave[j])
				mov 	R6, M[R1]
				cmp 	R6, M[R2]
				call.z 	SetPreto

				dec 	R4
				cmp 	R4, R0
				br.nz 	CicloPreto

	; Verifica condição de vitória
Vitoria:		mov 	R1, M[SIZEC]
				cmp 	R5, R1
				br.nz  	NotVictory

				call 	SetCursor
				mov 	R4, M[SIZEC]
				shla 	R4, 2
				add 	R2, R4
				add 	R2, 0004h

				push    VarTextoVitoria	
				push 	R2
				call 	EscString
				call 	DisablePlay
				call 	CalculateStats
				jmp 	EndAvalia
			
	; Set Brancos
NotVictory:		mov 	R1, JOGADA_INI
				mov 	R4, M[SIZEC] 

CicloBrancoExt:	inc 	R1				
				
 				; Saltar já verificado
 				mov 	R6, R1
 				add 	R6, M[SIZEC]
 				add 	R6, M[SIZEC]
 				cmp 	M[R6], R0
 				br.z   	ContinueCicBE

				; Posição do código a verificar
				mov 	R2, JOGADA_INI		
				sub 	R2, M[SIZEC]

				; Counter do Ciclo Interior
				mov 	R5, M[SIZEC]

CicloBrancoInt: dec 	R2
				
				; If (M[R1] != M[R2]) <=> If(Jogada[i] != Chave[j])
				mov 	R6, M[R1]
				cmp 	R6, M[R2]
				jmp.z 	SetBranco

				dec 	R5
				cmp 	R5, R0
				br.p  	CicloBrancoInt

ContinueCicBE:	dec 	R4
				cmp 	R4, R0
				br.nz 	CicloBrancoExt

				call 	ContinueClock
EndAvalia:		pop 	R7
				pop 	R6
				pop 	R5
				pop 	R4
				pop 	R3
				pop 	R2
				pop 	R1
				ret	

	; Subrotina do AvaliaJogada

		; Set Branco e Preto

SetPreto: 		inc 	R3 			; Incrementa Counter
				inc 	R5 			; Incrementa Counter de Pretos
				mov		R6, 'P'
				mov 	M[R3], R6 	; Imprime 'P'
				mov 	R6, INI 	; Elimina do codecheck
				mov 	M[R2], R6
				call 	Setvisitado
				ret

SetBranco:		inc 	R3
				mov		R6, 'B'
				mov 	M[R3], R6
				mov 	R6, INI
				mov 	M[R2], R6
				call 	Setvisitado
				jmp 	ContinueCicBE			

Setvisitado: 	mov 	R6, R1
				add 	R6, M[SIZEC]
				add 	R6, M[SIZEC]
				mov 	M[R6], R0
				ret

		; Copia o código para o sítio de teste e inicia avaliação
CopyCode:		mov 	R1, JOGADA_INI

				; Counter
				mov 	R4, M[SIZEC]

				; Lugares do código Check
				mov 	R2, JOGADA_INI				
				sub 	R2, M[SIZEC]

				; Lugares de Check
				mov 	R3, JOGADA_INI				
				add 	R3, M[SIZEC]

				; Lugares já visitados
				mov 	R5, R3
				add 	R5, M[SIZEC]	

				mov 	R6, INI

CicloCC:		dec 	R1 	
				dec 	R2
				inc 	R3
				inc 	R5

				mov 	R7, M[R1]
				mov 	M[R2], R7 
				mov 	M[R3], R6
				mov 	M[R5], R6

				dec 	R4
				cmp 	R4, R0
				br.nz  	CicloCC
				ret	

;===============================================================================
; NovoJogo: Faz reset da janela de jogo e inicia novo jogo
;               Entradas: ---
;               Saidas: ---
;               Efeitos: ---
;===============================================================================							

NovoJogo: 		inc 	M[NALEA_SET]
				mov 	M[JCOUNTER], R0
				mov 	M[MENU], R0
				call 	LimpaJanela
				call 	IniciaJogadas
				call 	PrintTabuleiro
				call 	PrintJogaTemp
				call 	GeraCode
				call 	EnablePlay
				call 	StartClock
				rti

NoneRTI:		rti

GiveUp: 		call 	StopClock
				call 	DisablePlay
				rti

;===============================================================================
; PrintTimer: Imprime o tempo no LCD
;               Entradas: ---
;               Saidas: ---
;               Efeitos: ---
;===============================================================================

PrintTimer: 	push 	R1
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

;===============================================================================
; AfterSecond: 	Operação  realizada após o cronómetro
;               Entradas: ---
;               Saidas: ---
;               Efeitos: ---
;===============================================================================

	; Operação após um segundo 
AfterSecond: 	cmp 	M[NALEA_SET], R0
				br.z 	IncAleatorio

				cmp 	M[TIME], R0
				call.z 	DisablePlay
				br.np 	EndAfterS 	 	
				
				dec 	M[TIME]
				call 	PrintTimer
				call 	StartTimer
EndAfterS:		rti

IncAleatorio: 	push 	R7
				inc 	M[NALEA]

				mov  	R7, 0001h  ; 0.1 segundo
                mov  	M[TempValor], R7
                mov  	R7, 0001h   ; Arranca o temporizador
                mov  	M[TempControlo], R7

				pop 	R7
				br 		EndAfterS


	; Inicia o temporizador
StartTimer: 	push 	R7

				mov  	R7, DELAYVALUE  ; 1 segundo
                mov  	M[TempValor], R7
                mov  	R7, 0001h   ; Arranca o temporizador
                mov  	M[TempControlo], R7

                pop 	R7
                ret

;===============================================================================
; Funções de controlo do clock
;               Entradas: ---
;               Saidas: ---
;               Efeitos: ---
;===============================================================================
     
StartClock: 	push 	R7
				mov 	R7, M[TIMEC]
				mov 	M[TIME], R7
				call 	StartTimer
				call 	PrintTimer
				pop 	R7
				ret

StopClock: 		mov 	M[TempControlo], R0
				ret

ContinueClock:  push 	R7
				mov 	R7, 1
				mov 	M[TempControlo], R7
				pop 	R7
				ret
;===============================================================================
; Intro:
;               Entradas: ---
;               Saidas: ---
;               Efeitos: ---
;===============================================================================

Intro:          push    R1
                call    LimpaJanela
                push    VarTextoIntro1
                push    XY_INTRO
                call    EscString

                mov     R1, XY_INTRO
                add     R1, 0200h
                sub     R1, 0002h
                push    VarTextoIntro2
                push    R1
                call    EscString
                pop     R1
                ret 

;===============================================================================
; LaunchMenu:
;               Entradas: ---
;               Saidas: ---
;               Efeitos: ---
;===============================================================================

LaunchMenu:     push    R1
                push    R2

                mov 	M[TIME], R0
                call 	PrintTimer

                mov 	R1, 1
                mov 	M[MENU], R1
                call    LimpaJanela

                push    TextoMenuInfo
                push    XY_MENUINFO
                call    EscString
                
                 ; Print Select Time
                mov     R1, XY_MENUSTART
                mov     R2, R1
                push    TextoMenuSele
                push    R1
                call    EscString
                add     R1, 7
                push    TextoMenuTime
                push    R1
                call    EscString
                add     R2, NLINHA
                add     R2, 1
                push    TextoTimeopc
                push    R2
                call    EscString
                add     R2, NLINHA        
                call    PrintCheckBox
                call    PrintXTimer

                 ; Print Select Size
                mov     R1, XY_MENUSTART
                add     R1, NLINHA4 
                mov     R2, R1              
                push    TextoMenuSele
                push    R1
                call    EscString
                add     R1, 7
                push    TextoMenuSize
                push    R1
                call    EscString
                add     R2, NLINHA
                add     R2, 1
                push    TextoSizeopc
                push    R2
                call    EscString
                add     R2, NLINHA        
                call    PrintCheckBox
                call    PrintXSize

                 ; Print Select Players
                mov     R1, XY_MENUSTART
                add     R1, NLINHA4
                add     R1, NLINHA4
                mov     R2, R1                
                push    TextoMenuSele
                push    R1
                call    EscString
                add     R1, 7
                push    TextoMenuPlay
                push    R1
                call    EscString
                add     R2, NLINHA
                add     R2, 1
                push    TextoPlayopc
                push    R2
                call    EscString
                add     R2, NLINHA        
                call    PrintCheckBox
                call    PrintXPlay
                
                pop     R2
                pop     R1
                rti   

PrintCheckBox:  push    R2
                push    R4
                
                dec     R2
                mov     R4, 3

CicloPCB:       push    TextoCheckBox
                push    R2
                call    EscString
                add     R2, 4        

                dec     R4
                cmp     R4, R0
                br.nz   CicloPCB

                pop     R4
                pop     R2
                ret

;===============================================================================
; SelectTimer:
;               Entradas: ---
;               Saidas: ---
;               Efeitos: ---
;===============================================================================

SelectXTimer:   push    R1
                push    R2

                cmp 	M[MENU], R0
                br.np 	NoMenuSXT

                mov     R1, 60
                cmp     M[TIMEC], R1
                br.z    SetXT120

                mov     R1, 120
                cmp     M[TIMEC], R1
                br.z    SetXT240 

                mov     R1, 60
                mov     M[TIMEC], R1
EndSXT:         mov     R2, XY_MENUSTART
                add     R2, NLINHA        
                add     R2, NLINHA 
                call    ClearOpc
                call    PrintXTimer

NoMenuSXT:      pop     R2
                pop     R1
                rti

SetXT120:       mov     R1, 120
                mov     M[TIMEC], R1
                br      EndSXT

SetXT240:       mov     R1, 240
                mov     M[TIMEC], R1
                br      EndSXT                                       

PrintXTimer:    push    R1
                push    R2

                mov     R1, M[TIMEC]
                mov     R2, XY_MENUSTART
                add     R2, NLINHA        
                add     R2, NLINHA 
                add     R2, 1

                mov     R1, 60
                cmp     M[TIMEC], R1
                br.z    EndPXT

                add     R2, 4

                mov     R1, 240
                cmp     M[TIMEC], R1
                call.z  Add4R2 

EndPXT:         mov     M[IO_CURSOR], R2
                mov     R1, 'x'
                mov     M[IO_WRITE], R1

                pop     R2
                pop     R1
                ret

;===============================================================================
; SelectSize:
;               Entradas: ---
;               Saidas: ---
;               Efeitos: ---
;===============================================================================

SelectXSize:    push    R1
                push    R2

                cmp 	M[MENU], R0
                br.np 	NoMenuSXS

                mov     R1, 4
                cmp     M[SIZEC], R1
                br.z    SetXS5

                mov     R1, 5
                cmp     M[SIZEC], R1
                br.z    SetXS6 

                mov     R1, 4
                mov     M[SIZEC], R1
EndSXS:         mov     R2, XY_MENUSTART
                add     R2, NLINHA4
                add     R2, NLINHA        
                add     R2, NLINHA 
                call    ClearOpc
                call    PrintXSize

NoMenuSXS:      pop     R2
                pop     R1
                rti

SetXS5:         mov     R1, 5
                mov     M[SIZEC], R1
                br      EndSXS

SetXS6:         mov     R1, 6
                mov     M[SIZEC], R1
                br      EndSXS                                       

PrintXSize:     push    R1
                push    R2

                mov     R1, M[SIZEC]
                mov     R2, XY_MENUSTART
                add     R2, NLINHA4
                add     R2, NLINHA        
                add     R2, NLINHA 
                add     R2, 1

                mov     R1, 4
                cmp     M[SIZEC], R1
                br.z    EndPXS

                add     R2, 4

                mov     R1, 6
                cmp     M[SIZEC], R1
                call.z  Add4R2 

EndPXS:         mov     M[IO_CURSOR], R2
                mov     R1, 'x'
                mov     M[IO_WRITE], R1

                pop     R2
                pop     R1
                ret           

;===============================================================================
; SelectPlay:
;               Entradas: ---
;               Saidas: ---
;               Efeitos: ---
;===============================================================================

SelectXPlay:    push    R1
                push    R2

                cmp 	M[MENU], R0
                br.np 	NoMenuSXP

                mov     R1, 1
                cmp     M[PLAYC], R1
                br.z    SetXP2

                mov     R1, 2
                cmp     M[PLAYC], R1
                br.z    SetXP3 

                mov     R1, 1
                mov     M[PLAYC], R1
EndSXP:         mov     R2, XY_MENUSTART
                add     R2, NLINHA4
                add     R2, NLINHA4
                add     R2, NLINHA        
                add     R2, NLINHA 
                call    ClearOpc
                call    PrintXPlay

NoMenuSXP:      pop     R2
                pop     R1
                rti

SetXP2:         mov     R1, 2
                mov     M[PLAYC], R1
                br      EndSXP

SetXP3:         mov     R1, 3
                mov     M[PLAYC], R1
                br      EndSXP                                       

PrintXPlay:     push    R1
                push    R2

                mov     R1, M[PLAYC]
                mov     R2, XY_MENUSTART
                add     R2, NLINHA4
                add     R2, NLINHA4
                add     R2, NLINHA        
                add     R2, NLINHA 
                add     R2, 1

                mov     R1, 1
                cmp     M[PLAYC], R1
                br.z    EndPXP

                add     R2, 4

                mov     R1, 3
                cmp     M[PLAYC], R1
                call.z  Add4R2 

EndPXP:         mov     M[IO_CURSOR], R2
                mov     R1, 'x'
                mov     M[IO_WRITE], R1

                pop     R2
                pop     R1
                ret           

;===============================================================================
; funções auxiliares do menu:
;               Entradas: ---
;               Saidas: ---
;               Efeitos: ---
;===============================================================================

Add4R2:         add     R2, 4
                ret

 ; recebe R2 na linha correta para clear
ClearOpc:       push    R1
                push    R2

                mov     R1, 32
                add     R2, 1
                mov     M[IO_CURSOR], R2
                mov     M[IO_WRITE], R1
                add     R2, 4
                mov     M[IO_CURSOR], R2
                mov     M[IO_WRITE], R1
                add     R2, 4
                mov     M[IO_CURSOR], R2
                mov     M[IO_WRITE], R1

                pop     R2
                pop     R1
                ret    

;===============================================================================
; CalculateStats:
;               Entradas: ---
;               Saidas: ---
;               Efeitos: ---
;===============================================================================
				
				; Organização da memória
				; Média de jogadas guardada como 10x a real
				; [PLAYC][Player actual][JOGOS1][MÈDIAJOG1][MÈDIATEMPO1]...
ResetPLayers: 	mov   	R1, PLAYC
				inc 	R1
				mov 	R2, 1
				mov 	M[R1], R2

				mov 	R4, MAX_PLAYERS
				add 	R4, MAX_PLAYERS
				add 	R4, MAX_PLAYERS

CicloRP:		inc 	R1
				mov 	M[R1], R0

				dec 	R4
				cmp 	R4, R0
				br.nz 	CicloRP
				ret

CalculateStats: push 	R1
				push 	R2
				push 	R3
				push 	R4
				push 	R5
				push 	R6
				push 	R7

				mov 	R1, M[PLAYC]
				
				; Põe R1 no ínicio dos stats do player atual
				inc 	R1
				mov 	R2, M[R1]
				dec 	R2
				mov 	R3, 3
				mul 	R2, R3
				add 	R1, R3

				; Calcula os stats
					; M_(n+1) = M_n * n/(n+1) + x_(n+1)/(n+1)

				mov 	R2, M[R1] 	; número de jogos atual (n)
				mov 	R3, R2
				inc 	R3 			; n+1
				push 	R3
				div 	R2, R3 		; R2 = n/(n+1) (divisão de inteiros -> a desprezar-se o resto)
				pop 	R3			; R3 = n+1
				inc 	M[R1] 		; n  = n+1

				inc 	R1
				call 	CalcPLayStats
				inc 	R1
				call 	CalcTimeStats

				pop 	R7
				pop 	R6
				pop 	R5
				pop 	R4
				pop 	R3
				pop 	R2
				pop 	R1
				ret

	; Calcula média de Jogos (guardada como 10x o real para ter precisão de .1)

CalcPLayStats:	mov 	R6, R2 		; R2 = n/(n+1)
				mov 	R7, R3 		; R7 = n + 1

				mov 	R4, M[JOGADA_INI]
				mov 	R5, 10	
				mul 	R5, R4 		; R4 = x_(n+1) x10
				div 	R4, R6 		; R4 = x_(n+1) / (n+1) (divisão de inteiros -> a desprezar-se o resto)

				mov 	R5, M[R1]   ; R5 = M_n 
				mul 	R6, R5 		; R5 = M_n * n/(n+1)
				add 	R4, R5 		; R4 = M_n * n/(n+1) + x_(n+1) / (n+1)
				mov 	M[R1], R4 	; Save da nova média
				ret

	; Calcula média de Tempo
CalcTimeStats:	mov 	R6, R2 		; R2 = n/(n+1)
				mov 	R7, R3 		; R7 = n + 1

				mov 	R4, M[TIME] ; R4 = x_(n+1)
				div 	R4, R6 		; R4 = x_(n+1) / (n+1) (divisão de inteiros -> a desprezar-se o resto)

				mov 	R5, M[R1]   ; R5 = M_n 
				mul 	R6, R5 		; R5 = M_n * n/(n+1)
				add 	R4, R5 		; R4 = M_n * n/(n+1) + x_(n+1) / (n+1)
				mov 	M[R1], R4 	; Save da nova média
				ret 

PrintStats: 	mov 	R1, M[PLAYC]
				call  	PrintPlay
				ret	

PrintPlay: 		push 	R1
				push 	R2
				push 	R3

				mov     R2, TextoStatsPlay   ; Apontador para inicio da "string"
                mov     R3, R0   			 ; Localizacao do primeiro carater
CicloPP:        mov     M[LCD_CURSOR], R3
                mov     R1, M[R2]
                cmp     R1, FIM_TEXTO
                br.z    FimPP
                mov 	M[LCD_WRITE], R1
                inc     R2
                inc     R3
                br      CicloPP
                inc 	R3
                inc 	R3
                mov 	R1, PLAYC
                inc 	R1
                mov 	R1, M[R1]
                mov     M[LCD_CURSOR], R3
                mov  	M[LCD_WRITE], R1	

FimPP:         	pop 	R3
                pop 	R2
                pop 	R1
		        ret   

;===============================================================================
;                                Programa prinicipal
;===============================================================================

inicio:         mov     R1, SP_INICIAL
                mov     SP, R1		

                ; Rotina do botão 0
                mov     R1, GiveUp
                mov     M[TAB_INT0], R1

                ; Rotina do botão 1
                mov     R1, FazJogada1
                mov     M[TAB_INT1], R1

                ; Rotina do botão 2
                mov     R1, FazJogada2
                mov     M[TAB_INT2], R1

                ; Rotina do botão 3
                mov     R1, FazJogada3
                mov     M[TAB_INT3], R1

                ; Rotina do botão 4
                mov     R1, FazJogada4
                mov     M[TAB_INT4], R1

				 ; Rotina do botão 5
                mov     R1, FazJogada5
                mov     M[TAB_INT5], R1

				; Rotina do botão 6
                mov     R1, FazJogada6
                mov     M[TAB_INT6], R1

               	; Rotina do botão 7
                mov     R1, SelectXTimer
                mov     M[TAB_INT7], R1

                ; Rotina do botão 8
                mov     R1, SelectXSize
                mov     M[TAB_INT8], R1

                ; Rotina do botão 9
                mov     R1, SelectXPlay
                mov     M[TAB_INT9], R1

                ; Rotina do botão A (+)
                mov 	R1, LaunchMenu
                mov 	M[TAB_INTA], R1

                ; Rotina do botão B (.)
                mov 	R1, ConfirmaJogada
                mov 	M[TAB_INTB], R1

                ; Rotina do botão C (-)
                mov 	R1, NovoJogo
                mov 	M[TAB_INTC], R1

                mov 	R1, NoneRTI
                mov 	M[TAB_INTD], R1

                mov 	R1, NoneRTI
                mov 	M[TAB_INTE], R1

                ; Rotina do temporizador
				mov 	R1, AfterSecond
				mov 	M[TAB_INTTemp], R1

				; Enable dos botões
				eni

				; Load Defaul values
				mov 	R1, -1
				mov 	M[MENU], R1

                mov 	R1, 4 
				mov 	M[SIZEC], R1

				mov 	R1, 1
				mov 	M[PLAYC], R1

				mov 	R1, 120
				mov 	M[TIMEC], R1
				mov 	M[TIME], R0

				; Setup do Ni inicial 
                mov 	R1, 565Eh
                mov 	M[NALEA], R1
				mov 	M[NALEA_SET], R0

				call 	StartTimer
				call 	PrintTimer
                call 	LimpaJanela
      			call    Intro

Stop:           br      Stop               