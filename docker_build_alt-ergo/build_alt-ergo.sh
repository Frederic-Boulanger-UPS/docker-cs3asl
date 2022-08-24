## Setup variables to avoid input for timezone settings
export DEBIAN_FRONTEND=noninteractive TZ=Europe/Paris
# Compute the name of the architecture
arch=`uname -m`; if [[ $arch == "x86_64" ]]; then arch="amd64"; elif [[ $arch == "aarch64" ]]; then arch="arm64"; fi
apt-get update && apt-get upgrade -y
apt-get install -y autoconf libgmp-dev pkg-config zlib1g-dev libexpat1-dev libgtk2.0-dev liblablgtksourceview2-ocaml-dev opam
opam init -y && eval $(opam env)
opam install -y dune dune-configurator zarith camlzip menhir ocplib-simplex seq cmdliner stdlib-shims psmt2-frontend lablgtk && eval $(opam env)
opam install alt-ergo -y
# # alt-ergo build fails, but we can repair it by hand
# cd ~/.opam/default/.opam-switch/build/alt-ergo-lib.2.4.1
# ./configure
# make
# cp alt-ergo /workspace/alt-ergo_$arch
# cp altgr-ergo /workspace/altgr-ergo_$arch
# Copy the built executables to the host
cp ~/.opam/default/bin/alt-ergo /workspace/alt-ergo_$arch
