; FakeOS Bootstrap
;
; So fake that I don't even bother checking long mode anymore, sorry
;
; References:
;  - Atmosphere

global start
global start64
global stack_bottom
global stack_top
extern main

section .text

; We assume that we are already in pmode

bits 32
start:
    mov esp, stack_top

    call set_up_page_tables
    call enable_paging

    lgdt [gdt64.pointer]
    jmp gdt64.code:start64

    hlt

bits 64
start64:
    mov ax, 0
    mov ss, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    call main

    hlt

bits 32

; map some pages, then let Rust handle the rest
set_up_page_tables:
    ; map first P4 entry to P3 table
    mov eax, p3_table
    or eax, 0b11 ; present + writable
    mov [p4_table], eax

    ; map first P3 entry to P2 table
    mov eax, p2_table
    or eax, 0b11 ; present + writable
    mov [p3_table], eax

    ; == map each P2 entry to a huge 2MiB page
    mov ecx, 0         ; counter variable

.map_p2_table:
    ; map ecx-th P2 entry to a huge page that starts at address 2MiB*ecx
    mov eax, 0x200000  ; 2MiB
    mul ecx            ; start address of ecx-th page
    or eax, 0b10000011 ; present + writable + huge
    mov [p2_table + ecx * 8], eax ; map ecx-th entry

    inc ecx            ; increase counter
    cmp ecx, 512       ; if counter == 512, the whole P2 table is mapped
    jne .map_p2_table  ; else map the next entry

    ret

enable_paging:
    ; load P4 to cr3 register (cpu uses this to access the P4 table)
    mov eax, p4_table
    mov cr3, eax

    ; enable PAE-flag in cr4 (Physical Address Extension)
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    ; set the long mode bit in the EFER MSR (model specific register)
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr

    ; enable paging in the cr0 register
    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax

    ret

section .rodata
gdt64:
    dq 0 ; zero entry
.code: equ $ - gdt64
    dq (1<<43) | (1<<44) | (1<<47) | (1<<53) ; code segment
.pointer:
    dw $ - gdt64 - 1
    dq gdt64

section .bss
align 4096

p4_table:
    resb 4096
p3_table:
    resb 4096
p2_table:
    resb 4096

stack_bottom:
    resb 1024 * 1024 * 32 ; Reserve this many bytes
stack_top:

section .multiboot_header
	; bit 0: Page-align modules
	; bit 1: Must pass memory map
	; bit 2: Must pass video mode table

	flags equ 0b011
	dd 0x1badb002 ; magic number (multiboot)
	dd flags      ; flags

	; checksum
	dd -0x1badb002 - flags

	dd 0 ; header_addr
	dd 0 ; load_addr
	dd 0 ; load_end_addr
	dd 0 ; bss_end_addr
	dd 0 ; entry_addr
	dd 0 ; mode_type
	dd 1024 ; width
	dd 768 ; height
	dd 32 ; depth
