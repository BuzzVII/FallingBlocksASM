[bits 32]

UP_KEY_PRESS: 	equ 0x48
DOWN_KEY_PRESS:	equ 0x50
LEFT_KEY_PRESS:	equ	0x4b
RIGHT_KEY_PRESS:equ 0x4d
S_KEY_DOWN:		equ 0x1f
S_KEY_PRESS:	equ	0x9f
CLEAR_START:	equ	0xb8000+0xbc*2+0xA0-4
NEXT_BLOCK_START equ 0xb8000+0x3c9*2+0xA0
CURRENT_BLOCK_START equ	0x05*2
CHECK_LINE_START equ 0xb8000+0x74c*2-0xa0
LINES_POS		equ	0xb8000+0xbc*2+0xA0*2-18*2
SCORE_POS		equ	LINES_POS+0x50*2
MAIN_LOOP_TIME	equ	1000000

section .text
    global _start ; must be declared for linking

_start:
	call draw_screen
	call wait_for_s
	call clear_game_area
	call choose_block
	main_loop:				;loop until end_game jumps to finish		
		RDTSC		
		mov [Game_loop_start],eax
		call clear_current_block
		call step_down
		call check_collision;includes choosing a new block if collision occured
		call move_block		;rotate, move side to side and move down, check for keypress
		call check_collision;includes choosing a new block if collision occured
		jmp end_game		;includes update score on screen
		back_to_main_loop:
		call clear_rows
		call draw_current_block
		call update_score
		
		waiting:
		RDTSC		
		mov ebx,	[Game_loop_start]
		sub	eax,	ebx
		cmp	eax,	MAIN_LOOP_TIME
		jl	waiting
	jmp main_loop
Finish:
	call wait_for_s
	call main_loop
	

;include all the files that contain the functions
	
;%include 
step_down:
	pusha
	mov	eax,		[Game_loop_count]
	cmp	ax,		0x04			;replace with dificulty level
	jne	nomove
		mov	bl,					[Block_position_y]
		mov	[Last_position_y],	bl
		add	bl,					0x01
		mov	[Block_position_y],	bl
		mov edx,			[score]
		add edx,			0x1
		mov	[score],		edx
		mov	edx,			0x0
		mov	[Game_loop_count], dx
		mov bl,[Block_position_x]
		mov [Last_position_x],  bl
		jmp finished_step
	nomove:
	add eax,	1
	mov [Game_loop_count],	eax
			mov	bl,					[Block_position_y]
		mov	[Last_position_y],	bl
		mov bl,[Block_position_x]
		mov [Last_position_x],  bl
	finished_step:
	popa
	ret
	
;%include 
move_block:
	pusha
		mov	eax,	0x00
		in al,		0x60
		mov	dl,		al
		in al, 		0x61
		or al, 		128
		out 0x61, 	al
		xor al,	 	128
		out 0x61, 	al 
		cmp	dl,		UP_KEY_PRESS
			je	rotate_block_clock
		cmp dl,		DOWN_KEY_PRESS
			je	rotate_block_anti
		cmp	dl,		LEFT_KEY_PRESS
			je	move_block_left
		cmp dl,		RIGHT_KEY_PRESS
			je	move_block_right
		rotate_block_clock:
			jmp finished_block_move
		rotate_block_anti:
			jmp finished_block_move
		move_block_left:
			mov	bl,					[Block_position_x]
			mov	[Last_position_x],	bl
			sub	bl,					0x01
			mov	[Block_position_x],	bl
			jmp finished_block_move
		move_block_right:
			mov	bl,					[Block_position_x]
			mov	[Last_position_x],	bl
			add	bl,					0x01
			mov	[Block_position_x],	bl
			jmp finished_block_move
		finished_block_move:
	popa
	ret
	
;%include
end_game:
	pusha
	popa
	jmp back_to_main_loop

%include 'choose_block.asm'
%include 'clear_rows.asm' 	
%include 'clear_game_area.asm'
%include 'update_score.asm'
%include 'draw_current_block.asm'
%include 'check_collision.asm'
	
;%include 
draw_screen:	;read in screen format 'string (50)',0,repeats,0
	pusha
	call	clear_screen_buffer
	mov		ebx,	Screen_layout ;starting address
	mov		eax,	0x0			  ;starting line
	next_line:
		mov		edx,	0x51
		add		edx,	ebx
		mov		ecx,	0x0
		mov		cl,		[edx]			;number of repeats
		printing_screen:
			call	print_32
			inc		eax
		loop	printing_screen
		add		ebx,	0x52		;shift to next line
		mov		dl,	[ebx]
		cmp		dl,	0
	jne	next_line
	popa
	ret	

