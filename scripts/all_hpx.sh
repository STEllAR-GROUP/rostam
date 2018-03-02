#!/bin/bash
#
# Copyright (c) 2018 Alireza Kheirkhahan
#
# Distributed under the Boost Software License, Version 1.0. (See accompanying
# file BOOST_LICENSE_1_0.rst or copy at http://www.boost.org/LICENSE_1_0.txt)

BUILD_SCRIPT=`dirname $0`/hpx_build.sh
echo $BUILD_SCRIPT

# Build with gcc 7.3.0 and boost 1.66.0 in debug
$BUILD_SCRIPT -c gcc -v 7.3.0 -b 1.66.0

# Build with gcc 7.3.0 and boost 1.66.0 in release mode and no download
$BUILD_SCRIPT -n -c gcc -v 7.3.0 -b 1.66.0 -o release

# Build with clang 5.0.1 and boost 1.66.0 in debug mode and no download
$BUILD_SCRIPT -n -c clang -v 5.0.1 -f '-DCMAKE_CXX_FLAGS=-stdlib=libc++'

# Build with clang 5.0.1 and boost 1.66.0 in debug mode and no download
$BUILD_SCRIPT -n -c clang -v 5.0.1 -o release -f '-DCMAKE_CXX_FLAGS=-stdlib=libc++'
