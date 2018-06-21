#!/bin/bash
#
# Copyright (c) 2016-2018 Alireza Kheirkhahan
#
# Distributed under the Boost Software License, Version 1.0. (See accompanying
# file BOOST_LICENSE_1_0.rst or copy at http://www.boost.org/LICENSE_1_0.txt)

usage()
{
    echo "Usage: $0 -p install directory -v version [args]"
    echo
    echo "This script downloads and builds GCC."
    echo
    echo "Options:"
    echo "  -p    Prefix: the directory where gcc should be installed [default: /opt/mn/gcc/<version>]"
    echo "  -v    Version of GCC to build (format: X.Y.Z)"
    echo "  -t    Number of threads to use while building [default: 4]"
    echo "  -b    The build directory [default: /dev/shm]"
    echo "  -m    The Module directory [default: /opt/modules]"
}

BUILD_DIRECTORY=/dev/shm
VERSION=6.1.0
THREADS=4
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
if [ -z "$PREFIX" ]; then PREFIX=/opt/mn/gcc/$VERSION; fi

cleanup()
{
    cd $ORIGINAL_DIRECTORY
    if [[ -d $BUILD_DIRECTORY/gcc-$VERSION && -w $BUILD_DIRECTORY/gcc-$VERSION ]];
    then
        rm -rf $BUILD_DIRECTORY/gcc-$VERSION
    fi
}

error()
{
    cleanup
    exit 1
}

cd $BUILD_DIRECTORY
mkdir gcc-$VERSION
cd gcc-$VERSION

wget http://ftpmirror.gnu.org/gcc/gcc-$VERSION/gcc-$VERSION.tar.gz
    if ! [[ $? == "0" ]]; then echo "ERROR: Unable to download GCC"; error; fi

tar --no-same-owner -xf gcc-$VERSION.tar.gz
if ! [[ $? == "0" ]]; then echo "ERROR: Unable to unpack `pwd`/gcc-$VERSION.tar.gz"; error; fi

mv gcc-$VERSION source
cd source

# Downloading isl, mpfr and otter prerequisites
contrib/download_prerequisites 

./configure \
--prefix=$PREFIX \
--with-pkgversion=`date +'%Y%m%d'` \
--enable-bootstrap \
--enable-shared \
--enable-threads=posix \
--enable-checking=release \
--enable-multilib \
--enable-languages=c,c++,fortran,lto \
--enable-plugin \
--with-linker-hash-style=gnu \
--disable-libunwind-exceptions \
--enable-gnu-unique-object \
--enable-__cxa_atexit \
--enable-initfini-array \
--disable-libgcj \
--enable-linker-build-id \
--enable-gnu-indirect-function \
--with-tune=generic \
--with-arch_32=i686 \
--build=x86_64-redhat-linux 

make -j${THREADS}
if ! [[ $? == "0" ]]; then echo "ERROR: failed to build GCC"; error; fi

make install 

cleanup

#######################################################
# Creating the Module file
if [ ! -d $MODULE_DIRECTORY/gcc ]; 
   then mkdir $MODULE_DIRECTORY/gcc; fi
if [ -f $MODULE_DIRECTORY/gcc/$VERSION ]
   then rm $MODULE_DIRECTORY/gcc/$VERSION; fi

echo "#%Module" >> $MODULE_DIRECTORY/gcc/$VERSION
echo "# Generated by gcc_build.sh" >> $MODULE_DIRECTORY/gcc/$VERSION
echo "proc ModulesHelp { } {" >> $MODULE_DIRECTORY/gcc/$VERSION
echo "    puts stderr { The GNU Compiler Collection includes front ends for C, C++, Fortran, " >> $MODULE_DIRECTORY/gcc/$VERSION
echo " as well as libraries for these languages (libstdc++, libgcj,...). - Homepage: http://gcc.gnu.org/" >> $MODULE_DIRECTORY/gcc/$VERSION
echo "    }" >> $MODULE_DIRECTORY/gcc/$VERSION
echo "}" >> $MODULE_DIRECTORY/gcc/$VERSION
echo "" >> $MODULE_DIRECTORY/gcc/$VERSION
echo "module-whatis {Description: The GNU Compiler Collection includes front ends for C, C++, Fortran, " >> $MODULE_DIRECTORY/gcc/$VERSION
echo " as well as libraries for these languages (libstdc++, libgcj,...). - Homepage: http://gcc.gnu.org/}" >> $MODULE_DIRECTORY/gcc/$VERSION

echo "" >> $MODULE_DIRECTORY/gcc/$VERSION
echo "set root $PREFIX" >> $MODULE_DIRECTORY/gcc/$VERSION

echo "" >> $MODULE_DIRECTORY/gcc/$VERSION
echo "conflict gcc" >> $MODULE_DIRECTORY/gcc/$VERSION

echo "if { ![is-loaded binutils/2.30] } {" >> $MODULE_DIRECTORY/gcc/$VERSION
echo "    module load binutils/2.30" >> $MODULE_DIRECTORY/gcc/$VERSION
echo "}" >> $MODULE_DIRECTORY/gcc/$VERSION

echo "" >> $MODULE_DIRECTORY/gcc/$VERSION
echo "prepend-path    CPATH           \$root/include" >> $MODULE_DIRECTORY/gcc/$VERSION
echo "prepend-path    LD_LIBRARY_PATH        \$root/lib" >> $MODULE_DIRECTORY/gcc/$VERSION
echo "prepend-path    LD_LIBRARY_PATH         \$root/lib64" >> $MODULE_DIRECTORY/gcc/$VERSION
echo "prepend-path    LD_LIBRARY_PATH         \$root/lib/gcc/x86_64-redhat-linux/$VERSION" >> $MODULE_DIRECTORY/gcc/$VERSION
echo "prepend-path    LIBRARY_PATH            \$root/lib" >> $MODULE_DIRECTORY/gcc/$VERSION
echo "prepend-path    LIBRARY_PATH            \$root/lib64" >> $MODULE_DIRECTORY/gcc/$VERSION
echo "prepend-path    MANPATH         \$root/share/man" >> $MODULE_DIRECTORY/gcc/$VERSION
echo "prepend-path    PATH            \$root/bin" >> $MODULE_DIRECTORY/gcc/$VERSION
echo "setenv	      CC      \$root/bin/gcc" >> $MODULE_DIRECTORY/gcc/$VERSION
echo "setenv  	      CXX     \$root/bin/g++" >> $MODULE_DIRECTORY/gcc/$VERSION

