;===============================================================================
; Programa mastermind.as
;
; Descricao: Jogo Mastermind
;
; Autor: 	Duarte Correia
;			João Guterres
;
; Data: 30/04/2017 				Ultima Alteracao:04/05/2017 
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
TAB_INT7        EQU     FE07h
TAB_INT8        EQU     FE08h
TAB_INT9        EQU     FE09h

TAB_INTA        EQU     FE0Ah 
TAB_INTB        EQU     FE0Bh  
TAB_INTC        EQU     FE0Ch
TAB_INTD        EQU     FE0Dh
TAB_INTE        EQU     FE0Eh
TAB_INTF        EQU     FE0Fh

MASCARA_INT	    EQU	FFFAh

; I/O a partir de FF00H
DISP7S1         EQU     FFF0h
DISP7S2         EQU     FFF1h
LCD_WRITE	    EQU	    FFF5h
LCD_CURSOR	    EQU	    FFF4h	
LEDS            EQU     FFF8h
INTERRUPTORES   EQU     FFF9h
IO_CURSOR       EQU     FFFCh
IO_WRITE        EQU     FFFEh

LIMPAR_JANELA   EQU     FFFFh

; Posições Iniciais para print
XY_INTRO        EQU     0922h
XY_MENUINFO     EQU     0202h
XY_MENUSTART    EQU     0227h

; Valor para o pseudo-aleatório
MASCARA	        EQU	1001110000010110b
BIT0	        EQU 	0001h 

; Valor para mudar de linha 
NLINHA	        EQU	0100h
NLINHA4         EQU     0400h

; ASCII chars
FIM_TEXTO       EQU     0
INI		EQU	45		; '-'

; Constantes de definição do Jogo
JOGADA_SIZE	EQU	4		; Tamanho do Código
JOGADA_TOTAL	EQU	10		; Número de Jogadas máximo (max 22, default 10)
COLORS 		EQU 	6		; Numero de cores

; Posições de memória reservadas
NALEA           EQU     D000h   ; Numero aleatório   
JCOUNTER        EQU     D001h   ; Counter da Jogada
TIMEC           EQU     D002h   ; Tempo escolhido
TIMER           EQU     D003h   ; Timer
SIZEC           EQU     D004h   ; Tamanho da chave        
PLAYC           EQU     D005h   ; Numero de jogadares

; Posições de memória para jogadas 
JOGADA_INI      EQU     F000h

;===============================================================================
; ZONA II: Definicao de variaveis
;          Pseudo-instrucoes : WORD - palavra (16 bits)
;                              STR  - sequencia de caracteres.
;          Cada caracter ocupa 1 palavra
;===============================================================================

                ORIG    8000h
VarTextoIntro1  STR     'MASTERMIND', FIM_TEXTO
VarTextoIntro2  STR     '****ACOMP****', FIM_TEXTO

TextoMenuInfo   STR     'Info:', FIM_TEXTO
TextoMenuSele   STR     'Select', FIM_TEXTO
TextoMenuTime   STR     'time:', FIM_TEXTO
TextoTimeopc    STR     '1   2   4', FIM_TEXTO

TextoMenuSize   STR     'key size:', FIM_TEXTO
TextoSizeopc    STR     '4   5   6', FIM_TEXTO

TextoMenuPlay   STR     'players:', FIM_TEXTO 
TextoPlayopc    STR     '1   2   3', FIM_TEXTO

TextoCheckBox   STR     '[ ]', FIM_TEXTO

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

EscString: 	push 	R1
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

                pop     R2
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

                pop     R2
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

                pop     R2
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
; funções auxiliares:
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
;                                Programa prinicipal
;===============================================================================

inicio:         mov     R1, SP_INICIAL
                mov     SP, R1
                
                call    Intro

                mov     R1, LaunchMenu
                mov     M[TAB_INT0], R1

                mov     R1, SelectXTimer
                mov     M[TAB_INT1], R1

                mov     R1, SelectXSize
                mov     M[TAB_INT2], R1

                mov     R1, SelectXPlay
                mov     M[TAB_INT3], R1
                eni 

                mov     R1, 120
                mov     M[TIMEC], R1

                mov     R1, 4
                mov     M[SIZEC], R1

                mov     R1, 1
                mov     M[PLAYC], R1

stop:           br      stop 