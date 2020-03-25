# Build ocaml-riscv rsicv-gcc spike
FROM ubuntu:18.04 as builder
RUN apt-get -y update
RUN apt-get install -y curl git make gcc g++ autoconf automake autotools-dev
RUN apt-get install -y libmpc-dev libmpfr-dev libgmp-dev libusb-1.0-0-dev
RUN apt-get install -y gawk build-essential bison flex texinfo gperf libtool
RUN apt-get install -y patchutils bc zlib1g-dev device-tree-compiler pkg-config libexpat-dev
RUN apt-get install -y python python3
RUN rm -rf /var/lib/apt/lists

# Set installation location
ENV RISCV /install 
ENV PROC -j8

# Clone the source codes 
RUN git clone --recursive https://github.com/patricoferris/riscv-gnu-toolchain.git -b caml-is-int
RUN git clone --recursive https://github.com/patricoferris/riscv-tools.git -b caml-is-int


# Checkout correct files 
WORKDIR /riscv-gnu-toolchain/riscv-binutils
RUN git checkout ocval
RUN git pull
RUN git log -n 1
WORKDIR /riscv-tools/riscv-isa-sim
RUN git checkout ocval
RUN git log -n 1
WORKDIR /riscv-tools/riscv-opcodes
RUN git checkout ocval
RUN git log -n 1

# Build gcc
WORKDIR /riscv-gnu-toolchain 
RUN ./configure --prefix=$RISCV
RUN make newlib $PROC
RUN make linux $PROC
RUN make clean 

# Build tools (importantly Spike ISA sim) 
ENV PATH="$RISCV/bin:${PATH}"
RUN ls "$RISCV/bin"
WORKDIR /riscv-tools 
RUN git log -n 1
RUN git pull 
ENV RISCV /tools

WORKDIR /riscv-tools/riscv-isa-sim
RUN git pull && git log -n 1

WORKDIR /riscv-tools
RUN ./build.sh

# Copy over all the built tools 
FROM ubuntu:18.04
RUN apt-get update
RUN apt-get install -y sudo vim device-tree-compiler make
RUN apt-get install -y curl git make gcc g++ autoconf automake autotools-dev
RUN apt-get install -y python3-pip software-properties-common

RUN rm -rf /var/lib/apt/lists

# Copy the modified gcc and spike isa sim
COPY --from=builder /install /usr/local
COPY --from=builder /tools /usr/local
# Build the OCaml cross-compiler
RUN git clone https://github.com/patricoferris/riscv-ocaml.git -b 4.07+cross+custom 
RUN git clone https://github.com/patricoferris/riscv-ocaml.git -b 4.07+cross+custom /og-riscv-ocaml
#COPY ./riscv-ocaml /riscv-ocaml

WORKDIR /riscv-ocaml

# Checkout code before the inline assembly updates 
RUN git checkout 88b3b40c87f7d2c239620a04bdf715ab3abdf7c3  
RUN ./configure -no-ocamldoc -no-debugger -prefix /riscv-ocaml && make -j4 world.opt && make install 
ENV PATH="/riscv-ocaml/bin:${PATH}"
# Checkout the latest code with the inline assembly 
RUN git fetch 
RUN git checkout inline-cii 
RUN make clean && ./configure --target riscv64-unknown-linux-gnu -prefix /riscv-ocaml -no-ocamldoc -no-debugger -target-bindir /riscv-ocaml/bin && make -j4 world || /bin/true 
RUN make -j4 opt
RUN cp /riscv-ocaml/bin/ocamlrun byterun
RUN make install
RUN make clean 

WORKDIR /og-riscv-ocaml

# Install unmodified cross-compiler for testing changes
RUN git pull
RUN git checkout o2-optimised 
RUN ./configure -no-ocamldoc -no-debugger -prefix /og-riscv-ocaml && make -j4 world.opt && make install 
ENV PATH="/og-riscv-ocaml/bin:${PATH}"
RUN make clean && ./configure --target riscv64-unknown-linux-gnu -prefix /og-riscv-ocaml -no-ocamldoc -no-debugger -target-bindir /og-riscv-ocaml/bin && make -j4 world || /bin/true 
RUN make -j4 opt
RUN cp /og-riscv-ocaml/bin/ocamlrun byterun
RUN make install 

# Clean up
RUN make clean

# Opam and x86 compiler (with cross-compiling capabilities)
RUN apt-add-repository ppa:avsm/ppa -y
RUN apt update 
RUN apt install -y opam
RUN opam --version
RUN opam init --disable-sandboxing --compiler=4.07.0 -y 
RUN eval $(opam env)
RUN opam repo add cross git+https://github.com/patricoferris/opam-cross-shakti.git
RUN opam install dune core -y 

WORKDIR /tmp
RUN git clone https://github.com/patricoferris/riscv-benchmarks.git

ENV RISCV /usr/local
ENV LD_LIBRARY_PATH=$RISCV/lib
ENV pk=$RISCV/riscv64-unknown-elf/bin/pk

WORKDIR /
ENTRYPOINT ["/bin/bash"]
