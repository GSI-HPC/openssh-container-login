#!/usr/bin/env bash

cat > debian10.def <<EOF
Bootstrap: docker
From: debian:10
EOF

test -f debian10.sif \
        || singularity build debian10.sif debian10.def

cat > centos7.def <<EOF
Bootstrap: docker
From: centos:7
EOF

test -f centos7.sif \
        || singularity build centos7.sif centos7.def
