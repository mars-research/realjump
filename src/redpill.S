; Self-contained code that tears down long mode and jumps to 0x7c00.
;
; Reference: Figure 1-6, AMD64 Architecture Programmer's Manual Vol. 2
; <https://www.amd.com/system/files/TechDocs/24593.pdf>

bits 64
org 0x500

; Load our tiny GDT
lgdt [gdt32.pointer]

; Switch to 32-bit compatibility mode
mov rbp, rsp
push gdt32.data   ; ss
push rbp          ; rsp
pushfq            ; rflags
push gdt32.code   ; cs
push long32       ; code
iretq

long32:
bits 32

mov ax, gdt32.data
mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax
mov ss, ax

; CR0.PG <- 0
mov eax, cr0
and eax, ~(1 << 31)
mov cr0, eax

xor ebx, ebx
mov cr3, ebx

; EFER.LME <- 0
mov ecx, 0xc0000080
rdmsr
and eax, ~(1 << 8)
wrmsr

; We are now out of Long Mode

; Enter 16-bit Protected Mode

mov ax, gdt32.data16
mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax
mov ss, ax
jmp gdt32.code16:prot16

prot16:
bits 16

; CR0.PE <- 0 
mov eax, cr0
and eax, ~(1 << 0)
mov cr0, eax

jmp 0:real16

real16:

; We are now unplugged from the matrix

cli

xor ax, ax
xor bx, bx
xor cx, cx
xor dx, dx

mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax
mov ss, ax
mov sp, 0x2000

lidt [idt16_pointer]
sti

int 10h

jmp 0:0x7c00

hlt

gdt32:
	dq 0
.code: equ $ - gdt32
	dw 0xffff    ; limit 0-15
	dw 0x0000    ; base 0-15
	db 0         ; base 16-23
	db 10011010b ; Pr | Privl(2) | S | Ex | DC | RW | Ac
	db 11001111b ; Gr | Sz | L | 0 | limit 16-19
	db 0
.code16: equ $ - gdt32
	dw 0xffff    ; limit 0-15
	dw 0x0000    ; base 0-15
	db 0         ; base 16-23
	db 10011010b ; Pr | Privl(2) | S | Ex | DC | RW | Ac
	db 10001111b ; Gr | Sz | 0 | 0 | limit 16-19
	db 0
.data: equ $ - gdt32
	dw 0xffff    ; limit 0-15
	dw 0x0000    ; base 0-15
	db 0         ; base 16-23
	db 10010010b ; Pr | Privl(2) | S | Ex | DC | RW | Ac
	db 11001111b ; Gr | Sz | L | 0 | limit 16-19
	db 0
.data16: equ $ - gdt32
	dw 0xffff    ; limit 0-15
	dw 0x0000    ; base 0-15
	db 0         ; base 16-23
	db 10010010b ; Pr | Privl(2) | S | Ex | DC | RW | Ac
	db 10001111b ; Gr | Sz | 0 | 0 | limit 16-19
	db 0
.pointer:
    dw .pointer - gdt32 - 1
    dq gdt32

idt16_pointer:
	dw 0x3ff
	dd 0
