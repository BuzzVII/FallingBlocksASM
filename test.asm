section .data
    prompt db "Press a key: ", 0
    len_p  equ $ - prompt
    key    db 0
    termios times 60 db 0
    orig_termios times 60 db 0
    TERMIOS_SIZE equ 60
    clear_seq db 27, "[H", 27, "[2J"
    clear_len equ $ - clear_seq
    TCGETS equ 0x5401
    TCSETS equ 0x5402
    SYS_IOCTL equ 54
    SYS_WRITE equ 4
    SYS_READ equ 3
    SYS_EXIT equ 1
    STDIN equ 0
    STDOUT equ 1
    C_LFLAG_OFFSET equ 12
    ICANON equ 0x4
    ECHO equ 0x8

section .text
    global _start

_start:
    ; Get the current terminal settings
    mov eax, SYS_IOCTL
    mov ebx, STDIN
    mov ecx, TCGETS
    mov edx, termios
    int 0x80

    ; Save the original settings for later restoration
    mov esi, termios
    mov edi, orig_termios
    mov ecx, TERMIOS_SIZE
    rep movsb

    ; Modify the icanon and echo bits in the c_lflag of the buffer
    mov eax, [termios + C_LFLAG_OFFSET]
    and eax, 0xFFFFFFF5
    mov [termios + C_LFLAG_OFFSET], eax

    ; Send ioctl to set the new terminal settings (non-canonical mode, no echo)
    mov eax, SYS_IOCTL
    mov ebx, STDIN
    mov ecx, TCSETS
    mov edx, termios
    int 0x80

    ; Loop until q from read Keypress (sys_read)
    main_loop:
        call clear_screen
        call prompt_user
        mov eax, SYS_READ
        mov ebx, STDIN
        mov ecx, key
        mov edx, 1
        int 0x80
        cmp byte [key], 'q'
        jne main_loop

    ; Restore original terminal settings before exiting
    mov eax, SYS_IOCTL
    mov ebx, STDIN
    mov ecx, TCSETS
    mov edx, orig_termios
    int 0x80

    ; Exit (sys_exit)
    mov eax, SYS_EXIT
    xor ebx, ebx               ; status: 0
    int 0x80

clear_screen:
    mov eax, SYS_WRITE
    mov ebx, STDOUT
    mov ecx, clear_seq
    mov edx, clear_len
    int 0x80
    ret

prompt_user:
    mov eax, SYS_WRITE
    mov ebx, STDOUT
    mov ecx, prompt
    mov edx, len_p
    int 0x80
    ret

