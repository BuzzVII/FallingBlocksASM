clear_game_area:
	pusha
    ; Clear the game area by setting the characters to " " (space)
    ; The gamer area is 21 columns wide and 21 rows high, starting from (29, 2)
    mov ecx, 21
    .row_loop:
       mov eax, 2
       mov ebx, 29
       add eax, ecx
       call move_cursor
       mov ebx, clear_strip 
       mov edx, 21
       call print
    loop .row_loop
	popa
	ret
