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
	.set ADISPLAY_DAT,	0x90001
	.set ADISPLAY_CMD,	0x90000
@ constantes
	.set INTERVALO_DISPLAY, 100
	.set INTERVALO_PRIMEIRO_BOTAO, 3000
	.set INTERVALO_DEMAIS_BOTAO, 2000
	.set MASCARA_PRIMEIRO_BIT, 0x01
	.set MASCARA_DOIS_BITS, 0x03
	.set BOTAO_VM, 0x1000
	.set BOTAO_VD, 0x0100
	.set BOTAO_AM, 0x0010
	.set BOTAO_AZ, 0x0001
	.set SEQ_MAX, 3

@ constantes para "commands"
        .set LCD_CLEARDISPLAY,0x01
        .set LCD_RETURNHOME,0x02
        .set LCD_ENTRYMODESET,0x04
        .set LCD_DISPLAYCONTROL,0x08
        .set LCD_CURSORSHIFT,0x10
        .set LCD_FUNCTIONSET,0x20
        .set LCD_SETCGRAMADDR,0x40
        .set LCD_SETDDRAMADDR,0x80
        .set LCD_BUSYFLAG,0x80

@ constantes para "display entry mode"
        .set LCD_ENTRYRIGHT,0x00
        .set LCD_ENTRYLEFT,0x02
        .set LCD_ENTRYSHIFTINCREMENT,0x01
        .set LCD_ENTRYSHIFTDECREMENT,0x00

@ constantes para "display on/off control"
        .set LCD_DISPLAYON,0x04
        .set LCD_DISPLAYOFF,0x00
        .set LCD_CURSORON,0x02
        .set LCD_CURSOROFF,0x00
        .set LCD_BLINKON,0x01
        .set LCD_BLINKOFF,0x00

@ constantes para "display/cursor shift"
        .set LCD_DISPLAYMOVE,0x08
        .set LCD_CURSORMOVE,0x00
        .set LCD_MOVERIGHT,0x04
        .set LCD_MOVELEFT,0x00

@ constantes para "function set"
        .set LCD_8BITMODE,0x10
        .set LCD_4BITMODE,0x00
        .set LCD_2LINE,0x08
        .set LCD_1LINE,0x00
        .set LCD_5x10DOTS,0x04
        .set LCD_5x8DOTS,0x00

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

	@ mensagem de inicio
	push	{r0-r3,lr}			@ guarda valores dos registradores na pilha
	ldr 	r1, =msg_inicio		@ parametro para funcao, endereco da mensagem
	mov 	r3, #0x00 			@ apenas uma linhas
	bl 		escreve_mensagem	@ limpa tela e escreve nova mensagem
	pop 	{r0-r3,lr}			@ restaura valores dos registradores
	@ mostra mensagem por 1 s
	ldr 	r0, =INTERVALO_PRIMEIRO_BOTAO
	bl	 	redefine_timer		@ seta timer com intervalo para 1 s
	pop 	{r0-r3,lr}
aguarda_start:
	ldr 	r7, =flag
	ldr 	r6, [r7]
	cmp 	r6, #0x00
	beq 	aguarda_start
	push 	{r0-r3,lr}
	bl 		limpa_display		@ limpa e reinicia display
	pop 	{r0-r3,lr}
	mov 	r6, #0x00
	str 	r6, [r7]

ini:
	@ inicializa random
	ldr     r0,=init        	@ carrega primeiro parâmetro
	mov     r1,#4           	@ carrega segundo parâmetro
	bl      init_by_array   	@ inicializa

	ldr 	r4, =LEDS
	mov 	r0, #0
	str 	r0, [r4]			@ apaga leds

	@ mostra fase e numero de leds
	ldr 	r1, =fases1
	ldr 	r2, =n4
	mov 	r3, #0x01			@ parametro da funcao, 2 linhas
	push 	{r0-r3,lr}
	bl 		escreve_mensagem
	pop		{r0-r3,lr}
	@ mostra mensagem por 1 s
	push 	{r0-r3,lr}
	ldr 	r0, =INTERVALO_PRIMEIRO_BOTAO
	bl	 	redefine_timer		@ seta timer com intervalo para 1 s
	pop 	{r0-r3,lr}
