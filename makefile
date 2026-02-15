fallingblocks:  
	nasm -f elf32 -o fallingblocks.o fallingblocks.asm
	ld -m elf_i386 -o fallingblocks fallingblocks.o

debug:  
	nasm -f elf32 -g -F dwarf -o fallingblocks.o fallingblocks.asm
	ld -m elf_i386 -o fallingblocks fallingblocks.o

clean:
	rm -f fallingblocks.o fallingblocks
