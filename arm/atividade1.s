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
	.set INTERVALO_DISPLAY, 100
	.set INTERVALO_PRIMEIRO_BOTAO, 3000
	.set INTERVALO_DEMAIS_BOTAO, 2000
	.set PRIMEIRO_BIT_MASCARA, 0x01

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
ini:
	@ inicializa random
	ldr     r0,=init        	@ carrega primeiro parâmetro
	mov     r1,#4           	@ carrega segundo parâmetro
	bl      init_by_array   	@ inicializa

	ldr 	r4, =LEDS
	mov 	r0, #0
	str 	r0, [r4]			@ acende leds

	mov 	r0, #0				@ valor display
	push	{r0-r3,lr}			@ guarda valores dos registradores na pilha
	bl 		display				@ mostra valor inicial
	pop 	{r0-r3,lr}			@ restaura valores dos registradores

	@ calcula intervalo botoes
	push 	{r0-r3,lr}
	ldr 	r1, =V
	ldr 	r1, [r1]
	mov 	r0, #6
	sub 	r0, r1
	ldr 	r1, =INTERVALO_DISPLAY
	mul 	r0, r1
	bl	 	redefine_timer		@ seta timer
	pop 	{r0-r3,lr}


loop_display:
	@ testa se ja mostrou todos leds
	ldr 	r7, =n_leds
	ldr 	r8, [r7] 			@ r8 contem numerdo de leds mostrados
	ldr 	r4, =N
	ldr 	r5, [r4]			@ r5 contem N
	cmp 	r8, r5 				@ Se mostrou todos os leds
	beq 	aguarda_primeiro_botao

	ldr		r3, =flag
	ldr		r2, [r3]
	cmp		r2, #0
	beq		loop_display
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
	bl 		mostra_led			@ mostra led aleatorio
	pop 	{r0-r3,lr}			@ restaura valores dos registradores

	ldr 	r7, =n_leds
	ldr 	r8, [r7]
	add 	r8, #1
	str 	r8, [r7]			@ atualiza numero leds mostrados
	b		loop_display


@ aguarda_primeiro_botao
@ aguarda que um botao seja pressiondo
@ em um limite tempo predeterminado
aguarda_primeiro_botao:
	@ redefine timer
	push 	{r0-r3,lr}
	ldr 	r0, =INTERVALO_PRIMEIRO_BOTAO
	bl	 	redefine_timer		@ seta timer com intervalo INTERVALO_PRIMEIRO_BOTAO
	pop 	{r0-r3,lr}
aguarda1:
	@ verifica se o timer expirou (3s)
	ldr		r3, =flag
	ldr		r2, [r3]
	cmp		r2, #0
	movne	r2, #0				@ reseta flag
	strne	r2, [r3]
	@ TESTE
	bne		fim

	@ verifica se um botao foi precionado
	push 	{r0-r3,lr}
	bl 		le_botoes
	mov 	r8, r0				@ botao lido em r8
	pop 	{r0-r3,lr}

	cmp 	r8, #-1				@ Se nao foi pressiondo nenhum botao
	beq		aguarda1			@ aguarda
	ldr 	r5, =seq_digitada	@ caso contrario
	ldr 	r4, [r5]
	lsl 	r4, #2
	orr 	r4, r8 				@ atualiza botoes lidos
	str 	r4, [r5]			@ salva botoes lidos
	mov 	r0, #0x01
	ldr 	r3, =n_botoes		@ r3 contem end n_botoes
	str 	r0, [r3]			@ primeiro botao lido
	b		aguarda_demais_botoes


@ aguarda_demais_botoes
@ aguada que botoes sejam
@ precionados em um tempo de 1 s
aguarda_demais_botoes:
	@ redefine timer
	push 	{r0-r3,lr}
	ldr 	r0, =INTERVALO_DEMAIS_BOTAO
	bl	 	redefine_timer		@ seta timer com intervalo INTERVALO_PRIMEIRO_BOTAO
	pop 	{r0-r3,lr}

aguarda2:
	@ verifica se o timer expirou (1s)
	ldr		r3, =flag
	ldr		r2, [r3]
	cmp		r2, #0
	movne	r2, #0				@ reseta flag
	strne	r2, [r3]
	@ TESTE
	bne		fim

	@ verifica se um botao foi precionado
	push 	{r0-r3,lr}
	bl 		le_botoes
	mov 	r8, r0				@ botao lido em r8
	pop 	{r0-r3,lr}

	cmp 	r8, #-1				@ Se nao foi pressiondo nenhum botao
	beq		aguarda2
	ldr 	r7, =seq_digitada	@ Caso contrario
	ldr 	r6, [r7]
	lsl 	r6, #2
	orr 	r6, r8				@ atualaliza botoes lidos
	str 	r6, [r7]			@ salva botoes lidos
	ldr 	r3, =n_botoes		@ r3 contem end n_botoes
	ldr 	r4, [r3]			@ r4 contem n_botoes
	add 	r4, #1				@ atualiza n_botoes
	str		r4, [r3]
	@ verifica se ja foram pressionados todos
	ldr 	r2, =N
	ldr 	r2, [r2]
	cmp 	r2, r4
	beq 	compara_sequencia
	b		aguarda_demais_botoes


