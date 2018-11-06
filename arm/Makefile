# Makefile atividade 1 - MC404

permitions:
	chmod +x arm*

random: random.c
	./arm-none-eabi-gcc -c random.c

assembler: atividade1.s
	./arm-none-eabi-as -o atividade1.o atividade1.s

linker: random.o atividade1.o mapa.lds
	./arm-none-eabi-ld -o atividade1 -Tmapa.lds atividade1.o random.o

run: devices.txt atividade1
	./armsim -d devices.txt -l atividade1
