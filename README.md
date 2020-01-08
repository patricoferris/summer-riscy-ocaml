# Riscy-OCaml 🐫
-----

This Dockerfile creates an Ubuntu 18.04 environment for running OCaml in a RISC-V ecosystem. It uses modified toolchains, tools and compilers for testing custom instructions in RISC-V. The following will be available: 

- riscv-gnu-toolchain: the compiler with modified opcodes
- riscv-tools: an assortment of tools, most importantly a modified ISA simulator, Spike
- /riscv-ocaml/bin/ocamlopt: a modified OCaml cross-compiler for RISC-V
- /og-riscv-ocaml/bin/ocamlopt: the unmodified OCaml cross-compiler for RISC-V
- ocamlopt: standard ocaml compiler (4.07.01, x86) installed in an OPAM switch 

Example Usage
---- 

Here is an example usage using some [benchmarks](https://github.com/patricoferris/riscv-benchmarks).

```
docker build . -t riscy
docker run -it riscy

git clone https://github.com/patricoferris/riscv-benchmarks
cd riscv-benchmarks/src
opam install dune ppx_jane core
eval $(opam env)
dune exec -- ./bench.exe build -c /riscv-ocaml/bin/ocamlopt -args "-ccopt -static" -v -asm
spike /usr/local/riscv64-unknown-elf/bin/pk -s intfloatarray.out
``` 

