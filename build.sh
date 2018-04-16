#!/bin/bash
mkdir -v build
cd build
case "$SHED_BUILD_MODE" in
    toolchain)
        if [ "$SHED_BUILD_HOST" == 'toolchain' ] && [ "$SHED_BUILD_TARGET" == 'native' ]; then
            CC=${SHED_TOOLCHAIN_TARGET}-gcc         \
            AR=${SHED_TOOLCHAIN_TARGET}-ar          \
            RANLIB=${SHED_TOOLCHAIN_TARGET}-ranlib  \
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
        elif [ "$SHED_BUILD_TARGET" == 'toolchain' ]; then
            ../configure --prefix=/tools                  \
                         --with-sysroot=$SHED_INSTALL_ROOT \
                         --with-lib-path=/tools/lib       \
                         --target=$SHED_TOOLCHAIN_TARGET  \
                         --disable-nls                    \
                         --disable-werror &&
            make -j $SHED_NUM_JOBS || exit 1
            if [[ $SHED_TOOLCHAIN_TARGET =~ ^aarch64-.* ]]; then
                mkdir -v "${SHED_FAKE_ROOT}/tools/lib" &&
                ln -sv lib "${SHED_FAKE_ROOT}/tools/lib64" || exit 1
            fi
            make DESTDIR="$SHED_FAKE_ROOT" install || exit 1
        else
            echo "Unsupported configuration for toolchain build"
            exit 1
        fi
    ;;
    *)
        ../configure --prefix=/usr       \
                     --enable-gold       \
                     --enable-ld=default \
                     --enable-plugins    \
                     --enable-shared     \
                     --disable-werror    \
                     --with-system-zlib &&
        make tooldir=/usr -j $SHED_NUM_JOBS &&
        make DESTDIR="$SHED_FAKE_ROOT" tooldir=/usr install || exit 1
    ;;
esac
