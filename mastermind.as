;===============================================================================
; Programa mastermind.as
;
; Descricao: Jogo Mastermind
;
; Autor: 	Duarte Correia
;			João Guterres
;
; Data: 30/04/2017 				Ultima Alteracao:03/05/2017 
;===============================================================================

;===============================================================================
; ZONA I: Definicao de constantes
;         Pseudo-instrucao : EQU
;===============================================================================

; TEMPORIZACAO
DELAYVALUE      EQU     F000h

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

TAB_INTA        EQU     FE0Ah 
TAB_INTB        EQU     FE0Bh          
MASCARA_INT		EQU		FFFAh

; I/O a partir de FF00H
DISP7S1         EQU     FFF0h
DISP7S2         EQU     FFF1h
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

; Posições de memória para jogadas 
JOGADA_INI		EQU		F000h

; Posição  de memória do pseudo aleatório
NALEA 			EQU 	D000h

; Valor para o pseudo-aleatório
MASCARA			EQU		1001110000010110b
BIT0			EQU 	0001h 

; Valor para mudar de linha 
NLINHA			EQU		0100h

; ASCII chars
FIM_TEXTO       EQU     0
INI				EQU		45		; '-'

; Constantes de definição do Jogo
JOGADA_SIZE		EQU		4		; Tamanho do Código
JOGADA_TOTAL	EQU		15		; Número de Jogadas máximo (max 22, default 10)
COLORS 			EQU 	6		; Numero de cores


;===============================================================================
; ZONA II: Definicao de variaveis
;          Pseudo-instrucoes : WORD - palavra (16 bits)
;                              STR  - sequencia de caracteres.
;          Cada caracter ocupa 1 palavra
;===============================================================================

                ORIG    8000h
VarTextoCode    STR     'CODE:', FIM_TEXTO
VarTextoJoga	STR		'Jogada: ', FIM_TEXTO
VarTextoConfirm	STR		'Confirm?', FIM_TEXTO
VarTextoCClean	STR		'        ', FIM_TEXTO

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

EscString: 		mov     R2, M[SP+3]   ; Apontador para inicio da "string"
                mov     R3, M[SP+2]   ; Localizacao do primeiro carater
Ciclo:          mov     M[IO_CURSOR], R3
                mov     R1, M[R2]
                cmp     R1, FIM_TEXTO
                br.z    FimEsc
                call    EscCar
                inc     R2
                inc     R3
                br      Ciclo
FimEsc:         retn    2   ; Actualiza STACK


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
;               Entradas: --- 														Alterar
;               Saidas: ---
;               Efeitos: Inicia as posições para as jogadas a '-' e jogada a '1'
;===============================================================================

IniciaJogadas:	mov 	R1,	1
				mov 	R2, JOGADA_INI
				mov 	R3, JOGADA_SIZE		
				mov 	M[R2], R1
				call 	ResetJogada
				ret	

ResetJogada: 	mov 	R1, INI
				mov 	R2, JOGADA_INI
				mov 	R3, JOGADA_SIZE	
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

PrintTabuleiro:	push    VarTextoJoga
				push 	XY_JOGADA         
PrintTextoJoga: call    EscString
                call 	PrintN
                push 	VarTextoCode
                push 	XY_CODE
PrintTextoCode: call 	EscString
				mov 	R1, 49
				mov 	R2, XY_INICIAL	
				mov	 	R4, JOGADA_TOTAL
				mov 	R6, 48

				; Verifica se é maior que 10
PrintJ:			cmp 	R1, 58
				br.z  	IncDezena 
				cmp 	R6, 48
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
				ret 				

	; subrotinas do PrintTabuleiro
					
				; Aumenta dezenas e faz reset a algarismo menos significativo
IncDezena:		inc 	R6
				mov 	R1, 48

				; Imprime algarismo das dezenas
PrintDeze:		mov 	R3, R2
				dec 	R3
				mov     M[IO_CURSOR], R3
				mov 	M[IO_WRITE], R6
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
				add 	R3, JOGADA_SIZE
				add 	R3, JOGADA_SIZE
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

PrintN:   		mov 	R1, R0
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
				ret

	; subrotina para reset após 99
	
ResetN:			mov 	R1, 1
				mov 	M[JOGADA_INI], R1
				mov 	R2, 000Bh
				mov 	M[IO_CURSOR], R2
				mov 	M[IO_WRITE], R0
				jmp 	PrintN				

;===============================================================================
; IncN: Incrementa o numero da jogada
;               Entradas: ---
;               Saidas: ---
;               Efeitos: Incrementa o valor da jogada para a jogada seguinte
;===============================================================================

IncN:			mov 	R1, M[JOGADA_INI]
				inc 	R1
				mov 	M[JOGADA_INI], R1
				ret			

;===============================================================================
; GetJogada: Retorna o cursor na linha da jogada atual e na posição de memória
;               Entradas: ---
;               Saidas: 	R1 Posição da memória da jogada atual
;							R2 posição inicial da linha da jogada atual				Alterar
;               Efeitos: Põe no topo do stack posição de memoria 
;							e posição de escrita
;===============================================================================

GetJogada:		mov 	R1, JOGADA_INI
				mov 	R2, XY_INICIAL
				mov		R3, M[JOGADA_INI]
				cmp 	R3, R0
				inc 	R1
				br.z 	EndGetJ
				add 	R2, NLINHA
				add 	R1, JOGADA_SIZE
				dec 	R3
				cmp 	R3, R0
				br.nz 	GetJogada
