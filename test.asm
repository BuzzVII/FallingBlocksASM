section .data
    CLEAR_SEQ db 27, "[H", 27, "[2J"
    CLEAR_LEN equ $ - CLEAR_SEQ
    HIDE_CURSOR_SEQ db 27, "[?25l"
    HIDE_CURSOR_LEN equ $ - HIDE_CURSOR_SEQ
    SHOW_CURSOR_SEQ db 27, "[?25h"
    SHOW_CURSOR_LEN equ $ - SHOW_CURSOR_SEQ
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
    timespec_buffer resb 16
    termios resb TERMIOS_SIZE
    orig_termios resb TERMIOS_SIZE

section .text
    global _start



_start:
    call set_terminal_mode

    ; Loop until the user presses the correct key
    mov dword [current_frame], 0
    mov byte [key_selected], 'a'
    main_loop:
        call clear_screen
        call select_random_key
        call prompt_user
        call get_keypress
        call timeout ; TODO: calcutate remaining time, currently constant
        mov eax, [current_frame]
        inc eax
        mov [current_frame], eax
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
    mov eax, SYS_WRITE
    mov ebx, STDOUT
    mov ecx, CLEAR_SEQ
    mov edx, CLEAR_LEN
    int 0x80
    ret

prompt_user:
    mov eax, SYS_WRITE
    mov ebx, STDOUT
    mov ecx, key_selected
    mov edx, 1
    int 0x80
    ret

select_random_key:
    ; Check if the current frame count has reached the threshold to select a new key
    mov eax, [current_frame]
    cmp eax, CHARACTER_FRAMES
    jl .keep_current_key
    ; Use /dev/urandom to generate a key between 'a' and 'z'
    call get_random_byte
    and byte [key_selected], 26
    add byte [key_selected], 'a'     ; Shift to 'a'-'z'
    mov dword [current_frame], 0 ; Reset frame count for the new key
    .keep_current_key:
    ret

timeout:
    mov eax, SYS_NANOSLEEP
    mov ebx, FRAME_TIME_NS
    mov ecx, 0
    int 0x80
    ret

get_keypress:
    ; set keypressed to 0 before reading
    mov byte [key_pressed], 0
    mov eax, SYS_READ
    mov ebx, STDIN
    mov ecx, key_pressed
    mov edx, 1
    int 0x80
    ; TODO: Non-blocking so we should check if we got a keypress or not
    ret

get_system_time:
    mov eax, SYS_CLOCK_GETTIME
    mov ebx, CLOCK_REALTIME
    mov ecx, timespec_buffer
    int 0x80
    ret

get_random_byte:
    mov eax, SYS_OPEN
    mov ebx, RANDOM_PATH
    mov ecx, READ_ONLY
    int 0x80
    mov esi, eax        ; Save the file descriptor

    mov eax, SYS_READ
    mov ebx, esi
    mov ecx, key_selected
    mov edx, 1
    int 0x80

    mov eax, SYS_CLOSE
    mov ebx, esi
    int 0x80
    ret

tcget:
    ; Get the current terminal settings into edx
    mov eax, SYS_IOCTL
    mov ebx, STDIN
    mov ecx, TCGETS
    int 0x80
    ret

tcset:
    ; Set the terminal settings from edx
    mov eax, SYS_IOCTL
    mov ebx, STDIN
    mov ecx, TCSETS
    int 0x80
    ret

set_terminal_mode:
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
    ret

