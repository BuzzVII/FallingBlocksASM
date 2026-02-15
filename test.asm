section .data
    CLEAR_SEQ db 27, "[H", 27, "[2J"
    CLEAR_LEN equ $ - CLEAR_SEQ
    CLEAR_ROW_SEQ db 27, "[J"
    CLEAR_ROW_LEN equ $ - CLEAR_ROW_SEQ
    HIDE_CURSOR_SEQ db 27, "[?25l"
    HIDE_CURSOR_LEN equ $ - HIDE_CURSOR_SEQ
    SHOW_CURSOR_SEQ db 27, "[?25h"
    SHOW_CURSOR_LEN equ $ - SHOW_CURSOR_SEQ
    POS_TEMPLATE db 27, "[00;00H"
    POS_LEN equ $ - POS_TEMPLATE
    TCGETS equ 0x5401
    TCSETS equ 0x5402
    TERMIOS_SIZE equ 60
    C_LFLAG_OFFSET equ 12
    C_CC_OFFSET equ 16
    VMIN equ 0x6
    VTIME equ 0x7
    ICANON equ 0x4
    ECHO equ 0x8
    SYS_NANOSLEEP equ 162
    SYS_IOCTL equ 54
    SYS_CLOSE equ 6
    SYS_OPEN equ 5
    SYS_WRITE equ 4
    SYS_READ equ 3
    SYS_EXIT equ 1
    SYS_CLOCK_GETTIME equ 265
    STDIN equ 0
    STDOUT equ 1
    READ_ONLY equ 0
    CLOCK_REALTIME equ 0
    RANDOM_PATH db "/dev/urandom", 0
    FRAME_TIME_NS dd 0, 16000000 ; 16ms = 60 FPS
    CHARACTER_FRAMES equ 120 ; Number of frames to displace character before changing

section .bss
    current_frame resd 1
    key_pressed resb 1
    key_selected resb 1
    row resd 1
    col resd 1
    timespec_buffer resb 16
    termios resb TERMIOS_SIZE
    orig_termios resb TERMIOS_SIZE

section .text
    global _start



_start:
    call set_terminal_mode
    call clear_screen

    ; Loop until the user presses the correct key
    mov dword [current_frame], CHARACTER_FRAMES ; Start with the max frames to select a new key immediately
    mov byte [row], 5
    mov byte [col], 5
    main_loop:
        ; Check if the current frame count has reached the threshold to select a new key
        mov eax, [current_frame]
        inc eax
        mov [current_frame], eax
        cmp eax, CHARACTER_FRAMES
        jl .keep_current_key
            call move_cursor
            call clear_row
            call select_random_key
            call select_random_row_col
            call move_cursor
            call prompt_user
            mov dword [current_frame], 0 ; Reset frame count for the new key
        .keep_current_key:
        call get_keypress
        call timeout ; TODO: calcutate remaining time, currently constant
        mov al, [key_pressed]
        cmp al, [key_selected]
        jne main_loop

    ; Restore original terminal settings before exiting
    mov edx, orig_termios
    call tcset

    ; Exit (sys_exit)
    mov eax, SYS_EXIT
    xor ebx, ebx ; status: 0
    int 0x80

clear_screen:
    pushad
    mov eax, SYS_WRITE
    mov ebx, STDOUT
    mov ecx, CLEAR_SEQ
    mov edx, CLEAR_LEN
    int 0x80
    popad
    ret

clear_row:
    pushad
    mov eax, SYS_WRITE
    mov ebx, STDOUT
    mov ecx, CLEAR_ROW_SEQ
    mov edx, CLEAR_ROW_LEN
    int 0x80
    popad
    ret

prompt_user:
    pushad
    mov eax, SYS_WRITE
    mov ebx, STDOUT
    mov ecx, key_selected
    mov edx, 1
    int 0x80
    popad
    ret

