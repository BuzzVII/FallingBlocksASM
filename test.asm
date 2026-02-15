section .data
    prompt db "Press a key: ", 0
    len_p  equ $ - prompt
    key    db 0                ; Variable to store key
    termios times 60 db 0      ; Buffer for termios struct (48 bytes)
    orig_termios times 60 db 0 ; Buffer to save original termios settings
    ; \033 is 27 in decimal or 0x1B in hex
    clear_seq db 27, "[H", 27, "[2J"
    clear_len equ $ - clear_seq

section .text
    global _start

_start:
    ; sys_write(fd=1, buf=clear_seq, count=clear_len)
    mov eax, 4          ; syscall: sys_write
    mov ebx, 1          ; file descriptor: stdout
    mov ecx, clear_seq  ; pointer to string
    mov edx, clear_len  ; number of bytes
    int 0x80            ; call kernel

    ; Get the current terminal settings
    mov eax, 54                ; syscall: sys_ioctl
    mov ebx, 0                 ; stdin
    mov ecx, 0x5401            ; TCGETS
    mov edx, termios           ; pointer to termios struct
    int 0x80

    ; Save the original settings for later restoration
    mov esi, termios           ; source: current settings
    mov edi, orig_termios      ; destination: backup variable
    mov ecx, 60                ; number of bytes to copy (size of termios struct)
    rep movsb

    ; Modify the icanon and echo bits in the c_lflag of the buffer
    mov eax, [termios + 12] ; c_lflag is the third 4-byte tcflag_t)
    and eax, 0xFFFFFFF5
    ;and eax, 0b11111111111111111111111111110101; ; Clear ICANON (bit 2) and ECHO (bit 4)
    mov [termios + 12], eax ; Update c_lflag with new settings

    ; Send ioctl to set the new terminal settings (non-canonical mode, no echo)
    mov eax, 54              ;  syscall: sys_ioctl
    mov ebx, 0                 ; stdin
    mov ecx, 0x5402            ; TCSETS
    mov edx, termios           ; pointer to termios struct
    int 0x80

    ; Print Prompt (sys_write)
    mov eax, 4                 ; syscall: sys_write
    mov ebx, 1                 ; file descriptor: stdout
    mov ecx, prompt            ; buffer
    mov edx, len_p             ; length
    int 0x80

    ; Loop until Q from read Keypress (sys_read)
    main_loop:
        mov eax, 3                 ; syscall: sys_read
        mov ebx, 0                 ; file descriptor: stdin
        mov ecx, key               ; buffer to store character
        mov edx, 1                 ; read 1 byte
        int 0x80
        cmp byte [key], 'q'        ; check if the key is 'q'
        jne main_loop              ; if not 'q', continue looping

    ; Restore original terminal settings before exiting
    mov eax, 54              ; syscall: sys_ioctl
    mov ebx, 0                 ; stdin
    mov ecx, 0x5402            ; TCSETS
    mov edx, orig_termios      ; pointer to original termios struct
    int 0x80

    ; Exit (sys_exit)
    mov eax, 1                 ; syscall: sys_exit
    xor ebx, ebx               ; status: 0
    int 0x80
