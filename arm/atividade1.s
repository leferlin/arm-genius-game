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
	.set VM,           	0x90010
	.set VD,			0x90011
    .set AM,			0x90012
    .set AZ,			0x90013
	.set TIMER,			0x90020
	@.set DISPLAY_DEC,	0x90030
	.set DISPLAY_SEG,	0x90031
	.set LEDS, 			0x90040
@ constantes
	.set INTERVAL,1000

@ define tamanho das pilhas
	.equ TAM_PILHA_FIQ,0x100
	.equ TAM_PILHA_SUP,0x100
	.equ TAM_PILHA_USR,1024


@ vetor de interrupções
	.org  7*4               	@ preenche apenas uma posição do vetor,
	                        	@ correspondente ao tipo 7
	b       tratador_timer

	.text
_start:

	mov		sp, #0x400			@ seta pilha do modo supervisor
	mov		r0, #FIQ_MODE		@ coloca processador no modo FIQ (interrupção externa)
	msr		cpsr, r0			@ processador agora no modo FIQ
	mov		sp, #0x300			@ seta pilha de interrupção FIQ
	mov		r0, #USER_MODE		@ coloca processador no modo usuário
	bic 	r0, r0, #FIQ  	    @ interrupções IRQ habilitadas
	msr		cpsr, r0			@ processador agora no modo usuário
	mov		sp, #0x40000		@ pilha do usuário no final da memória

	@ inicializa random
	ldr     r0,=init        	@ carrega primeiro parâmetro
	mov     r1,#2           	@ carrega segundo parâmetro
	bl      init_by_array   	@ inicializa

	mov 	r0, #0				@ valor display

	push	{r0-r3,lr}			@ guarda valores dos registradores na pilha
	bl 		display				@ mostra valor inicial
	pop 	{r0-r3,lr}			@ restaura valores dos registradores
	ldr		r3, =INTERVAL
	ldr		r6, =TIMER
	str  	r3, [r6]			@ seta timer

loop:
	ldr		r3, =flag
	ldr		r2, [r3]
	cmp		r2, #0
	beq		loop
	mov		r2, #0				@ reseta flag
	str		r2, [r3]

	@ incrementa contadores
	add		r0, r0, #1			@ incrementa contador decimos
	cmp		r0, #10				@ se completou 10 decimos de segundo
	moveq	r0, #0				@ reinicia a contagem de decimos

	@ (TESTE) mostra tempo no display
	push 	{r0-r3,lr}
	bl 		display
	pop 	{r0-r3,lr}

	push	{r0-r3,lr}			@ guarda valores dos registradores na pilha
	bl 		gera_sequencia		@ mostra valor atual do cronometro
	pop 	{r0-r3,lr}			@ restaura valores dos registradores
	b		loop


@ gera_sequencia
@ procedimento gera sequencia aleatória
@ entrada:	valor do display em r0
@ saida:	nao ha
gera_sequencia:
    push	{r4-r11}			@ guarda valores dos registradores

    push    {lr}          		@ guarda valores dos regs
	bl      genrand_int32		@ chama gerador, resultado em r0
	pop 	{lr}

	push    {r0-r3,lr}          @ guarda valores dos regs
	bl		mostra_botoes		@ chama mostrar_botoes
	pop 	{r0-r3,lr}

	pop 	{r4-r11}			@ restaura regs
	bx		lr					@ retorna


mostra_botoes:
    push	{r4-r11}			@ guarda valores dos registradores

	ldr 	r4, =LEDS
	str 	r0, [r4]			@ acende leds

	pop 	{r4-r11}			@ restaura regs
	bx		lr

@ redefine_timer
@ procedimento define/redefine o timer do sistema
@ entrada:	intervalo do timer em r0
@ saida:	nao ha
redefine_timer:
	push	{r4-r11}			@ guarda valores dos registradores

	ldr 	r4, =TIMER
	str 	r0, [r4]			@ seta timer

	pop 	{r4-r11}			@ restaura regs
	bx		lr

@ TESTE
@ display
@ procedimento escreve os digitos nos displays de 7 segmentos
@ entrada:	decimos de segundo em r0
@			segundos em r1
@ saida:	nao ha
display:
	push	{r4-r11}			@ guarda valores dos registradores
	@ldr		r2,=DISPLAY_DEC		@ r2 tem porta display
	ldr 	r4,=DISPLAY_SEG
	ldr		r5,=digitos
	ldrb	r6,[r5,r0]			@ padrao de bits para valor dos segundos
	@orr 	r5,#0x80			@ Liga ponto
	strb  	r6,[r4]				@ seta valor dos segundos no display
	@ldrb	r5,[r4,r0]			@ padrao de bits para valor dos decimos
	@strb  	r5,[r2]				@ seta valor dos decimos no display
	pop 	{r4-r11}			@ restaura regs
	bx		lr					@ retorna


@ tratador da interrupcao
@ aqui quando timer expirou
	.align 4
tratador_timer:
	ldr	r7,=flag				@ apenas liga a flag
	mov	r8,#1
	str	r8,[r7]
	movs	pc,lr				@ e retorna

@ Dados
	.data
flag:
	.word 0
digitos:
	.byte 0x7e,0x30,0x6d,0x79,0x33,0x5b,0x5f,0x70,0x7f,0x7b
init:
	.long 0x123
	.long 0x234
	.long 0x345
	.long 0x456






@ end
