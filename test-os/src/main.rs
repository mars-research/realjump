#![no_std]
#![feature(asm, start)]

use core::panic::PanicInfo;

#[start]
fn main(_argc: isize, _argv: *const *const u8) -> isize {
    let mbr = include_bytes!(concat!(env!("OUT_DIR"), "/mbr.bin"));

    unsafe {
        realjump::boot_mbr(mbr).unwrap();
    }

    0
}

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    unsafe {
        asm!("int3");
    }

    loop {}
}
