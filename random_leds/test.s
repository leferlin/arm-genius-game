@ luzes aleatórias, sem uso do timer

	.global _start          @ ligador precisa deste rótulo
	
@ endereço painel de leds
        .set LEDSADDR,0x90000
        .set INTERVAL,0x400000

        .text
_start:
	                        @ para simplificar, vamos executar em modo supervisor
	mov     sp,#0x80000     @ prepara pilha
	ldr     r0,=init        @ carrega primeiro parâmetro
	mov     r1,#4           @ carrega segundo parâmetro
	bl      init_by_array   @ inicializa
loop:	
	bl      genrand_int32   @ chama gerador, resultado em r0
        ldr     r2,=LEDSADDR    @ escreve valor aleatório no
        str     r0,[r2]         @ painel de leds
        ldr     r1,=INTERVAL    @ inicializa contador de tempo
espera:
        subs    r1,#1           @ espera contador de tempo zerar
        bne     espera
        b       loop
	
	.data
init:
	.long 0x123
	.long 0x234
	.long 0x345
	.long 0x456
	