select_random_key:
    ; Store random value returned in ecx for use in prompt_user
    pushad
    ; Use /dev/urandom to generate a key between 'a' and 'z'
    mov ecx, key_selected ; Pass the address of key_selected to select_random_key
    call get_random_byte
    and byte [ecx], 26
    add byte [ecx], 'a'     ; Shift to 'a'-'z'
    popad
    ret

select_random_row_col:
    ; Store random value returned in ecx for use in row/col
    pushad
    mov ecx, row
    call get_random_byte
    and byte [ecx], 9
    add byte [ecx], 1      ; Shift to 1-10
    mov ecx, col
    call get_random_byte
    and byte [ecx], 9
    add byte [ecx], 1      ; Shift to 1-10
    popad
    ret

timeout:
    pushad
    mov eax, SYS_NANOSLEEP
    mov ebx, FRAME_TIME_NS
    mov ecx, 0
    int 0x80
    popad
    ret

get_keypress:
    pushad
    ; set keypressed to 0 before reading
    mov byte [key_pressed], 0
    mov eax, SYS_READ
    mov ebx, STDIN
    mov ecx, key_pressed
    mov edx, 1
    int 0x80
    ; TODO: Non-blocking so we should check if we got a keypress or not
    popad
    ret

get_system_time:
    pushad
    mov eax, SYS_CLOCK_GETTIME
    mov ebx, CLOCK_REALTIME
    mov ecx, timespec_buffer
    int 0x80
    popad
    ret

get_random_byte:
    ; Read a random byte from /dev/urandom into ecx
    pushad
    mov edx, ecx
    mov eax, SYS_OPEN
    mov ebx, RANDOM_PATH
    mov ecx, READ_ONLY
    int 0x80
    mov esi, eax        ; Save the file descriptor

    mov eax, SYS_READ
    mov ebx, esi
    mov ecx, edx
    mov edx, 1
    int 0x80

    mov eax, SYS_CLOSE
    mov ebx, esi
    int 0x80
    popad
    ret

tcget:
    ; Get the current terminal settings into edx
    pushad
    mov eax, SYS_IOCTL
    mov ebx, STDIN
    mov ecx, TCGETS
    int 0x80
    popad
    ret

tcset:
    ; Set the terminal settings from edx
    pushad
    mov eax, SYS_IOCTL
    mov ebx, STDIN
    mov ecx, TCSETS
    int 0x80
    popad
    ret

set_terminal_mode:
    pushad
    mov eax, SYS_WRITE
    mov ebx, STDOUT
    mov ecx, HIDE_CURSOR_SEQ
    mov edx, HIDE_CURSOR_LEN
    int 0x80

    ; Get the current terminal settings
    mov edx, termios
    call tcget

    ; Save the original settings for later restoration
    mov esi, termios
    mov edi, orig_termios
    mov ecx, TERMIOS_SIZE
    rep movsb

    ; Modify the icanon and echo bits in the c_lflag of the buffer
    mov eax, [termios + C_LFLAG_OFFSET]
    and eax, 0xFFFFFFF5
    mov [termios + C_LFLAG_OFFSET], eax

    ; Set the VMIN and VTIME control characters to 0 for non-blocking read
    mov byte [termios + C_CC_OFFSET + VMIN], 0
    mov byte [termios + C_CC_OFFSET + VTIME], 0

    ; Send ioctl to set the new terminal settings
    mov edx, termios
    call tcset
    popad
    ret

move_cursor:
    ; TODO: can only go up to 9, need to handle more rows/columns
    ; Format the position sequence with the current row and column
    mov eax, [row]
    add eax, '0'
    mov [POS_TEMPLATE + 3], al
    mov eax, [col]
    add eax, '0'
    mov [POS_TEMPLATE + 6], al

    ; Write the position sequence to move the cursor
    mov eax, SYS_WRITE
    mov ebx, STDOUT
    mov ecx, POS_TEMPLATE
    mov edx, POS_LEN
    int 0x80
    ret
