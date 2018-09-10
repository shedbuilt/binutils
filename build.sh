#!/bin/bash
declare -A SHED_PKG_LOCAL_OPTIONS=${SHED_PKG_OPTIONS_ASSOC}
# Patch
patch -Np1 -i "${SHED_PKG_PATCH_DIR}/binutils-2.31.1-commonpagesize.patch" || exit 1
# Configure, Build and Install
mkdir -v build
cd build
if [ -n "${SHED_PKG_LOCAL_OPTIONS[toolchain]}" ]; then
    if [ "$SHED_BUILD_HOST" != "$SHED_NATIVE_TARGET" ] && [ "$SHED_BUILD_TARGET" == "$SHED_NATIVE_TARGET" ]; then
        CC=${SHED_BUILD_HOST}-gcc         \
        AR=${SHED_BUILD_HOST}-ar          \
        RANLIB=${SHED_BUILD_HOST}-ranlib  \
        ../configure --prefix=/tools            \
                     --disable-nls              \
                     --disable-werror           \
                     --with-lib-path=/tools/lib \
                     --with-sysroot &&
        make -j $SHED_NUM_JOBS &&
        make DESTDIR="$SHED_FAKE_ROOT" install &&
        make -C ld clean &&
        make -C ld LIB_PATH=/usr/lib:/lib &&
        cp -v ld/ld-new /tools/bin || exit 1
    elif [ "$SHED_BUILD_TARGET" != "$SHED_NATIVE_TARGET" ]; then
        ../configure --prefix=/tools                   \
                     --with-sysroot="$SHED_INSTALL_ROOT" \
                     --with-lib-path=/tools/lib        \
                     --target=$SHED_BUILD_TARGET       \
                     --disable-nls                     \
                     --disable-werror &&
        make -j $SHED_NUM_JOBS || exit 1
        if [[ $SHED_BUILD_TARGET =~ ^aarch64-.* ]]; then
            mkdir -pv "${SHED_FAKE_ROOT}/tools/lib" &&
            ln -sv lib "${SHED_FAKE_ROOT}/tools/lib64" || exit 1
        fi
        make DESTDIR="$SHED_FAKE_ROOT" install
    else
        echo "Unsupported configuration for toolchain build"
        exit 1
    fi
else
    ../configure --prefix=/usr       \
                 --enable-gold       \
                 --enable-ld=default \
                 --enable-plugins    \
                 --enable-shared     \
                 --disable-werror    \
                 --enable-64-bit-bfd \
                 --with-system-zlib &&
    make tooldir=/usr -j $SHED_NUM_JOBS &&
    make DESTDIR="$SHED_FAKE_ROOT" tooldir=/usr install
fi
