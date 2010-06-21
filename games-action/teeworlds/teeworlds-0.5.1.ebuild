# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

inherit toolchain-funcs eutils games

BAM_P="bam-0.2.0"
DESCRIPTION="Online 2D platform shooter."
HOMEPAGE="http://www.teeworlds.com"
SRC_URI="http://www.teeworlds.com/files/${P}-src.tar.gz -> ${P}-src.tar.gz
    http://teeworlds.com/trac/bam/browser/releases/bam-0.2.0.tar.gz?format=raw
    -> ${BAM_P}.tar.gz"

LICENSE="as-is"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="dedicated"

RDEPEND="dev-lang/lua
    !dedicated? (
        media-libs/libsdl[X,alsa,opengl]
        sys-libs/zlib
    )"
# has modified wavpack and pnglite in its sources
# not worth of effort patching up to system ones
DEPEND="${RDEPEND}
    app-arch/zip"

S=${WORKDIR}/${P}-src
# that's a temporary fix for datadir location
dir=${GAMES_DATADIR}/${PN}

src_prepare() {
    rm -f license.txt
}

src_compile() {
    # compile bam
    ebegin "Preparing BAM"
    cd "${WORKDIR}/${BAM_P}"
    $(tc-getCC) ${CFLAGS} src/tools/txt2c.c -o src/tools/txt2c || die
    src/tools/txt2c src/base.bam src/driver_gcc.bam \
    src/driver_cl.bam > src/internal_base.h || die
    # internal lua sources!
    $(tc-getCC) ${CFLAGS} ${LDFLAGS} \
        src/lua/*.c src/*.c -o src/bam \
        -I /usr/include/ -lm -lpthread || die
    eend $?
    # compile game
    cd "${S}"
    sed -i \
        -e "s|cc.flags = \"-Wall -pedantic-errors\"|cc.flags = \"${CXXFLAGS}\"|" \
        -e "s|linker.flags = \"\"|linker.flags = \"${LDFLAGS}\"|" \
        -e "s|-Wall -fstack-protector -fstack-protector-all -fno-exceptions|${CXXFLAGS}|" \
        default.bam || die "sed failed"

    if use dedicated ; then
        ../${BAM_P}/src/bam -v server_release || die "bam failed"
    else
        ../${BAM_P}/src/bam -v release || die "bam failed"
    fi
}

src_install() {
    exeinto "${dir}"
    doexe ${PN}_srv || die "dogamesbin failed"

    if ! use dedicated ; then
        doexe ${PN} || die "dogamesbin failed"
        newicon other/icons/Teeworlds.ico ${PN}.ico
        games_make_wrapper ${PN} "./${PN}" "${dir}"
        make_desktop_entry ${PN} "Teeworlds"
        insinto "${dir}"
        doins -r data || die "doins failed"
    else
        insinto "${dir}"/data/maps
        doins data/maps/* || die "doins failed"
    fi

    dodoc *.txt
    prepgamesdirs
}
