## Setup variables to avoid input for timezone settings
export DEBIAN_FRONTEND=noninteractive TZ=Europe/Paris

# Fix issue with libGL on Windows
export LIBGL_ALWAYS_INDIRECT=1

# Update and upgrade apt software
# Install some necessary stuff to get and build programs
apt-get update && apt-get upgrade -y && apt-get install -y x11-apps nano python3-pip wget

# Build Z3 4.8.17
wget https://github.com/Z3Prover/z3/archive/refs/tags/z3-4.11.0.tar.gz
tar zxf z3-4.11.0.tar.gz
cd z3-z3-4.11.0
PYTHON=python3 ./configure --prefix=/usr/local
cd build
make
make install
cd ../..
rm -r z3-*

# Build E prover
# Old 2.0 version at http://wwwlehre.dhbw-stuttgart.de/~sschulz/WORK/E_DOWNLOAD/V_2.0/E.tgz
wget http://wwwlehre.dhbw-stuttgart.de/~sschulz/WORK/E_DOWNLOAD/V_2.6/E.tgz
tar zxf E.tgz
cd E
./configure --prefix=/usr/local
make
make install
cd ..
rm -r E E.tgz

# Build Soufflé
apt-get install -y cmake autoconf bison doxygen flex g++ \
				   git libffi-dev libncurses5-dev libtool libsqlite3-dev mcpp \
				   sqlite
wget https://github.com/souffle-lang/souffle/archive/refs/tags/2.3.tar.gz
tar zxf 2.3.tar.gz && rm 2.3.tar.gz
cd souffle-2.3
cmake -S . -B build -DCMAKE_INSTALL_PREFIX=/usr/souffle/
cmake --build build --target install
cd ..
rm -r souffle-2.3
tar zcCf /usr/souffle souffle-2.3.tgz .

# Compute the name of the architecture
arch=`uname -m`; if [[ $arch == "x86_64" ]]; then arch="amd64"; elif [[ $arch == "aarch64" ]]; then arch="arm64"; fi
# Copy the built executables to the host
cp /usr/local/bin/z3 /workspace/z3_$arch
cp /usr/local/bin/eprover /workspace/eprover_$arch
cp /souffle-2.3.tgz /workspace/souffle-2.3_$arch.tgz
