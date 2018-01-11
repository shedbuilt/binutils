#!/bin/bash
mkdir -v build
cd build
case "$SHED_BUILDMODE" in
    toolchain)
        if [ ! -d /tools/${SHED_TARGET} ]; then
            ../configure --prefix=/tools                  \
                         --with-sysroot=$SHED_INSTALLROOT \
                         --with-lib-path=/tools/lib       \
                         --target=$SHED_TARGET            \
                         --disable-nls                    \
                         --disable-werror || return 1
            make -j 1 || return 1
            make DESTDIR="$SHED_FAKEROOT" install || return 1
        else
            CC=$SHED_TARGET-gcc                     \
            AR=$SHED_TARGET-ar                      \
            RANLIB=$SHED_TARGET-ranlib              \
            ../configure --prefix=/tools            \
                         --disable-nls              \
                         --disable-werror           \
                         --with-lib-path=/tools/lib \
                         --with-sysroot || return 1
            make -j 1 || return 1
            make DESTDIR="$SHED_FAKEROOT" install || return 1
            make -C ld clean || return 1
            make -C ld LIB_PATH=/usr/lib:/lib || return 1
            cp -v ld/ld-new /tools/bin || return 1
        fi
    ;;
    *)
        ../configure --prefix=/usr       \
                     --enable-gold       \
                     --enable-ld=default \
                     --enable-plugins    \
                     --enable-shared     \
                     --disable-werror    \
                     --with-system-zlib || return 1
        # PiLFS says that gold has issues with parallel jobs
        make tooldir=/usr -j 1 || return 1
        make DESTDIR="$SHED_FAKEROOT" tooldir=/usr install || return 1
    ;;
esac
