# realjump

`realjump` is a tiny `#![no_std]` crate that loads and boots Real Mode code (MBR, GRUB2, etc.) from your x86-64 kernel.
It puts the system from Long Mode back to Real Mode and jumps to the code.

## But why?

It's mostly useful for quickly getting back to Linux from your OS because the boot process can be very slow on server hardware, and you are too lazy to implement some kexec-like functionality in your kernel.

## Usage

1. Disable interrupts.
1. Identity map the first 1MiB of memory as executable.
1. Halt all other processors.
1. Call `realjump::boot(your_mbr_slice, 0x7c00).unwrap()`.
1. `realjump` will take care of the rest. It will load its own GDT and take the system all the way back to Real Mode.

## INT 13h

Certain BIOS services, like INT 13h, may no longer function when you return to Real Mode.
For GRUB2, you can work around this by loading the `core.img` directly with `realjump::boot_grub2`.
