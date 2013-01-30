clear_rows:
	pusha
	mov eax,	CHECK_LINE_START
	mov	ecx,	0x17
	check_row:
		mov dx, 	[eax]
		cmp	dh,		0x0f
		je move_next_row
		mov	bx,0xb000+' '
		mov	[eax],	bx
		add eax,	2
		check_row_return:
	loop check_row
	jmp shift_rows_down
	lines_complete:
	mov	edx,	0x0
	mov [row_clear_level],dl
	popa
	ret
	
shift_rows_down:
;increment score and lines
	mov edx,			[score]
	add edx,			0x100
	mov	[score],	edx
	mov dl,			[lines]
	add dl,			0x1
	mov	[lines],	dl
	
;move each row down one
	mov	ecx,	0x14
	mov	ebx,	0x0
	mov	bl,	[row_clear_level]
	sub	ecx,	ebx
	row_down_loop:
		push ecx
		mov edx,	CHECK_LINE_START
		mov	ebx,	0x14
		sub ebx,	ecx
		;add ebx,	ecx		;add rows up from current row in loop
		imul ebx,	0xA0
		sub	edx,	ebx
		mov ecx, 	0x18
		row_across_loop:
			mov bx,	[edx]
			push edx
			add edx,	0xA0
			mov [edx],	bx
			pop edx
			add edx,	2
		loop row_across_loop
		pop ecx
	loop row_down_loop
	
	
;reset which row to look at
	mov eax,	CHECK_LINE_START
	mov edx,	0x00;
	mov dl,		[row_clear_level]
	imul edx,	0xA0
	sub	eax,	edx
	mov	ecx,	0x17
	jmp check_row
	
	move_next_row:
	mov	edx,	0x0
	mov dl,		[row_clear_level]
	inc dl
	cmp dl,		0x15
	je lines_complete
	mov [row_clear_level],dl
	mov eax,	CHECK_LINE_START
	imul edx,	0xA0
	sub	eax,	edx
	mov ecx,	0x17
	jmp	check_row_return