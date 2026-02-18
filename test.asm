section .data
    POS_TEMPLATE db 27, "[00;00H"
    POS_LEN equ $ - POS_TEMPLATE
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

section .text
    global _start
    extern set_terminal_mode
    extern restore_terminal_mode
    extern clear_screen
    extern clear_row
    extern get_keypress

_start:
    call set_terminal_mode
    call clear_screen

    ; Loop until the user presses the correct key
    mov dword [current_frame], CHARACTER_FRAMES ; Start with the max frames to select a new key immediately
    mov byte [row], 25
    mov byte [col], 25
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
        ; set keypressed to 0 before reading
        call get_keypress
        ; copy return value to key_pressed
        mov [key_pressed], al
        call timeout ; TODO: calcutate remaining time, currently constant
        mov al, [key_pressed]
        cmp al, [key_selected]
        jne main_loop

    call restore_terminal_mode

    ; Exit (sys_exit)
    mov eax, SYS_EXIT
    xor ebx, ebx ; status: 0
    int 0x80

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
    and byte [ecx], 25
    add byte [ecx], 'a'     ; Shift to 'a'-'z'
    popad
    ret

select_random_row_col:
    ; Store random value returned in ecx for use in row/col
    pushad

    mov ecx, row
    call get_random_byte
    and byte [ecx], 25
    add byte [ecx], 1

    mov ecx, col
    call get_random_byte
    and byte [ecx], 50
    add byte [ecx], 1

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

move_cursor:
    ; Format the position sequence with the current row and column
    mov eax, [row]
    mov dl, 10
    div dl      ; Get quotient in al (tens) and remainder in ah (ones)
    add al, '0'
    add ah, '0'
    mov [POS_TEMPLATE + 3], ah
    mov [POS_TEMPLATE + 2], al

    mov eax, [col]
    mov dl, 10
    div dl 
    add al, '0'
    add ah, '0'
    mov [POS_TEMPLATE + 6], ah
    mov [POS_TEMPLATE + 5], al

    ; Write the position sequence to move the cursor
    mov eax, SYS_WRITE
    mov ebx, STDOUT
    mov ecx, POS_TEMPLATE
    mov edx, POS_LEN
    int 0x80
    ret
