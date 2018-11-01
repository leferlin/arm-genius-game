@ Leandro Ferlin
@ RA 148729
@ MC404
@ Tarefa 06 - Cronometro


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
	.set START_STOP,	0x90010
	.set RESET,			0x90011
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
	mov		sp,#0x400			@ seta pilha do modo supervisor
	mov		r0,#FIQ_MODE		@ coloca processador no modo FIQ (interrupção externa)
	msr		cpsr,r0				@ processador agora no modo FIQ
	mov		sp,#0x300			@ seta pilha de interrupção FIQ
	mov		r0,#USER_MODE		@ coloca processador no modo usuário
	bic 	r0,r0,#FIQ  	    @ interrupções IRQ habilitadas
	msr		cpsr,r0				@ processador agora no modo usuário
	mov		sp,#0x40000			@ pilha do usuário no final da memória

	mov		r0,#0				@ r0 contem contador para decimos de segundo
	mov		r1,#0				@ r1 contem contador para segundos
	push	{r0-r4}				@ guarda valores dos registradores na pilha
	bl 		display				@ mostra valor inicial
	pop 	{r0-r4}				@ restaura valores dos registradores
	ldr		r3,=INTERVAL
	ldr		r6,=TIMER
	str  	r3,[r6]				@ seta timer
	@b 		loop
loop_botao:
	ldr		r3,=RESET
	ldr		r2,[r3]
	cmp		r2,#1
	beq		reset

	ldr		r3,=START_STOP
	ldr		r2,[r3]
	cmp		r2,#0
	beq		botao_zero
	b		botao_um

botao_zero:
	@ testa reset
	ldr		r3,=RESET
	ldr		r2,[r3]
	cmp		r2,#1
	beq		reset

	ldr 	r3,=flag_botao
	ldr		r2,[r3]
	cmp 	r2,#0
	beq		loop_botao
	@ deliga cronometro
	mov		r2,#0
	str 	r2,[r3]				@ atualiza flag_botao
	mov		r3,#0
	ldr		r6,=TIMER
	str  	r3,[r6]				@ seta timer
	b 		loop_botao

botao_um:
	@ testa reset
	ldr		r3,=RESET
	ldr		r2,[r3]
	cmp		r2,#1
	beq		reset

	ldr 	r3,=flag_botao
	ldr		r2,[r3]
	cmp 	r2,#1
	beq		loop
	@ inicia contagem
	mov		r2,#1
	str 	r2,[r3]				@ atualiza flag_botao
	ldr		r3,=INTERVAL
	ldr		r6,=TIMER
	str  	r3,[r6]				@ seta timer
	b 		loop

reset:
	mov		r3,#0
	ldr		r6,=TIMER
	str  	r3,[r6]				@ seta timer
	mov		r0,#0				@ r0 contem contador para decimos de segundo
	mov		r1,#0				@ r1 contem contador para segundos
	push	{r0-r4}				@ guarda valores dos registradores na pilha
	bl 		display				@ mostra valor inicial
	pop 	{r0-r4}				@ restaura valores dos registradores
	b 		loop_botao

loop:
	ldr		r3,=RESET
	ldr		r2,[r3]
	cmp		r2,#1
	beq		reset

	ldr		r3,=START_STOP
	ldr		r2,[r3]
	cmp		r2,#0
	beq		botao_zero

	ldr		r3,=flag
	ldr		r2,[r3]
	cmp		r2,#0
	beq		loop
	mov		r2,#0				@ reseta flag
	str		r2,[r3]

	@ incrementa contadores
	add		r0,r0,#1			@ incrementa contador decimos
	cmp		r0,#10				@ se completou 10 decimos de segundo
	addeq	r1,r1,#1			@ incrementa 1 segundo completo
	moveq	r0,#0				@ reinicia a contagem de decimos
	cmp		r1,#10				@ se completou 10 segundos
	moveq	r0,#0				@ zera contagem
	moveq	r1,#0
	push	{r0-r4}				@ guarda valores dos registradores na pilha
	bl 		display				@ mostra valor atual do cronometro
	pop 	{r0-r4}				@ restaura valores dos registradores
	b		loop

@ display
@ procedimento escreve os digitos nos displays de 7 segmentos
@ entrada:	decimos de segundo em r0
@			segundos em r1
@ saida:	nao ha
display:
	push	{r5-r11}			@ guarda valores dos registradores
	ldr		r2,=DISPLAY_DEC		@ r2 tem porta display
	ldr 	r3,=DISPLAY_SEG
	ldr		r4,=digitos
	ldrb	r5,[r4,r1]			@ padrao de bits para valor dos segundos
	orr 	r5,#0x80			@ Liga ponto
	strb  	r5,[r3]				@ seta valor dos segundos no display
	ldrb	r5,[r4,r0]			@ padrao de bits para valor dos decimos
	strb  	r5,[r2]				@ seta valor dos decimos no display
	pop 	{r5-r11}			@ restaura regs
	bx		lr					@ retorna

flag_botao:
	.word 1
flag:
     .word 0
digitos:
     .byte 0x7e,0x30,0x6d,0x79,0x33,0x5b,0x5f,0x70,0x7f,0x7b

@ tratador da interrupcao
@ aqui quando timer expirou
	.align 4
tratador_timer:
	ldr	r7,=flag				@ apenas liga a flag
	mov	r8,#1
	str	r8,[r7]
	movs	pc,lr				@ e retorna



@ end
