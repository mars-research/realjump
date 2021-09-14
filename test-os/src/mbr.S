bits 16
org 0x7c00

mov ah, 1
mov al, 2
int 0x10

mov ah, 2
mov bh, 0
mov dh, 0
mov dl, 0
int 0x10

; EEEEE
mov ah, 10
mov al, 69
mov cx, 5
int 0x10

; QEMU isa-debug-exit (code 33)
mov eax, 0x10
out 0xf4, eax

times 510 - ($-$$) db 0
dw 0xaa55
