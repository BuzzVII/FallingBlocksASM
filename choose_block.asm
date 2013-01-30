choose_block:
	pusha	
	retry_choose:
	mov	ebx,	[next_block]
	mov	[current_block], ebx
	RDTSC
	shr	eax,	4
	and	al,	00000111b
	;Take current CPU counts, use second lowest bit and AND with 7 to get a random number between 0-7 (one two many)
	;select next block based on this
	cmp	al,0x0
	je	S_O
	cmp al,0x1
	je	S_I
	cmp al,0x2
	je	S_T
	cmp al,0x3
	je	S_L1
	cmp al,0x4
	je	S_L2
	cmp al,0x5
	je	S_S
	cmp al,0x6
	je	S_Z
	cmp al,0x7		;increase the chance of the T block
	je	S_T
	
	;functions to set the memory address for the next block to the location in memory of the block randomly selected
	S_O:
	mov edx,	O
	mov	[next_block],edx
	jmp block_done
	S_I:
	mov edx,	I
	mov	[next_block],edx
	jmp block_done
	S_T:
	mov edx,	T
	mov	[next_block],edx
	jmp block_done
	S_L1:
	mov edx,	L1
	mov	[next_block],edx
	jmp block_done
	S_L2:
	mov edx,	L2
	mov	[next_block],edx
	jmp block_done
	S_S:
	mov edx,	S
	mov	[next_block],edx
	jmp block_done
	S_Z:
	mov edx,	Z
	mov	[next_block],edx
	
	;all block select function jump to here to move what used to be the next block into current block 
	block_done:
	mov	ebx,	[current_block]
	cmp	ebx,	0x00					;check to make sure there is acctually a current block, if not shift next in and regenerate next
	jne finished_block_select
	jmp retry_choose
	finished_block_select:
	
mov	bl,CURRENT_BLOCK_START
mov	[Block_position_x], 	bl
mov	[Last_position_x],		bl
mov	bl,0x00
mov	[Block_position_y],		bl
mov	[Last_position_y],		bl
mov	[Block_rotation],		bl
mov	[Rotations_for_block],	bl
;call	draw_current_block
	
clear_next_block:
	mov ebx, NEXT_BLOCK_START
		mov ecx, 0x08
		clear_next_block_loop:
			mov	dl,	' '
			mov	dh,	0x0f
			mov	[ebx],	dx
			add ebx,2
			cmp ecx,0x4
			je clear_next_new_line
			back_to_clear_next:
			loop clear_next_block_loop	
	jmp Draw_next_block
		
	;function for clear_next_block	
	clear_next_new_line:
		mov ebx, NEXT_BLOCK_START+0xA0
		jmp	back_to_clear_next
		
	
Draw_next_block:
	mov ebx, NEXT_BLOCK_START
		mov	eax, [next_block]
		add eax, 0x2
		next_tert:
			mov ecx, 0x00FF
			mov dl, [eax]
			cmp dl,0			;check for exit character
			je finished_tert	;exit loop at end of string
			cmp	dl,1
			je finished_tert	;exit loop at end of string
			cmp	dl,2
			je	next_block_line
			cmp	dl,'B'
			je	fill_block
			mov	dx, [ebx]
			mov	[ebx],	dx
			add ebx, 0x2
			back_for_more_block:
			inc eax
		jmp	next_tert
		finished_tert:
	popa
	ret
	
	;function for draw_next_block
	next_block_line:
		mov	ebx, NEXT_BLOCK_START+0xA0
		jmp back_for_more_block
	
	;function for draw_next_block
	fill_block:
		push	ebx
		mov ebx, [next_block]
		mov dh, [ebx]
		pop		ebx
		mov dl, ' '
		mov	[ebx],	dx
		add ebx, 0x2
		jmp back_for_more_block
