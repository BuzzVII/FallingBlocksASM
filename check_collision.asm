;%include 
;check_collision:
;	pusha
;	
;	;check walls
;	mov dl,	[Block_position_x]
;	cmp	dl,	0x15	
;	je	hit_side
;	cmp	dl,	0xFF
;	je	hit_side
;	jmp didnt_hit_side
;	hit_side:
;	mov edx,	0x0
;	mov dl, 	[Last_position_x]
;	mov [Block_position_x],	dl
;	didnt_hit_side:
;	
;	;check bottom
;	mov dl,	[Block_position_y]
;	cmp	dl,	0x13	
;	jne	block_didnt_land
;	;check other blocks
;	
;	;if block has landed
;	call choose_block
;	block_didnt_land;
;		
;	popa
;	ret
	
check_collision:		
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
		next_collision:
			mov ecx, 0x00FF
			mov dl, [eax]
			cmp dl,0				;check for exit character
			je finished_collision	;exit loop at end of string
			cmp	dl,1
			je finished_collision	;exit loop at end of string
			cmp	dl,2
			je	next_collision_line
			cmp	dl,'B'
			je	check_block_collision
			add ebx, 0x2
			back_for_more_collisions:
			inc eax
		jmp	next_collision
	finished_collision:
	popa
	ret
		
	;function for draw_current_block
	next_collision_line:
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
		jmp back_for_more_collisions

	;function for draw_current_block
	check_block_collision:
		mov	dx, [ebx]
		cmp dl, ' '
		je	check_block_block_collision
		collision_is_on:
	
		push	ebx
		
		mov	dl,		[Last_position_y]		;check if block last moved down before collision
		mov bl,		[Block_position_y]
		cmp	dl,		bl
		jne	reset_y
		
		mov dl, 	[Last_position_x]		;collision from moving across, reset move across position
		mov [Block_position_x],	dl
		pop		ebx
		add ebx, 0x2
		jmp finished_collision
		
		reset_y:							;collision from moving down, land block call next block
		mov dl, 	[Last_position_y]
		mov [Block_position_y],	dl
		call draw_current_block
		call choose_block
		pop		ebx
		add ebx, 0x2
		jmp finished_collision
		
		;function for checking if a block on block collision occured
		check_block_block_collision:
		cmp dh,	0x0f
		je	back_for_more_collisions
		jmp	collision_is_on
