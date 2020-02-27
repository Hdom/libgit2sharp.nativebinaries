#!/bin/bash

set -e

LIBGIT2SHA=`cat ./nuget.package/libgit2/libgit2_hash.txt`
SHORTSHA=${LIBGIT2SHA:0:7}

rm -rf libssh2/build
mkdir libssh2/build
pushd libssh2/build
export _BINPATH=`pwd`
cmake -DCMAKE_BUILD_TYPE:STRING=Release \
      -DCMAKE_C_FLAGS=-fPIC \
      -DBUILD_SHARED_LIBS=OFF \
      -DENABLE_ZLIB_COMPRESSION=ON \
      -DCMAKE_OSX_ARCHITECTURES="i386;x86_64" \
      ..
cmake --build .
popd


rm -rf libgit2/build
mkdir libgit2/build
pushd libgit2/build

export _BINPATH=`pwd`

if [[ $RID == *arm64 ]]; then
	export TOOLCHAIN_FILE=/nativebinaries/CMakeLists.arm64.txt
fi
# NOTE: we set USE_SSH=OFF to prevent cmake from searching for a system libssh2 package
# instead, we specifically locate the libssh2 built above
cmake -DCMAKE_BUILD_TYPE:STRING=Release \
      -DBUILD_CLAR:BOOL=OFF \
      -DUSE_SSH=OFF \
      -DGIT_SSH_MEMORY_CREDENTIALS=ON \
      -DLIBSSH2_FOUND=ON \
      -DLIBSSH2_INCLUDE_DIRS="/nativebinaries/libssh2/include" \
      -DLIBSSH2_LIBRARIES="/nativebinaries/libssh2/build/src/libssh2.a" \
      -DENABLE_TRACE=ON \
      -DLIBGIT2_FILENAME=git2-$SHORTSHA \
      -DCMAKE_OSX_ARCHITECTURES="i386;x86_64" \
      -DUSE_BUNDLED_ZLIB=ON \
      -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE} \
      ..
cmake --build .

popd

OS=`uname`
ARCH=`uname -m`

PACKAGEPATH="nuget.package/runtimes"

if [[ $RID == "" ]]; then
	if [[ $ARCH == "x86_64" ]]; then
		RID="unix-x64"
	else
		RID="unix-x86"
	fi
	echo "$(tput setaf 3)RID not defined. Falling back to '$RID'.$(tput sgr0)"
fi

if [[ $OS == "Darwin" ]]; then
	LIBEXT="dylib"
else
	LIBEXT="so"
fi

rm -rf $PACKAGEPATH/$RID
mkdir -p $PACKAGEPATH/$RID/native

cp libgit2/build/libgit2-$SHORTSHA.$LIBEXT $PACKAGEPATH/$RID/native
