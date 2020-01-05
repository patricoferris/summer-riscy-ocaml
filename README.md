# Riscy-OCaml 🐫
-----

This Dockerfile creates an Ubuntu 18.04 environment for running OCaml in a RISC-V ecosystem. It uses modified toolchains, tools and compilers for testing custom instructions in RISC-V. The following will be available: 

- riscv-gnu-toolchain: the compiler with modified opcodes
- riscv-tools: an assortment of tools, most importantly a modified ISA simulator, Spike
- /riscv-ocaml/bin/ocamlopt: a modified ocaml cross-compiler for RISC-V
- ocamlopt: standard ocaml compiler (4.07.01, x86) installed in an OPAM switch 

Example Usage
---- 

Here is an example usage using some [benchmarks](https://github.com/patricoferris/riscv-benchmarks).

```
docker build . -t riscy
docker run -it riscy

git clone https://github.com/patricoferris/riscv-benchmarks
cd riscv-benchmarks/src
ocamlopt -o driver driver.ml
./driver build-with-riscv
spike /usr/local/riscv-unknown-elf/pk -s intfloatarray
``` 

