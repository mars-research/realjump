use std::env;
use std::path::PathBuf;
use std::process::Command;

fn main() {
    println!("cargo:rerun-if-changed=src/redpill.S");

    let out_dir = PathBuf::from(env::var("OUT_DIR").unwrap());
    let out = out_dir.join("redpill.bin");
    assert!(Command::new("nasm")
        .args(&["src/redpill.S", "-fbin"])
        .arg("-o").arg(out)
        .status()
        .unwrap()
        .success());
}
