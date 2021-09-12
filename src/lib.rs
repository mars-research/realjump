#![no_std]

#![feature(asm)]

use core::result::Result;
use core::ptr::copy;

/// An error.
#[derive(Debug)]
pub enum Error {
    /// The MBR magic is invalid.
    InvalidMagic,
}

/// Boot an MBR.
///
/// This function will never return if it succeeds. Before calling this function, you need to:
///
/// - Identity map the lowest 1MiB memory as executable
/// - Disable interrupts
pub unsafe fn boot_mbr(mbr: &[u8; 512]) -> Result<(), Error> {
    if mbr[510] != 0x55 || mbr[511] != 0xaa {
        return Err(Error::InvalidMagic);
    }

    let code_dest = 0x500 as *mut u8;
    let mbr_dest = 0x7c00 as *mut u8;

    let code = include_bytes!(concat!(env!("OUT_DIR"), "/redpill.bin"));

    copy(mbr as *const [u8] as _, mbr_dest, mbr.len());
    copy(code as _, code_dest, code.len());

    asm!("mov rax, 0x500", "jmp rax");

    unreachable!()
}
