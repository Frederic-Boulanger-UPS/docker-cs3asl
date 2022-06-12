#!/bin/sh
cat build_provers.sh | docker run --rm --interactive --privileged --volume `pwd`:/workspace:rw --entrypoint "bash" ubuntu:22.04
