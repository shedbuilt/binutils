#!/bin/bash
mkdir -v build
cd build
../configure --prefix=/usr       \
             --enable-gold       \
             --enable-ld=default \
             --enable-plugins    \
             --enable-shared     \
             --disable-werror    \
             --with-system-zlib
# PiLFS says that gold has issues with parallel jobs
make tooldir=/usr
make DESTDIR=$SHED_FAKEROOT tooldir=/usr install
