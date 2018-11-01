@ Leandro Ferlin    RA 148729
@ MC 404
@ Atividade 1 - Jogo Genius


.global _start

@ modos de interrupção no registrador de status
	.set FIQ_MODE,0x11
	.set USER_MODE,0x10

@ flag para habilitar interrupções externas no registrador de status
	.set FIQ, 0x80

@enderecos dispositivos
	.set DISPLAY_DEC,	0x90030
	.set DISPLAY_SEG,	0x90031
	.set TIMER,			0x90020
	.set VM,           	0x90010
	.set VD,			0x90011
    .set AM,			0x90012
    .set AZ,			0x90013
@ constantes
	.set INTERVAL,100

@ define tamanho das pilhas
	.equ TAM_PILHA_FIQ,0x100
	.equ TAM_PILHA_SUP,0x100
	.equ TAM_PILHA_USR,1024


@ vetor de interrupções
	.org  7*4               	@ preenche apenas uma posição do vetor,
	                        	@ correspondente ao tipo 7
	b       tratador_timer

	.org 0x1000
_start:







gerar_sequencia:
    push	{r5-r11}			@ guarda valores dos registradores

    mov
    push    {r0-r4}             @ guarda valores dos regs


	pop 	{r5-r11}			@ restaura regs
	bx		lr					@ retorna


mostrar_botoes:
    push	{r5-r11}			@ guarda valores dos registradores

	pop 	{r5-r11}			@ restaura regs
	bx		lr




























@ end
