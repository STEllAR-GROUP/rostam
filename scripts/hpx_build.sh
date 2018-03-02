#!/bin/bash
#
# Copyright (c) 2018 Alireza Kheirkhahan
#
# Distributed under the Boost Software License, Version 1.0. (See accompanying
# file BOOST_LICENSE_1_0.rst or copy at http://www.boost.org/LICENSE_1_0.txt)

usage()
{
    echo "Usage: $0 -d directory -v version [args]"
    echo
    echo "This script downloads and builds the HPX."
    echo
    echo "Options:"
    echo "  -d    HPX Build Directory [default: /dev/shm/hpx/version-buildtype-compiler]"
    echo "  -s    HPX Source Directory [default: /dev/shm/hpx/source]"
    echo "  -p    Install PREFIX [default: /opt/hpx/version-buildtype-compiler]"
    echo "  -n    Don't download HPX (expects source is available -s directory)"
    echo "  -t    Number of threads to use while building [default: number of processors]" 
    echo "  -c    Compiler: gcc or clang [default: gcc]"
    echo "  -v    Compiler version [default: 7.3]"
    echo "  -o    build type, debug or release [default: debug]"
    echo "  -b    Boost version [default: 1.66.0]"
    echo "  -m    The Module directory [default: /opt/hpx/modules]"
    echo "  -w    The Module filename [default: version-buildtype-compiler]"
    echo "  -f    other cmake flags, ie '-DCMAKE_CXX_FLAGS=-stdlib=libc++' "
}

SOURCE_DIRECTORY=/dev/shm/hpx/source
COMPILER=gcc
VERSION=7.3.0
THREADS=`grep -c ^processor /proc/cpuinfo`
MODULE_DIRECTORY=/opt/hpx/modules
DOWNLOAD=1
BUILD_TYPE=debug
BOOT_VERSTION=1.66.0

##########################################################
# Argument parsing
while getopts "hnd:s:p:t:c:v:o:b:m:f:" OPTION; do case $OPTION in
    h)
        usage
        exit 0
        ;;
    n)
        DOWNLOAD=0
        ;;    
    d)
        BUILD_DIRECTORY=$OPTARG
        ;;
    s)
        SOURCE_DIRECTORY=$OPTARG
        ;;
    p)
        PREFIX=$OPTARG 
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
    c)
        COMPILER=$OPTARG
        ;;
    v)
        VERSION=$OPTARG
        ;;
    o)
        BUILD_TYPE=$OPTARG
        ;;
    b)
        BOOT_VERSTION=$OPTARG
        ;;    
    m)
        MODULE_DIRECTORY=$OPTARG
        ;;
    w)
        MODULE_WORD=$OPTARG
        ;;
    f)
        CMAKE_FLAGS=$OPTARG
        ;;
    ?)
        usage
        exit 1
        ;;
esac; done
#########################################################
# ORIGINAL_DIRECTORY=$PWD
# ORIGINAL_LOADEDMODULES=$LOADEDMODULES
# cleanup()
# {
#     cd $ORIGINAL_DIRECTORY
#     for m in $(echo $ORIGINAL_LOADEDMODULES | sed "s/:/ /g")
# do
#     module load $m
# done
# }

error()
{
    # cleanup
    exit 1
}

if [ -z "$MODULE_WORD" ]; then MODULE_WORD=master-$BUILD_TYPE-$COMPILER$VERSION; fi
if [ -z "$PREFIX" ]; then PREFIX=/opt/hpx/$MODULE_WORD; fi
if [ -z "$BUILD_DIRECTORY" ]; then BUILD_DIRECTORY=/dev/shm/hpx/$MODULE_WORD; fi

if [[ $DOWNLOAD == "1" ]]; then
    if [[ -d $SOURCE_DIRECTORY && -w $SOURCE_DIRECTORY ]];
    then
        rm -rf $SOURCE_DIRECTORY
    fi
    git clone --depth 1 https://github.com/STEllAR-GROUP/hpx.git $SOURCE_DIRECTORY;
    if ! [[ $? == "0" ]]; then echo "ERROR: Unable to download HPX"; error; fi
fi
SOURCE_DIRECTORY=$(cd $SOURCE_DIRECTORY; pwd)

if [ ! -d $BUILD_DIRECTORY ]; 
    then mkdir -p $BUILD_DIRECTORY/; fi

cd $BUILD_DIRECTORY
rm -rf *
if [ -d $PREFIX ];
    then rm -rf $PREFIX; fi

echo $$LOADEDMODULES
module purge;
module load cmake/3.9.0;
module load $COMPILER/$VERSION
module load boost/$BOOT_VERSTION-$COMPILER$VERSION-$BUILD_TYPE
module load mpi/mpich-3.2-x86_64
module load PAPI/5.6.0
echo $$LOADEDMODULES

cmake \
    -DHPX_WITH_THREAD_IDLE_RATES=ON \
    -DHPX_WITH_PARCELPORT_MPI=ON \
    -DHPX_WITH_PAPI=On \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    $SOURCE_DIRECTORY

