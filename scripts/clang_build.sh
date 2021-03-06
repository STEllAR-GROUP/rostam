#!/bin/bash
#
# Copyright (c) 2016-2018 Alireza Kheirkhahan
#
# Distributed under the Boost Software License, Version 1.0. (See accompanying
# file BOOST_LICENSE_1_0.rst or copy at http://www.boost.org/LICENSE_1_0.txt)

usage()
{
    echo "Usage: $0 -p install directory -v version [args] "
    echo
    echo "This script downloads and builds llvm/clang."
    echo
    echo "Options:"
    echo "  -p    Prefix: the directory where clang should be installed [default: /opt/mn/clang/<version>]"
    echo "  -v    Version of llvm/clang to build (format: X.Y.Z)"
    echo "  -t    Number of threads to use while building [default: 4]"
    echo "  -b    The build directory [default: /dev/shm]"
    echo "  -m    The Module directory [default: /opt/modules]"
}

BUILD_DIRECTORY=/dev/shm
VERSION=6.0.0
THREADS=8
MODULE_DIRECTORY=/opt/modules

##########################################################
# Argument parsing
while getopts "ht:p:v:b:m:" OPTION; do case $OPTION in
    h)
        usage
        exit 0
        ;;
    t)
	if [[ $OPTARG =~ ^[0-9]+$ ]]; then
            THREADS=$OPTARG
        else
            echo "ERROR: -t argument was invalid"; echo
            usage
            exit 1
        fi
        ;;
    p)
	PREFIX=$OPTARG 
        ;;
    v)
	VERSION=$OPTARG
        ;;
    b)
	BUILD_DIRECTORY=$OPTARG
        ;;
    m)
        MODULE_DIRECTORY=$OPTARG
        ;;
    ?)
        usage
        exit 1
        ;;
esac; done
#########################################################
ORIGINAL_DIRECTORY=$PWD
if [ -z "$PREFIX" ]; then PREFIX=/opt/mn/clang/$VERSION; fi

cleanup()
{
    cd $ORIGINAL_DIRECTORY
    if [[ -d $BUILD_DIRECTORY/clang-$VERSION && -w $BUILD_DIRECTORY/clang-$VERSION ]];
    then
        rm -rf $BUILD_DIRECTORY/clang-$VERSION
    fi
}

error()
{
    cleanup
    exit 1
}

cd $BUILD_DIRECTORY
mkdir clang-$VERSION
cd clang-$VERSION

# Donwloading the Source:
# llvm
wget http://llvm.org/releases/$VERSION/llvm-$VERSION.src.tar.xz
    if ! [[ $? == "0" ]]; then echo "ERROR: Unable to download llvm"; error; fi

# clang
wget http://llvm.org/releases/$VERSION/cfe-$VERSION.src.tar.xz
    if ! [[ $? == "0" ]]; then echo "ERROR: Unable to download llvm"; error; fi

# compiler-rt
wget http://llvm.org/releases/$VERSION/compiler-rt-$VERSION.src.tar.xz
    if ! [[ $? == "0" ]]; then echo "ERROR: Unable to download llvm"; error; fi

# libc++
wget http://llvm.org/releases/$VERSION/libcxx-$VERSION.src.tar.xz
    if ! [[ $? == "0" ]]; then echo "ERROR: Unable to download llvm"; error; fi

# libc++abi
wget http://llvm.org/releases/$VERSION/libcxxabi-$VERSION.src.tar.xz
    if ! [[ $? == "0" ]]; then echo "ERROR: Unable to download llvm"; error; fi

# OpenMP
wget http://llvm.org/releases/$VERSION/openmp-$VERSION.src.tar.xz
    if ! [[ $? == "0" ]]; then echo "ERROR: Unable to download llvm"; error; fi

# LLVM Test Suite
wget http://llvm.org/releases/$VERSION/test-suite-$VERSION.src.tar.xz
    if ! [[ $? == "0" ]]; then echo "ERROR: Unable to download llvm"; error; fi

# LLD
wget http://llvm.org/releases/$VERSION/lld-$VERSION.src.tar.xz
    if ! [[ $? == "0" ]]; then echo "ERROR: Unable to download llvm"; error; fi

# LLDB
wget http://llvm.org/releases/$VERSION/lldb-$VERSION.src.tar.xz
    if ! [[ $? == "0" ]]; then echo "ERROR: Unable to download llvm"; error; fi

# Extracting the Source:
echo "Unpacking the source files ..."

tar --no-same-owner -xf llvm-$VERSION.src.tar.xz
if ! [[ $? == "0" ]]; then echo "ERROR: Unable to unpack `pwd`/llvm-$VERSION.src.tar.xz"; error; fi

mv llvm-$VERSION.src llvm
cd llvm/tools/
tar --no-same-owner -xf ../../cfe-$VERSION.src.tar.xz
if ! [[ $? == "0" ]]; then echo "ERROR: Unable to unpack `pwd`/cfe-$VERSION.src.tar.xz"; error; fi
mv cfe-$VERSION.src/ clang

tar --no-same-owner -xf ../../lld-$VERSION.src.tar.xz
if ! [[ $? == "0" ]]; then echo "ERROR: Unable to unpack `pwd`/lld-$VERSION.src.tar.xz"; error; fi

