#!/usr/bin/env bash

cd /tmp

cat > debian10.def <<EOF
Bootstrap: docker
From: debian:10
%post
  apt update -y
  apt install -y zsh
  mkdir -p /etc/slurm /var/run/munge /var/spool/slurm /var/lib/sss/pipes/nss /cvmfs
EOF

test -f debian10.sif \
        || singularity build --fakeroot debian10.sif debian10.def

cat > centos7.def <<EOF
Bootstrap: docker
From: centos:7
%post
  yum install -y zsh
  mkdir -p /etc/slurm /var/run/munge /var/spool/slurm /var/lib/sss/pipes/nss /cvmfs
EOF

test -f centos7.sif \
        || singularity build --fakeroot centos7.sif centos7.def

cd - >/dev/null