aguarda_ini:
	ldr 	r7, =flag
	ldr 	r6, [r7]
	cmp 	r6, #0x00
	beq 	aguarda_ini
	push 	{r0-r3,lr}
	bl 		limpa_display		@ limpa e reinicia display
	pop 	{r0-r3,lr}
	mov 	r6, #0x00
	str 	r6, [r7]

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
	bne		erro_tempo

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
	bne		erro_tempo

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
@ compara sequecian digitada com sequencia original
compara_sequencia:
	ldr 	r4, =seq_correta
	ldr 	r4, [r4]
	ldr 	r5, =seq_digitada
	ldr 	r5, [r5]
	cmp 	r4, r5
	beq 	proxima_fase
	@ verifica se atingiu numero maximo de tentativas
	ldr 	r6, =n_seq
	ldr 	r7, [r6]
	mov 	r8, #SEQ_MAX
	cmp 	r7, r8				@ Se a sequencia foi digitada 3 vezes
	beq		erro_seq_max		@ termina
	@ mostra mensagem de erro na sequencia
	push 	{r0-r3,lr}
	bl 		erro_seq
	pop 	{r0-r3,lr}

	ldr 	r6, =n_seq
	ldr 	r7, [r6]
	add 	r7, #1
	str 	r7, [r6]			@ atualiza numero de sequencias e salva
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
	b  		ini

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
	ldr 	r4, =LEDS
	str 	r0, [r4]			@ acende leds
	str 	r0, [r2]

	pop 	{r4-r11}			@ restaura regs
	bx		lr

@ botao_aleatorio
@ procedimento gera sequencia aleatória
@ entrada:	nao ha
@ saida:	mascara para botao aleatorio em r0
botao_aleatorio:
    push	{r4-r11}			@ oguarda valores dos registradores

    push    {lr}          		@ guarda valores dos regs
	bl      genrand_int32		@ chama gerador, resultado em r0
	pop 	{lr}
	mov 	r1, #MASCARA_DOIS_BITS
	and 	r0, r1				@ 2 bits aleatorios (valores no intervalo [0,3])

	@ atualiza sequencia correta
	ldr 	r7, =seq_correta
	ldr 	r6, [r7]
	lsl 	r6, #2
	mov 	r8, #3
	sub 	r8, r0
	orr 	r6, r6, r8			@ atualaliza sequencia correta
	str 	r6, [r7]			@ salva sequencia

	ldr 	r1, =MASCARA_PRIMEIRO_BIT
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
zera_variaveis:
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
	ldr 	r4, =n_seq
	mov 	r5, #0x00
	str 	r5, [r4]			@ reinicia ultimo led
	b 		ini

@ erro de tempo esgotado
erro_tempo:
	@ define mensagem a ser mostrada
	ldr     r1, =msg_erro
	push 	{r0-r3,lr}
	bl      escreve_mensagem 	@ escreve mensagem no display, primeira linha
	pop 	{r0-r3,lr}
	@ mostra mensagem por 1 s
	ldr 	r0, =INTERVALO_PRIMEIRO_BOTAO
	bl	 	redefine_timer		@ seta timer com intervalo para 1 s
	pop 	{r0-r3,lr}
aguarda_tempo:
	ldr 	r7, =flag
	ldr 	r6, [r7]
	cmp 	r6, #0x00
	beq 	aguarda_tempo
	push 	{r0-r3,lr}
	bl 		limpa_display		@ limpa e reinicia display
	pop 	{r0-r3,lr}
	mov 	r6, #0x00
	str 	r6, [r7]

	@ restaura valores de N e F para os valores padroes
	ldr 	r4, =N
	mov 	r5, #4
	str 	r5, [r4]
	ldr 	r4, =F
	mov 	r5, #1
	add 	r5, #1
	str 	r5, [r4]
	b 		zera_variaveis		@ zera variaveis e retorna ao inicio

@ mostra mensagem de erro na sequencia
erro_seq:
	push 	{r4-r11}
	@ define mensagem a ser mostrada
	ldr     r1, =msg_erro_seq
	push 	{r0-r3,lr}
	bl      escreve_mensagem 	@ escreve mensagem no display, primeira linha
	pop 	{r0-r3, lr}
	@ mostra mensagem por 1 s
	push 	{r0-r3,lr}
	ldr 	r0, =INTERVALO_PRIMEIRO_BOTAO
	bl	 	redefine_timer		@ seta timer com intervalo para 1 s
	pop 	{r0-r3,lr}