@ compara_sequencia
@ procedimento compara sequecian digitada com sequencia original
@ entrada:	nao ha
@ saida:	nao há
compara_sequencia:
	ldr 	r4, =seq_correta
	ldr 	r4, [r4]
	ldr 	r5, =seq_digitada
	ldr 	r5, [r5]
	cmp 	r4, r5
	beq 	proxima_fase
	@ TESTE
	b 		fim


@ le_botoes
@ procedimento le o proximo botao pressionado
@ entrada:	nao ha
@ saida:	numero do botao em r0
le_botoes:
	push {r4-r11}
	@ botao vermelho
	ldr 	r4, =VM
	ldrb 	r4, [r4]
	cmp 	r4, #0x01
	moveq 	r0, #0
	popeq 	{r4-r11}
	bxeq 		lr
	@ botao verde
	ldr 	r4, =VD
	ldrb 	r4, [r4]
	cmp 	r4, #0x01
	moveq 	r0, #1
	popeq 	{r4-r11}
	bxeq 		lr
	@ botao amarelo
	ldr 	r4, =AM
	ldrb 	r4, [r4]
	cmp 	r4, #0x01
	moveq 	r0, #2
	popeq 	{r4-r11}
	bxeq 		lr
	@ botao azul
	ldr 	r4, =AZ
	ldrb 	r4, [r4]
	cmp 	r4, #0x01
	moveq 	r0, #3
	popeq 	{r4-r11}
	bxeq 		lr
	@ caso default: nenhum botao lido
	mov 	r0, #-1
	pop 	{r4-r11}
	bx 		lr

@ mostra_led
@ procedimento mostra um led aleatorio
@ entrada:	sequencia de botoes em r0
@ saida:	nao ha
mostra_led:
    push	{r4-r11}			@ guarda valores dos registradores

gera_led:
	push	{lr}				@ guarda valores dos registradores na pilha
	bl 		botao_aleatorio		@ escolhe um botao aleatorio, valor em r0
	pop 	{lr}				@ restaura valores dos registradores

	ldr 	r2, =ultimo_led
	ldr 	r3, [r2]
	cmp 	r0, r3 				@ Se o botao for o mesmo exibido na ultima vez
	beq 	gera_led			@ escolhe novo led
								@ Caso contrario
	ldr 	r7, =seq_correta
	ldr 	r6, [r7]
	lsl 	r6, #2
	orr 	r6, r0				@ atualaliza sequencia correta
	str 	r6, [r7]			@ salva sequencia

	ldr 	r4, =LEDS
	str 	r0, [r4]			@ acende leds
	str 	r0, [r2]

	pop 	{r4-r11}			@ restaura regs
	bx		lr

@ botao_aleatorio
@ procedimento gera sequencia aleatória
@ entrada:	nao ha
@ saida:	nao ha
botao_aleatorio:
    push	{r4-r11}			@ oguarda valores dos registradores

    push    {lr}          		@ guarda valores dos regs
	bl      genrand_int32		@ chama gerador, resultado em r0
	pop 	{lr}
	lsr 	r0, #30				@ 2 bits aleatorios (valores no intervalo [0,4])
	ldr 	r1, =PRIMEIRO_BIT_MASCARA
	lsl 	r0, r1, r0			@ r0 contem um unico bit 1

	pop 	{r4-r11}			@ restaura regs
	bx		lr					@ retorna


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
@ entrada:	segundos em r0
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

@ proxima_fase
@ atualiza variaveis F, N
proxima_fase:
	ldr 	r4, =N
	ldr 	r5, [r4] 			@ r5 contem N
	add 	r5, #1 				@ incrementa N
	str 	r5, [r4]
	ldr 	r4, =F
	ldr 	r5, [r4] 			@ r5 contem F
	add 	r5, #1 				@ incremente F
	str 	r5, [r4]
	ldr 	r4, =n_botoes
	mov 	r5, #0x00
	str 	r5, [r4]			@ reinicia numero de botoes
	ldr 	r4, =n_leds
	mov 	r5, #0x00
	str 	r5, [r4]			@ reinicia numero de leds
	ldr 	r4, =seq_correta
	mov 	r5, #0x00
	str 	r5, [r4]			@ reinicia sequencia correta
	ldr 	r4, =seq_digitada
	mov 	r5, #0x00
	str 	r5, [r4]			@ reinicia sequencia digitada
	ldr 	r4, =ultimo_led
	mov 	r5, #0x0F
	str 	r5, [r4]			@ reinicia ultimo led
	b 		ini

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	@ TESTE
fim:
	mov 	r0, #0xF
	ldr 	r4, =LEDS
	str 	r0, [r4]			@ acende leds
	mov 	r0, #10
	bl 		display
espera:
	b espera
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	pop 	{r4-r11}			@ restaura regs
	bx		lr


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
F:
	.word 1
N:
	.word 2
V:
	.word 1
ultimo_led:
	.word 0xF
n_botoes:						@ numero de botoes digitados
	.word 0x00
n_leds:
	.word 0x00					@ numero de leds mostrados
seq_correta:
	.word 0x00
seq_digitada:					@ sequencia digitada
	.word 0x00
digitos:
	.byte 0x7e,0x30,0x6d,0x79,0x33,0x5b,0x5f,0x70,0x7f,0x7b,0x4f,0x4e
init:
	.long 0x123
	.long 0x234
	.long 0x345
	.long 0x456




@ end
