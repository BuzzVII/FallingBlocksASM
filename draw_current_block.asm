clear_current_block:
	;set current block position
	pusha
	mov eax,	0x0
	mov	al,[Last_position_x]
	imul eax,	2
	mov ebx, CLEAR_START
	add ebx, eax
	mov eax,	0x0
	mov al,[Last_position_y]
	imul eax,0xA0
	add ebx, eax
		mov	eax, [current_block]
		add eax, 0x1
		mov dl,[eax]
		mov	[Rotations_for_block],	dl
		add eax, 0x1
		clear_game_block:
			mov ecx, 0x00FF
			mov dl, [eax]
			cmp dl,0				;check for exit character
			je finished_clear	;exit loop at end of string
			cmp	dl,1
			je finished_clear	;exit loop at end of string
			cmp	dl,2
			je	next_clear_block_line
			cmp	dl,'B'
			je	clear_game_fill
			;mov	dx, [ebx]
			;mov	[ebx],	dx
			add ebx, 0x2
			back_for_more_clear:
			inc eax
		jmp	clear_game_block
	finished_clear:
	popa
	ret
		
	;function for clear_current_block
	next_clear_block_line:
		push eax
		mov eax,0x0
		mov	al,[Last_position_x]
		imul eax,	2
		mov ebx, CLEAR_START
		add ebx, eax
		mov eax,	0x0
		mov al,[Last_position_y]
		add eax,0x1
		imul eax,0xA0
		add ebx, eax
		pop eax
		jmp back_for_more_clear

	;function for clear_current_block
	clear_game_fill:
		mov dh, 0x0f
		mov dl, ' '
		mov	[ebx],	dx
		add ebx, 0x2
		jmp back_for_more_clear	

draw_current_block:		
	;set current block position
	pusha
	mov eax,	0x0
	mov	al,[Block_position_x]
	imul eax,	2
	mov ebx, CLEAR_START
	add ebx, eax
	mov eax,	0x0
	mov al,[Block_position_y]
	imul eax,0xA0
	add ebx, eax
		mov	eax, [current_block]
		add eax, 0x1
		mov dl,[eax]
		mov	[Rotations_for_block],	dl
		add eax, 0x1
		new_game_block:
			mov ecx, 0x00FF
			mov dl, [eax]
			cmp dl,0				;check for exit character
			je finished_game_block	;exit loop at end of string
			cmp	dl,1
			je finished_game_block	;exit loop at end of string
			cmp	dl,2
			je	next_game_block_line
			cmp	dl,'B'
			je	fill_game_block
			;mov	dx, [ebx]
			;mov	[ebx],	dx
			add ebx, 0x2
			back_for_more_game_block:
			inc eax
		jmp	new_game_block
	finished_game_block:
	popa
	ret
		
	;function for draw_current_block
	next_game_block_line:
		push eax
		mov eax,0x0
		mov	al,[Block_position_x]
		imul eax,	2
		mov ebx, CLEAR_START
		add ebx, eax
		mov eax,	0x0
		mov al,[Block_position_y]
		add eax,0x1
		imul eax,0xA0
		add ebx, eax
		pop eax
		jmp back_for_more_game_block

	;function for draw_current_block
	fill_game_block:
		push	ebx
		mov ebx, [current_block]
		mov dh, [ebx]
		pop		ebx
		mov dl, ' '
		mov	[ebx],	dx
		add ebx, 0x2
		jmp back_for_more_game_block