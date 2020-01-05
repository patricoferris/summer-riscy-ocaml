# Build ocaml-riscv rsicv-gcc spike
FROM ubuntu:18.04 as builder
RUN apt-get -y update
RUN apt-get install -y curl git make gcc g++ autoconf automake autotools-dev
RUN apt-get install -y libmpc-dev libmpfr-dev libgmp-dev libusb-1.0-0-dev
RUN apt-get install -y gawk build-essential bison flex texinfo gperf libtool
RUN apt-get install -y patchutils bc zlib1g-dev device-tree-compiler pkg-config libexpat-dev
RUN apt-get install -y python python3

# Set installation location
ENV RISCV /install 
ENV PROC -j8

# Clone the source codes 
RUN git clone --recursive https://github.com/patricoferris/riscv-gnu-toolchain.git -b caml-is-int
RUN git clone --recursive https://github.com/patricoferris/riscv-tools.git -b caml-is-int

WORKDIR /riscv-gnu-toolchain/riscv-binutils
RUN git checkout caml-is-int
WORKDIR /riscv-tools/riscv-isa-sim
RUN git checkout caml-is-int

# Build gcc
WORKDIR /riscv-gnu-toolchain 
RUN ./configure --prefix=$RISCV
RUN make newlib $PROC
RUN make linux $PROC

# Build tools (importantly Spike ISA sim) 
ENV PATH="$RISCV/bin:${PATH}"
RUN ls "$RISCV/bin"
WORKDIR /riscv-tools 
ENV RISCV /tools
RUN ./build.sh

# Copy over all the built tools 
FROM ubuntu:18.04
RUN apt-get update
RUN apt-get install -y sudo vim device-tree-compiler make
RUN apt-get install -y curl git make gcc g++ autoconf automake autotools-dev
RUN apt-get install -y libmpc-dev libmpfr-dev libgmp-dev libusb-1.0-0-dev
RUN apt-get install -y gawk build-essential bison flex texinfo gperf libtool
RUN apt-get install -y patchutils bc zlib1g-dev device-tree-compiler pkg-config libexpat-dev
RUN apt-get install -y libpixman-1-dev libfdt-dev libglib2.0-dev zlib1g-dev
RUN apt-get install -y python3-pip software-properties-common

# Copy the modified gcc and spike isa sim
COPY --from=builder /install /usr/local
COPY --from=builder /tools /usr/local
# Build the OCaml cross-compiler 
RUN git clone https://github.com/patricoferris/riscv-ocaml.git -b 4.07+cross+custom 
WORKDIR /riscv-ocaml
# Checkout code before the inline assembly updates 
RUN git checkout 88b3b40c87f7d2c239620a04bdf715ab3abdf7c3  
RUN ./configure -no-ocamldoc -no-debugger -prefix /riscv-ocaml && make -j4 world.opt && make install 
ENV PATH="/riscv-ocaml/bin:${PATH}"
# Checkout the latest code with the inline assembly 
RUN git checkout 86d09ad40ac0aaa4e27b0019eeef324d6dc484cb
RUN make clean && ./configure --target riscv64-unknown-linux-gnu -prefix /riscv-ocaml -no-ocamldoc -no-debugger -target-bindir /riscv-ocaml/bin && make -j4 world || /bin/true 
RUN make -j4 opt
RUN cp /riscv-ocaml/bin/ocamlrun byterun
RUN make install

# Opam and x86 compiler
RUN apt-add-repository ppa:avsm/ppa
RUN apt update 
RUN apt install -y opam m4
RUN opam init --disable-sandboxing --compiler=4.07.1 -y 
RUN eval $(opam env)

ENV RISCV /usr/local
ENV LD_LIBRARY_PATH=$RISCV/lib
ENV pk=$RISCV/riscv64-unknown-elf/bin/pk

WORKDIR /
ENTRYPOINT ["/bin/bash"]
