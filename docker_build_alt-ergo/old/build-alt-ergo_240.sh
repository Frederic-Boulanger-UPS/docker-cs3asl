# For building alt-ergo 2.4.0
# In a docker container run with --privileged
export DEBIAN_FRONTEND=noninteractive
export TZ=Europe/Paris

apt-get update && apt-get upgrade -y
apt-get install -y wget
apt-get install -y liblablgtksourceview2-ocaml-dev libgmp-dev
apt-get install -y opam
opam init -y
eval $(opam env)
opam install -y dune dune-configurator
opam install -y camlzip cmdliner lablgtk psmt2-frontend stdlib-shims zarith
rm -rf /root/.opam/default/lib/num*
opam install -y ocplib-simplex

wget https://github.com/OCamlPro/alt-ergo/archive/2.4.0.tar.gz
tar zxf 2.4.0.tar.gz
cd alt-ergo-2.4.0/
# autoconf
./configure
make
arch=`uname -m`
arch=`if [ $arch = "x86_64" ]; then echo amd64; elif [ $arch = "aarch64" ]; then echo arm64; else echo $arch; fi`
cp _build/install/default/bin/alt-ergo /workspace/resources/altergo-240/alt-ergo_$arch
cp _build/install/default/bin/altgr-ergo /workspace/resources/altergo-240/altgr-ergo_$arch
