#!/usr/bin/env bash

set -euo pipefail

pushd $(dirname "$0")

cargo build
objcopy -O elf32-i386 target/x86_64-unknown-none/debug/fakeos fakeos.32

set +e
qemu-system-x86_64 -kernel fakeos.32 -nographic -device isa-debug-exit,iobase=0xf4,iosize=0x4

code=$?

if [ $code -ne 33 ]; then
	echo "QEMU exited with $code - should be 33"
	exit 1
fi

echo "Success"
