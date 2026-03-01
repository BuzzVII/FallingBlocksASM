fallingblocks: terminal.asm fallingblocks.asm choose_block.asm clear_rows.asm clear_game_area.asm update_score.asm draw_current_block.asm check_collision.asm
	nasm -f elf32 -o terminal.o terminal.asm
	nasm -f elf32 -o fallingblocks.o fallingblocks.asm
	ld -m elf_i386 -o fallingblocks fallingblocks.o terminal.o

debug: terminal.asm fallingblocks.asm choose_block.asm clear_rows.asm clear_game_area.asm update_score.asm draw_current_block.asm check_collision.asm
	nasm -f elf32 -g -F dwarf -o terminal.o terminal.asm
	nasm -f elf32 -g -F dwarf -o fallingblocks.o fallingblocks.asm
	ld -m elf_i386 -o fallingblocks fallingblocks.o terminal.o

clean:
	rm -f test.o test
	rm -f terminal.o
	rm -f fallingblocks.o fallingblocks

test: terminal.asm test.asm
	nasm -f elf32 -o terminal.o terminal.asm
	nasm -f elf32 -o test.o test.asm
	ld -m elf_i386 -o test test.o terminal.o

test_debug: terminal.asm test.asm
	nasm -f elf32 -g -F dwarf -o terminal.o terminal.asm
	nasm -f elf32 -g -F dwarf -o test.o test.asm
	ld -m elf_i386 -o test test.o terminal.o
