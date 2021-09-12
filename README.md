# mbrjump

`mbrjump` is a tiny `#![no_std]` crate that boots a supplied MBR header from your x86-64 kernel.
It puts the system from Long Mode back to Real Mode and jumps to the MBR.

It's mostly useful for quickly getting back to Linux from your OS because the boot process can be very slow on server hardware, and you are too lazy to implement some kexec-like functionality in your kernel.

## Usage

1. Load the MBR from somewhere
1. Disable interrupts
1. Identity map the first 1MiB of memory as executable
1. Call `mbrjump::boot_mbr(your_mbr_slice).unwrap()`
1. ???
1. Profit!