clear_screen_buffer:
    pusha
    mov		ebx,	0xb8000
    mov		ecx,	0x50*0x19
    clear_loop:
        mov		word [ebx], 0x0720
        add		ebx, 2
        loop	clear_loop
    popa
    ret

print_32:
    pusha
    mov		edx, [ebx]
    mov		ecx, 0x20
    print_loop:
        mov		al, [edx]
        mov		ah, 0x07
        mov		word [ebx], ax
        add		ebx, 2
        inc		edx
        loop	print_loop
    popa
    ret

;%include
wait_for_s:
	pusha
	s_wait_loop:
        ; read the keyboard status from port 60h into al and store it in dl
        ; These are privilaged instructions, so we have to run in ring 0 to use them. We will use the keyboard status to check for key presses and releases
		;mov	eax,	0x00
		;in al,		0x60
		;mov	dl,		al
		;in al, 0x61  ; read 8255 port 61h ( 97 Decimal ) into al
		;or al, 128  ;        // set the MSB - the keyboard acknowlege signal
		;out 0x61, al ;        // send the keyboard acknowlege signal from al
		;xor al, 128 ;// unset the MSB - the keyboard acknowlege signal
		;out 0x61, al ;    // send the keyboard acknowlege signal from al

        ; This uses sys call so that we can run in ring 3 and still check for key presses. We will use the keyboard status to check for key presses and releases
        mov eax, 0x00
        mov ebx, 0x00
        mov ecx, 0x00
        mov edx, 0x00
        int 0x80
		cmp	dl,		S_KEY_PRESS
        jne	s_wait_loop
    ; ring 0 instructions to reset the keyboard status
	;mov al, 0x20
    ;out 0x20, al
	popa
	ret

;DATA: variables and constants
;store all the Tetrinome shapes in memory as color,no. rotations, piece row, new row/end peice/end Tetrinome
O:db 	01100000b, 0x01,	'BB'	,2, \
			'BB'	,0
I:db	01010000b, 0x02,	'BBBB'	,1, \
			'B'		,2, \
			'B'		,2, \
			'B'		,2, \
			'B'		,0
L1:db	01000000b, 0x04,	'BBB'	,2, \
			'B'		,1, \
			'BB'	,2, \
			' B'	,2, \
			' B'	,1, \
			'  B'	,2, \
			'BBB'	,1, \
			'B'		,2, \
			'B'		,2, \
			'BB'	,0
L2:db	00110000b, 0x04,	'B'		,2, \
			'BBB'	,1, \
			'BB'	,2, \
			'B'		,2, \
			'B'		,1, \
			'BBB'	,2, \
			'  B'	,1, \
			' B'	,2, \
			' B'	,2, \
			'BB'	,0
T:db 	01110000b, 0x03,	'BBB'	,2, \
			' B'	,1, \
			' B'	,2, \
			'BB'	,2, \
			' B'	,1, \
			' B'	,2, \
			'BBB'	,0
S:db 	00010000b, 0x02,	' BB'	,2, \
			'BB'	,1, \
			'B'		,2, \
			'BB'	,2, \
			' B'	,0
Z:db 	0010000b, 0x02,	'BB'	,2, \
			' BB'	,1, \
			' B'	,2, \
			'BB'	,2, \
			'B'		,0
;WIN:db					'You WON!',0
;LOSE:db					'You LOST!',0
;PLAY_AGAIN:db			'Press S to play again'
;FINISH_GAME:db			'Press Q to quit'
score:dd				0x00000000
lines:db				0x00
current_block:dd		0x00000000
next_block:dd			0x00000000
Block_position_x:db 	0x00
Last_position_x:db		0x00
Block_position_y:db		0x00
Last_position_y:db		0x00
Block_rotation:db		0x00
Rotations_for_block:db	0x00
Game_loop_start:dd		0x00000000
Game_loop_count:dw		0x0000
row_clear_level:db		0x00
Clear_strip:db			'                       ',0
;25 rows X 80 columns = 1440
Screen_layout:		
db'================================================================================',0,1, \
  '|                   =======================================                    |',0,1, \
  '|                   |\\\\\\|                       |//////|                    |',0,2, \
  '| LINES :           |\\\\\\|                       |//////|                    |',0,1, \
  '| SCORE :           |//////|                       |\\\\\\|                    |',0,1, \
  '|                   |\\\\\\|                       |//////|                    |',0,3, \
  '| NEXT BLOCK:       |//////|                       |\\\\\\|                    |',0,1, \
  '|  ===============  |\\\\\\|   Press S to start    |//////|                    |',0,1, \
  '|  |             |  |//////|                       |\\\\\\|                    |',0,6, \
  '|  ===============  |\\\\\\|                       |//////|                    |',0,1, \
  '|                   |\\\\\\|                       |//////|                    |',0,5, \
  '|                   =======================================                    |',0,1, \
  '================================================================================',0,1,0

