# Makefile atividade 1 - MC404

permitions:
	chmod +x arm*

random: random.c
	./arm-none-eabi-gcc -c random.c

assembler: atividade1.s
	./arm-none-eabi-linux-as -o atividade1.o atividade1.s

linker: assembler random mapa.lds
	./arm-none-eabi-linux-ld -o atividade1 -T mapa.lds atividade1.o random.o

run: linker devices.txt
	./armsim -d devices.txt -l atividade1
