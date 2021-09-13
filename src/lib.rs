//! Tiny no_std crate that loads and boots Real Mode code from an x86-64 kernel.
//!
//! `realjump` is a tiny `#![no_std]` crate that loads and boots Real Mode code (MBR, GRUB2, etc.) from your x86-64 kernel.
//! It puts the system from Long Mode back to Real Mode and jumps to the code.

#![no_std]

#![feature(asm)]
#![deny(missing_docs)]

use core::result::Result;
use core::ptr::{copy, write_volatile};

/// The maximum payload size.
pub const MAX_PAYLOAD_SIZE: usize = 0x78000;

/// Size of the bootstrap code.
pub const BOOTSTRAP_CODE_SIZE: usize = include_bytes!(concat!(env!("OUT_DIR"), "/redpill.bin")).len();

/// The bootstrap code.
static BOOTSTRAP_CODE: &'static [u8] = include_bytes!(concat!(env!("OUT_DIR"), "/redpill.bin"));

/// Where the bootstrap code should be copied to.
const BOOTSTRAP_CODE_DEST: u16 = 0x500;

/// An error.
#[derive(Debug)]
#[non_exhaustive]
pub enum Error {
    /// The payload is too large.
    PayloadTooLarge,

    /// The payload would overlap with the bootstrap code.
    PayloadWouldOverlap,

    /// The MBR magic is invalid.
    InvalidMbrMagic,
}

/// Boot an MBR.
///
/// This function will never return if it succeeds. Before calling this function, you need to:
///
/// - Identity map the lowest 1MiB memory as executable
/// - Disable interrupts
pub unsafe fn boot_mbr(mbr: &[u8; 512]) -> Result<(), Error> {
    if mbr[510] != 0x55 || mbr[511] != 0xaa {
        return Err(Error::InvalidMbrMagic);
    }

    boot(mbr, 0x7c00)
}

/// Boot a GRUB2 core image.
pub unsafe fn boot_grub2(image: &[u8]) -> Result<(), Error> {
    boot_offset(image, 0x8000, 0x200)
}

/// Copy a payload to a destination, then jump to it.
///
/// This is equivalent to calling `boot_offset(payload, destination, 0)`.
pub unsafe fn boot(payload: &[u8], destination: u16) -> Result<(), Error> {
    boot_offset(payload, destination, 0)
}

/// Copy a payload to a destination, then jump to an offset.
///
/// For a GRUB2 `core.img`, the destination and offset should be 0x8000 and 0x200 respectively.
pub unsafe fn boot_offset(payload: &[u8], destination: u16, offset: u16) -> Result<(), Error> {
    if payload.len() > MAX_PAYLOAD_SIZE {
        return Err(Error::PayloadTooLarge);
    }

    let p = (destination, destination + offset);
    let b = (BOOTSTRAP_CODE_DEST, BOOTSTRAP_CODE_DEST + BOOTSTRAP_CODE_SIZE as u16);

    if p.0 <= b.1 && b.0 <= p.1 {
        return Err(Error::PayloadWouldOverlap);
    }

    copy(payload as *const [u8] as _, destination as *mut u8, payload.len());
    copy(BOOTSTRAP_CODE as *const [u8] as _, BOOTSTRAP_CODE_DEST as *mut u8, BOOTSTRAP_CODE.len());

    let entrypoint = (destination + offset) as u16;
    write_volatile(BOOTSTRAP_CODE_DEST as *mut u16, entrypoint);

    asm!("jmp rax", in("rax") BOOTSTRAP_CODE_DEST + 2);

    unreachable!()
}
