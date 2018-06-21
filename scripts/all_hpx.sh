#!/bin/bash
#
# Copyright (c) 2018 Alireza Kheirkhahan
#
# Distributed under the Boost Software License, Version 1.0. (See accompanying
# file BOOST_LICENSE_1_0.rst or copy at http://www.boost.org/LICENSE_1_0.txt)

BUILD_SCRIPT=`dirname $0`/hpx_build.sh

# Build with gcc 8.1.0 and boost 1.67.0 in debug
$BUILD_SCRIPT -c gcc -v 8.1.0 -b 1.67.0

# Build with gcc 8.1.0 and boost 1.67.0 in release mode and no download
$BUILD_SCRIPT -n -c gcc -v 8.1.0 -b 1.67.0 -o release

# Build with clang 6.0.0 and boost 1.67.0 in debug mode and no download
$BUILD_SCRIPT -n -c clang -v 6.0.0 -b 1.67.0 -f '-DCMAKE_CXX_FLAGS=-stdlib=libc++'

# Build with clang 6.0.0 and boost 1.67.0 in debug mode and no download
$BUILD_SCRIPT -n -c clang -v 6.0.0 -o release -b 1.67.0 -f '-DCMAKE_CXX_FLAGS=-stdlib=libc++'
