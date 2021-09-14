extern crate nasm_rs;

use std::env;
use std::path::PathBuf;
use std::process::Command;

macro_rules! source {
    ($($arg:tt)*) => {
        println!("cargo:rerun-if-changed={}", format_args!($($arg)*));
    };
}

macro_rules! static_link {
    ($lib: expr) => {
        println!("cargo:rustc-link-lib=static={}", $lib);
    };
}

fn main() {
    source!("build.rs");
    x86_64_asm("crt0.S");
    x86_raw("mbr.S", "mbr.bin");
}

fn x86_64_asm(source: &str) {
    let file = format!("src/{}", source);
    source!("{}", file);

    let mut mb = nasm_rs::Build::new();
    mb.file(&file);
    mb.target("");
    mb.flag("-felf64");
    mb.compile(source);

    static_link!(source);
}

fn x86_raw(source: &str, target: &str) {
    let file = format!("src/{}", source);
    source!("{}", file);

    let out_dir = PathBuf::from(env::var("OUT_DIR").unwrap());
    let out = out_dir.join(target);
    assert!(Command::new("nasm")
        .args(&[&file, "-fbin"])
        .arg("-o").arg(out)
        .status()
        .unwrap()
        .success());
}
