#!/bin/bash
#
# $Id: build-modules-7.5.5.sh,v 1.1 2011/08/10 23:58:34 lavajoe Exp $
#
# This script builds all binary Perl modules required by Squeezebox Server.

DISTDIR="$1"; shift
D="$1"; shift

# Build dir
BUILD=$PWD

# Require modules to pass tests
RUN_TESTS=1

FLAGS=""

# $1 = module to build
# $2 = Makefile.PL arg(s)
function build_module {
    tar zxvf $DISTDIR/SqueezeboxServer-$1.tar.gz || exit 1
    cd $1
        
    perl Makefile.PL PREFIX=$D $2
    if [ $RUN_TESTS -eq 1 ]; then
        make test
    else
        make
    fi
    if [ $? != 0 ]; then
        if [ $RUN_TESTS -eq 1 ]; then
            echo "make test failed, aborting"
        else
            echo "make failed, aborting"
        fi
        exit $?
    fi
    make install || exit 1
    make clean || exit 1

    cd ..
    rm -rf $1
}

function build_all {
    export PERL_MM_USE_DEFAULT=1
    RUN_TESTS=0
    build_module EV-3.8
    RUN_TESTS=1
    export PERL_MM_USE_DEFAULT=
}

# Build a single module if requested, or all
if [ $1 ]; then
    build $1
else
    build_all
fi

# Reset PERL5LIB
export PERL5LIB=

# clean out useless .bs/.packlist files, etc
find $BUILD -name '*.bs' -exec rm -f {} \;
find $BUILD -name '*.packlist' -exec rm -f {} \;
