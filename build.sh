#!/bin/bash
mkdir -v build
cd build
case "$SHED_BUILDMODE" in
    toolchain)
        if [ "$SHED_HOST" == 'toolchain' ]; then
            CC=${SHED_TOOLCHAIN_TARGET}-gcc         \
            AR=${SHED_TOOLCHAIN_TARGET}-ar          \
            RANLIB=${SHED_TOOLCHAIN_TARGET}-ranlib  \
            ../configure --prefix=/tools            \
                         --disable-nls              \
                         --disable-werror           \
                         --with-lib-path=/tools/lib \
                         --with-sysroot || exit 1
            make -j 1 || exit 1
            make DESTDIR="$SHED_FAKEROOT" install || exit 1
            make -C ld clean || exit 1
            make -C ld LIB_PATH=/usr/lib:/lib || exit 1
            cp -v ld/ld-new /tools/bin || exit 1
        else
            ../configure --prefix=/tools                  \
                         --with-sysroot=$SHED_INSTALLROOT \
                         --with-lib-path=/tools/lib       \
                         --target=$SHED_NATIVE_TARGET     \
                         --disable-nls                    \
                         --disable-werror || exit 1
            make -j 1 || exit 1
            make DESTDIR="$SHED_FAKEROOT" install || exit 1
        fi
    ;;
    *)
        ../configure --prefix=/usr       \
                     --enable-gold       \
                     --enable-ld=default \
                     --enable-plugins    \
                     --enable-shared     \
                     --disable-werror    \
                     --with-system-zlib || exit 1
        # PiLFS says that gold has issues with parallel jobs
        make tooldir=/usr -j 1 || exit 1
        make DESTDIR="$SHED_FAKEROOT" tooldir=/usr install || exit 1
    ;;
esac