tar --no-same-owner -xf ../../lldb-$VERSION.src.tar.xz
if ! [[ $? == "0" ]]; then echo "ERROR: Unable to unpack `pwd`/lldb-$VERSION.src.tar.xz"; error; fi

cd ../projects/

tar --no-same-owner -xf ../../compiler-rt-$VERSION.src.tar.xz
if ! [[ $? == "0" ]]; then echo "ERROR: Unable to unpack `pwd`/compiler-rt-$VERSION.src.tar.xz"; error; fi
mv compiler-rt-$VERSION.src/ compiler-rt

tar --no-same-owner -xf ../../libcxx-$VERSION.src.tar.xz
if ! [[ $? == "0" ]]; then echo "ERROR: Unable to unpack `pwd`/libcxx-$VERSION.src.tar.xz"; error; fi
mv libcxx-$VERSION.src/ libcxx

tar --no-same-owner -xf ../../libcxxabi-$VERSION.src.tar.xz
if ! [[ $? == "0" ]]; then echo "ERROR: Unable to unpack `pwd`/libcxxabi-$VERSION.src.tar.xz"; error; fi
mv libcxxabi-$VERSION.src/ libcxxabi

tar --no-same-owner -xf ../../openmp-$VERSION.src.tar.xz
if ! [[ $? == "0" ]]; then echo "ERROR: Unable to unpack `pwd`/openmp-$VERSION.src.tar.xz"; error; fi
mv openmp-$VERSION.src/ openmp

tar --no-same-owner -xf ../../test-suite-$VERSION.src.tar.xz
if ! [[ $? == "0" ]]; then echo "ERROR: Unable to unpack `pwd`/test-suite-$VERSION.src.tar.xz"; error; fi
mv test-suite-$VERSION.src/ test-suite

cd $BUILD_DIRECTORY/clang-$VERSION/llvm
mkdir build
cd build

cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$PREFIX -DLLDB_DISABLE_PYTHON=1 ..

make -j${THREADS}
if ! [[ $? == "0" ]]; then echo "ERROR: failed to build Clang"; error; fi

make install 

cleanup

#######################################################
# Creating the Module file
if [ ! -d $MODULE_DIRECTORY/clang ]; 
   then mkdir $MODULE_DIRECTORY/clang; fi
if [ -f $MODULE_DIRECTORY/clang/$VERSION ]
   then rm $MODULE_DIRECTORY/clang/$VERSION; fi

echo "#%Module" >> $MODULE_DIRECTORY/clang/$VERSION
echo "# Generated by clang_build.sh" >> $MODULE_DIRECTORY/clang/$VERSION
echo "proc ModulesHelp { } {" >> $MODULE_DIRECTORY/clang/$VERSION
echo "    puts stderr { The LLVM compiler infrastructure supports a wide range of projects, from industrial strength compilers to specialized JIT applications to small research projects. - Homepage: http://llvm.org/" >> $MODULE_DIRECTORY/clang/$VERSION
echo "    }" >> $MODULE_DIRECTORY/clang/$VERSION
echo "}" >> $MODULE_DIRECTORY/clang/$VERSION
echo "" >> $MODULE_DIRECTORY/clang/$VERSION
echo "module-whatis {Description: The LLVM compiler infrastructure supports a wide range of projects, from industrial strength compilers to specialized JIT applications to small research projects. - Homepage: http://llvm.org/}" >> $MODULE_DIRECTORY/clang/$VERSION

echo "" >> $MODULE_DIRECTORY/clang/$VERSION
echo "set root $PREFIX" >> $MODULE_DIRECTORY/clang/$VERSION

echo "" >> $MODULE_DIRECTORY/clang/$VERSION
echo "conflict clang" >> $MODULE_DIRECTORY/clang/$VERSION

echo "if { ![is-loaded binutils/2.30] } {" >> $MODULE_DIRECTORY/clang/$VERSION
echo "    module load binutils/2.30" >> $MODULE_DIRECTORY/clang/$VERSION
echo "}" >> $MODULE_DIRECTORY/clang/$VERSION

echo "" >> $MODULE_DIRECTORY/clang/$VERSION
echo "prepend-path    CPATH           \$root/include" >> $MODULE_DIRECTORY/clang/$VERSION
echo "prepend-path    LD_LIBRARY_PATH        \$root/lib" >> $MODULE_DIRECTORY/clang/$VERSION
echo "prepend-path    LD_LIBRARY_PATH        \$root/lib/clang/$VERSION/lib/linux" >> $MODULE_DIRECTORY/clang/$VERSION
echo "prepend-path    LIBRARY_PATH            \$root/lib" >> $MODULE_DIRECTORY/clang/$VERSION
echo "prepend-path    MANPATH         \$root/share/man" >> $MODULE_DIRECTORY/clang/$VERSION
echo "prepend-path    PATH            \$root/bin" >> $MODULE_DIRECTORY/clang/$VERSION
echo "prepend-path    PATH            \$root/libexec" >> $MODULE_DIRECTORY/clang/$VERSION
echo "" >> $MODULE_DIRECTORY/clang/$VERSION
echo "setenv  CC         \$root/bin/clang" >> $MODULE_DIRECTORY/clang/$VERSION
echo "setenv  CXX        \$root/bin/clang++" >> $MODULE_DIRECTORY/clang/$VERSION
echo "setenv  CXXFLAGS 	 -stdlib=libc++" >> $MODULE_DIRECTORY/clang/$VERSION
