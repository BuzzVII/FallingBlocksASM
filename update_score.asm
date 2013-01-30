update_score:
	pusha
		mov	ecx,	2
		mov	bl,	[lines]
		mov	edx,	LINES_POS
		add	edx,	2
		print_lines:
			mov	al,		bl
			and eax, 	0x0000000f
			add	al,		'0'
			cmp	al,		'9'
			jle	no_hex_line
				add al,	'A'-'9'-1
			no_hex_line:
			mov	[edx], 	al
			shr	ebx,	4
			sub	edx,	2
			loop print_lines
		mov	ecx,	6
		mov	ebx,	[score]
		mov	edx,	SCORE_POS
		add edx,	10
		print_score:
			mov	eax,	ebx
			and eax, 	0x0000000f
			add	al,		'0'
			cmp al,		'9'
			jle	no_hex_score
				add al,	'A'-'9'-1
			no_hex_score:
			mov	[edx], 	al
			shr	ebx,	4
			sub	edx,	2
			loop print_score
	popa
	ret