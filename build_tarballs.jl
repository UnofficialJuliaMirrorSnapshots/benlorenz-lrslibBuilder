# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "lrslib"
version = v"7.0"
versionstr = "070"

# Collection of sources required to build lrslibBuilder
sources = [
    "http://cgm.cs.mcgill.ca/~avis/C/lrslib/archive/lrslib-$versionstr.tar.gz" =>
    "e9f12b29be89b3ad6984f3a9cf83f5776ac06edc57b0716649e63395e5ac4dfe",
]

# Bash recipe for building across all platforms
script = raw"""
cd lrslib-070
extraargs=""
cflags="-O3 -Wall"

# 32bit linux, arm and windows:
if [[ $target == i686* ]] || [[ $target == arm* ]]; then
# no 128 bit ... patch makefile
sed -i -e 's#lrs-shared: ${SHLINK} lrs.o#lrs-shared: ${SHLINK} lrs64.o#' makefile
sed -i -e 's#$(CC) lrs.o -o $@ -L . -llrs#$(CC) lrs64.o -o $@ -L . -llrs#' makefile
sed -i -e 's#redund-shared: ${SHLINK}  redund.o#redund-shared: ${SHLINK}  redund64.o#' makefile
sed -i -e 's#$(CC) redund.o -o $@ -L . -llrs#$(CC) redund64.o -o $@ -L . -llrs#' makefile
sed -i -e 's#SHLIBOBJ=lrslong1-shr.o lrslong2-shr.o lrslib1-shr.o lrslib2-shr.o#SHLIBOBJ=lrslong1-shr.o lrslib1-shr.o#' makefile
fi

if [[ $target == *apple* ]]; then
sed -i -e 's#-Wl,-soname=#-install_name #' makefile
extraargs="SONAME=liblrs.0.dylib SHLINK=liblrs.dylib SHLIB=liblrs.0.0.0.dylib"
elif [[ $target == *freebsd* ]]; then
export CC="$CC $LDFLAGS"
elif [[ $target == *mingw* ]]; then
extraargs="SONAME=liblrs.0.dll SHLINK=liblrs.dll SHLIB=liblrs.0.0.0.dll"
cflags="$cflags -DSIGNALS -DTIMES"
fi

make prefix=$prefix INCLUDEDIR=$prefix/include LIBDIR=$prefix/lib CFLAGS="$cflags" $extraargs install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()

# The products that we will ensure are always built
products(prefix) = [
    LibraryProduct(prefix, "liblrs", :liblrs)
    ExecutableProduct(prefix, "lrs", :lrs)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/GMP-v6.1.2-1/build_GMP.v6.1.2.jl"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)