EndGetJ:		mov 	M[IO_CURSOR], R2 
				push 	R2
				push 	R1
				ret

;===============================================================================
; Print jogada: Faz print do tabuleiro do jogo na janela de texto
;               Entradas:	R1 inicio da jogada 
;							R2 posição inicial da linha 							Alterar/Apagar
;               Saidas: ---
;               Efeitos: Imprime a jogada selecionada por R1 na posição R2
;===============================================================================

PrintJogada:	mov 	R5, R2
				mov 	R6, R1
				add 	R6, JOGADA_SIZE 
CicloPJ:		mov 	R3, M[R1]
				mov 	M[IO_CURSOR], R5
				mov 	M[IO_WRITE],  R3
				inc 	R1
				add 	R5, 2 
				cmp 	R1, R6
				br.nz	CicloPJ
				ret 

;===============================================================================
; GeraCode: Gera Code e guarda-o na memória
;               Entradas: ---
;               Saidas: ---
;               Efeitos: ---
;===============================================================================

GeraCode: 		mov 	R4, JOGADA_SIZE
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
				add 	R1, 48
				dec 	R5
				mov 	M[R5], R1
				dec 	R4
				cmp 	R4, R0
				br.nz 	NovoCode
				rti

;===============================================================================
; Print Code: Faz print do code do jogo na janela de texto
;               Entradas:	R1 inicio da jogada 
;							R2 posição inicial da linha
;               Saidas: ---
;               Efeitos: Imprime a jogada selecionada por R1 na posição R2
;===============================================================================

PrintCode:		mov 	R1, JOGADA_INI
				mov 	R2, XY_CODES 
				mov 	R6, JOGADA_INI
				sub 	R6, JOGADA_SIZE 
CicloPrinC:		mov 	R3, M[R6]
				mov 	M[IO_CURSOR], R2
				mov 	M[IO_WRITE],  R3
				inc 	R6
				add 	R2, 2 
				cmp 	R1, R6
				br.nz	CicloPrinC
				rti

;===============================================================================
; ConfirmaJogada: Incrementa a jogada e escreve na janela de texto
;               Entradas: ---
;               Saidas: ---
;               Efeitos: ---
;===============================================================================

ConfirmaJogada:	call 	IncN 
				call 	PrintN 
				mov 	R7, R0
				call 	ResetJogada
				call 	CleanConfirm
				call 	PrintJogaTemp
				rti

CleanConfirm: 	mov 	R2, XY_TEMP
				mov 	R1, JOGADA_SIZE
				shla 	R1, 1
				add 	R2, R1
				add 	R2, 4
				push    VarTextoCClean
				push 	R2
				call 	EscString 
				ret 

;===============================================================================
; FazJogada: Botões de seleção da chave
;               Entradas: ---
;               Saidas: ---
;               Efeitos: ---
;===============================================================================

FazJogada1:	  	mov 	R1, '1'
				call 	SaveJogada			 
				rti		

FazJogada2:	  	mov 	R1, '2'
				call 	SaveJogada			 
				rti		

FazJogada3:	  	mov 	R1, '3'
				call 	SaveJogada			 
				rti		

FazJogada4:	  	mov 	R1, '4'
				call 	SaveJogada			 
				rti		

FazJogada5:	  	mov 	R1, '5'
			 	call 	SaveJogada
				rti		

FazJogada6:	  	mov 	R1, '6'
				call 	SaveJogada			 
				rti		

SaveJogada:		mov 	R2, JOGADA_INI
				inc 	R7
CheckSize:		cmp 	R7, JOGADA_SIZE
				br.np 	ContinueSJ 
				sub 	R7, JOGADA_SIZE
				br 		CheckSize 	 
ContinueSJ:		add 	R2, R7
				mov 	M[R2], R1
				call	PrintJogaTemp
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

				mov   	R2, XY_TEMP
				mov 	R3, JOGADA_SIZE

				mov 	R4, JOGADA_INI 
CicloPJT:		inc 	R4
				mov  	R1, M[R4]
				mov	 	M[IO_CURSOR], R2
				mov  	M[IO_WRITE],  R1
				add  	R2, 2

				dec 	R3
				cmp 	R3, R0 
				br.nz	CicloPJT

				mov 	R5, JOGADA_SIZE
				dec 	R5
				cmp 	R7, R5
				br.np   EndPJT
				add 	R2, 4
				push    VarTextoConfirm
				push 	R2
				call 	EscString

EndPJT:			pop 	R5
				pop 	R4
				pop 	R3
				pop 	R2
				pop 	R1
				ret 				

;===============================================================================
;                                Programa prinicipal
;===============================================================================

inicio:         mov     R1, SP_INICIAL
                mov     SP, R1
                call 	LimpaJanela
                call 	IniciaJogadas
                call 	PrintTabuleiro

				call  	PrintJogaTemp		

                ; Setup do Ni inicial 
                mov 	R1, 565Eh
                mov 	M[NALEA], R1

                ; Rotina do botão 0
                mov     R1, PrintCode
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

                ; Rotina do botão A (+)
                mov 	R1, GeraCode
                mov 	M[TAB_INTA], R1

                ; Rotina do botão B (.)
                mov 	R1, ConfirmaJogada
                mov 	M[TAB_INTB], R1

				; Enable dos botões
				eni

Stop:           br      Stop               