aguarda:
	ldr 	r7, =flag
	ldr 	r6, [r7]
	cmp 	r6, #0x00
	beq 	aguarda
	push 	{r0-r3,lr}
	bl 		limpa_display		@ limpa e reinicia display
	pop 	{r0-r3,lr}
	mov 	r6, #0x00
	str 	r6, [r7]
	pop 	{r4-r11}
	bx		lr

@ erro do numerdo de sequencias maximo atingido
erro_seq_max:
	@ define mensagem a ser mostrada
	ldr     r1, =msg_erro_max
	push 	{r0-r3,lr}
	bl      escreve_mensagem 	@ escreve mensagem no display, primeira linha
	pop 	{r0-r3,lr}
	@ mostra mensagem por 1 s
	ldr 	r0, =INTERVALO_PRIMEIRO_BOTAO
	bl	 	redefine_timer		@ seta timer com intervalo para 1 s
	pop 	{r0-r3,lr}
aguarda_max:
	ldr 	r7, =flag
	ldr 	r6, [r7]
	cmp 	r6, #0x00
	beq 	aguarda_max
	push 	{r0-r3,lr}
	bl 		limpa_display		@ limpa e reinicia display
	pop 	{r0-r3,lr}
	mov 	r6, #0x00
	str 	r6, [r7]

	@ restaura valores de N e F para os valores padroes
	ldr 	r4, =N
	mov 	r5, #4
	str 	r5, [r4]
	ldr 	r4, =F
	mov 	r5, #1
	add 	r5, #1
	str 	r5, [r4]
	b 		zera_variaveis		@ zera variaveis e retorna ao inicio

@ escreve_mensagem
@ procedimento escreve dado em r0 no display
@ entrada:		endereco da mensagem da primeira linhas em r1
@ 		 		endereco da mensagem da segunda linha em r2
@ 				r3 contem 1 se mensagem tem duas linhas, 0 caso contrario
@ saida:		nao ha
escreve_mensagem:
	push 	{r4-r11}
	@ comando LCD
	mov		r0,#LCD_FUNCTIONSET+LCD_8BITMODE+LCD_2LINE+LCD_5x8DOTS
	                        	@ r0 tem comando
	push 	{r0-r3,lr}
	bl      wr_cmd				@ escreve comando no display
	pop 	{r0-r3,lr}
	mov		r0,#LCD_CLEARDISPLAY
	                        	@ r0 tem comando: clear display
	push 	{r0-r3,lr}
	bl      wr_cmd				@ escreve comando no display
	pop 	{r0-r3,lr}
	mov		r0,#LCD_RETURNHOME
	                        	@ r0 tem comando: cursor home
	push 	{r0-r3,lr}
	bl      wr_cmd				@ escreve comando no display
	pop 	{r0-r3,lr}
	mov		r0,#LCD_DISPLAYCONTROL+LCD_DISPLAYON+LCD_BLINKOFF
	                        	@ r0 tem comando
	push 	{r0-r3,lr}
	bl      wr_cmd				@ escreve comando no display
	pop 	{r0-r3,lr}
	@ escreve primeira linha
	push 	{r0-r3,lr}
	bl      write_msg
	pop 	{r0-r3,lr}

	@ escreve segunda linha
	cmp 	r3, #0x00			@ Se nao ha segunda linha, retorna
	beq 	fim_escreve_mensagem
	mov		r0,#(LCD_SETDDRAMADDR+64)
	                        @ r0 tem comando: endereço inicio da segunda linha
	                        @ para 16x2 e 20x2:
	                        @   primeira linha: 0..39 (0x00..0x27)
	                        @   segunda linha: 64..103 (0x40..0x67)
	                        @ para 20x4:
	                        @   primeira linha: 0..19 (0x00..0x13)
	                        @   segunda linha:64..83 (0x40..0x53)
	                        @   terceira linha: 20..39 (0x14..0x27)
	                        @   quarta linha:  84..103 (0x54..0x67)
	push 	{r0-r3,lr}
	bl      wr_cmd			@ escreve comando no display
	pop 	{r0-r3,lr}
    push 	{r0-r3,lr}
	mov     r1, r2	      	@ escreve mensagem no display, segunda linha
	bl      write_msg
	pop 	{r0-r3,lr}
