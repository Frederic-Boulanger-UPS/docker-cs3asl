#!/bin/sh
cat build_alt-ergo.sh | docker run --rm --interactive --privileged --volume `pwd`:/workspace:rw --entrypoint "bash" ubuntu:20.04
