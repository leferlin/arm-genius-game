# Makefile atividade 1 - MC404

x:
	chmod +x arm*

random: random.c
	arm-none-eabi-gcc -c random.c

assembler: atividade1.s
	./arm-none-eabi-linux-as -o atividade1.o atividade1.s

linker: random assembler mapa.lds
	./arm-none-eabi-linux-ld -o atividade1 -T mapa.lds atividade1.o random.o

run: devices.txt linker
	./armsim -d devices.txt -l atividade1
