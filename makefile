falling_blocks:  
	nasm -f bin -o fallingblocks.img fallingblocks.asm

run:
	qemu-system-x86_64 -fda fallingblocks.img