fim_escreve_mensagem:
	pop 	{r4-r11}
	bx 		lr

@ limpa_display
@ procedimento escreve dado em r0 no display
@ entrada:		nao ha
@ saida: 		nao ha
limpa_display:
	push 	{r4-r11}
	@ comando LCD
	mov		r0,#LCD_FUNCTIONSET+LCD_8BITMODE+LCD_2LINE+LCD_5x8DOTS
	                        	@ r0 tem comando
	push 	{r0-r3,lr}
	bl      wr_cmd				@ escreve comando no display
	pop 	{r0-r3,lr}
	mov		r0,#LCD_CLEARDISPLAY
	                        	@ r0 tem comando: clear display
	push 	{r0-r3,lr}
	bl      wr_cmd				@ escreve comando no display
	pop 	{r0-r3,lr}
	mov		r0,#LCD_RETURNHOME
	                        	@ r0 tem comando: cursor home
	push 	{r0-r3,lr}
	bl      wr_cmd				@ escreve comando no display
	pop 	{r0-r3,lr}
	mov		r0,#LCD_DISPLAYCONTROL+LCD_DISPLAYON+LCD_BLINKOFF
	                        	@ r0 tem comando
	push 	{r0-r3,lr}
	bl      wr_cmd				@ escreve comando no display
	pop 	{r0-r3,lr}
	pop 	{r4-r11}
	bx 		lr

@ wr_cmd
@ escreve comando em r0 no display
wr_cmd:
	ldr		r6,=ADISPLAY_CMD 	@ r6 tem porta display
	ldrb	r5,[r6]
	tst     r5,#LCD_BUSYFLAG
	beq		wr_cmd           	@ espera BF ser 1
	strb	r0,[r6]
	mov		pc,lr

@ wr_dat
@ escreve dado em r0 no display
wr_dat:
	ldr		r6,=ADISPLAY_CMD 	@ r6 tem porta display
	ldrb	r5,[r6]          	@ lê flag BF
	tst     r5,#LCD_BUSYFLAG
	beq		wr_dat           	@ espera BF ser 1
	ldr		r6,=ADISPLAY_DAT 	@ r6 tem porta display
	strb	r0,[r6]
	mov		pc,lr

@ write_msg
@ escreve cadeia de caracteres apontada por r1, terminada com caractere nulo
write_msg:
	push    {lr}
	mov		r4, #0  			@ endereço inicial
write_msg1:
	ldrb    r0,[r1,r4] 			@ caractere a ser escrito
	teq		r0,#0
	popeq   {pc}       			@ final da cadeia
	bl      wr_dat     			@ escreve caractere
	add     r1,#1      			@ avança contador
	b       write_msg1


@ tratador da interrupcao
@ aqui quando timer expirou
	.align 4
tratador_timer:
	ldr		r7,=flag			@ apenas liga a flag
	mov		r8,#1
	str		r8,[r7]
	movs	pc,lr				@ e retorna

@ Dados
	.data
flag:
	.word 0
F:
	.word 1
N:
	.word 4
V:
	.word 1
ultimo_led:
	.word 0xF
n_botoes:						@ numero de botoes digitados
	.word 0x00
n_leds:
	.word 0x00					@ numero de leds mostrados
n_seq:
	.word 0x00					@ numero de sequencias erradas digitadas
seq_correta:
	.word 0x00
seq_digitada:					@ sequencia digitada
	.word 0x00
fases1:
	.asciz      "Fase 1"
n4:
	.asciz      "4"
msg_inicio:
@    .asciz      "Hello, ARM!"
    .asciz      "INICIO DO JOGO"
msg_erro:
@    .asciz      "I am alive!"
    .asciz      "TEMPO ESGOTADO"
msg_erro_seq:
@    .asciz      "I am alive!"
    .asciz      "SEQUENCIA INCORRETA. TENTE NOVAMENTE"
msg_erro_max:
@    .asciz      "I am alive!"
    .asciz      "NUMERO MAXIMO DE TENTATIVA ATINGIDO"
digitos:
	.byte 0x7e,0x30,0x6d,0x79,0x33,0x5b,0x5f,0x70,0x7f,0x7b,0x4f,0x4e
init:
	.long 0x123
	.long 0x234
	.long 0x345
	.long 0x456




@ end
