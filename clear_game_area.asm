clear_game_area:
	pusha
	mov ebx, CLEAR_START
	add ebx,	4
	mov ecx,		0x14 ;make 15 to not leave gap at top
	clear_game_area_loop:
		push ecx
		mov	eax, Clear_strip
		next_space:
			mov ecx, 0x00FF
			mov dl, [eax]
			mov dh, 0x0f		
			cmp dl,0			;check for exit character
			je finished_line	;exit loop at end of string
			mov	[ebx],	dx
			inc eax
			add ebx, 0x2
		jmp	next_space
		finished_line:
		add	ebx,	0x39*2
		pop	ecx
	loop	clear_game_area_loop	
	popa
	ret