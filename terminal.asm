section .data
    CLEAR_SEQ db 27, "[H", 27, "[2J"
    CLEAR_LEN equ $ - CLEAR_SEQ
    CLEAR_ROW_SEQ db 27, "[J"
    CLEAR_ROW_LEN equ $ - CLEAR_ROW_SEQ
    HIDE_CURSOR_SEQ db 27, "[?25l"
    HIDE_CURSOR_LEN equ $ - HIDE_CURSOR_SEQ
    SHOW_CURSOR_SEQ db 27, "[?25h"
    SHOW_CURSOR_LEN equ $ - SHOW_CURSOR_SEQ
    POS_TEMPLATE db 27, "[00;00h"
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
    SYS_IOCTL equ 54
    SYS_WRITE equ 4
    STDIN equ 0
    STDOUT equ 1

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
    global set_terminal_mode
    global restore_terminal_mode
    global clear_screen
    global clear_row

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

restore_terminal_mode:
    pushad
    mov edx, orig_termios
    call tcset

    mov eax, SYS_WRITE
    mov ebx, STDOUT
    mov ecx, SHOW_CURSOR_SEQ
    mov edx, SHOW_CURSOR_LEN
    int 0x80
    popad
    ret

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

