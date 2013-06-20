#!/bin/bash

# important: you need to use the most general CFLAGS to build the packages:
#  * for x86  : CFLAGS="-march=i586 -mtune=generic -O2 -pipe -g"
#  * for amd64: CFLAGS="-march=x86-64 -mtune=generic -O2 -pipe -g"

# What you can set:
VERSION="3.6.6.2"
BINVERSION="3.6.6.2"
OPTS="-v"
USEFILE="/etc/portage/package.use/libreo"
MYPKGDIR="$( portageq pkgdir )"
################################################

die() {
        echo "${1}"
        exit 1
}

if [ "$( uname -m )" = "x86_64" ] ; then
	MYFLAGS="-march=x86-64 -mtune=generic -O2 -pipe -g"
	ARCH="amd64"
elif [ "$( uname -m )" = "i686" ] ; then
	MYFLAGS="-march=i586 -mtune=generic -O2 -pipe -g"
	ARCH="x86"
else
	die "Arch $( uname -m ) not supported"
fi

for i in \
	"/bin/echo" \
	"/bin/mkdir" \
	"/bin/mv" \
	"/bin/rm" \
	"/bin/sed" \
	"/bin/tar" \
	"/usr/bin/emerge" \
	"/usr/bin/portageq" \
	"/usr/bin/quickpkg"
do
	if [ ! -e "${i}" ] ; then
		die "Missing some basic utility in your system"
	fi
done

# first the default subset of useflags
IUSES_BASE="bash-completion branding cups dbus gstreamer gtk opengl vba webdav -aqua -binfilter -jemalloc -mysql -odk -postgres"

ENABLE_EXTENSIONS="presenter-console presenter-minimizer"
DISABLE_EXTENSIONS="nlpsolver pdfimport scripting-beanshell scripting-javascript wiki-publisher"

for lo_xt in ${ENABLE_EXTENSIONS}; do
        IUSES_BASE+=" libreoffice_extensions_${lo_xt}"
done
for lo_xt in ${DISABLE_EXTENSIONS}; do
        IUSES_BASE+=" -libreoffice_extensions_${lo_xt}"
done
unset lo_xt

# now for the options
IUSES_J="java libreoffice_extensions_nlpsolver"
IUSES_NJ="-java"
IUSES_G="gnome eds"
IUSES_NG="-gnome -eds"
IUSES_K="kde"
IUSES_NK="-kde"

if [ -f /etc/portage/package.use ] ; then
	die "Please save your package.use and re-create it as a directory"
fi

mkdir -p /etc/portage/package.use/ || die

mkdir -p "${MYPKGDIR}"
if [ -z "${MYPKGDIR}" -o ! -d "${MYPKGDIR}" ] ; then
	die "Anything goes wrong"
fi

# compile the flavor
echo "Base"
echo "app-office/libreoffice ${IUSES_BASE} ${IUSES_NJ} ${IUSES_NG} ${IUSES_NK}" > ${USEFILE}
FEATURES="${FEATURES} splitdebug" CFLAGS="${MYFLAGS}" CXXFLAGS="${MYFLAGS}" emerge ${OPTS} =libreoffice-${VERSION} || die "emerge failed"
quickpkg libreoffice --include-config=y
mv ${MYPKGDIR}/app-office/libreoffice-${VERSION}.tbz2 ./libreoffice-base-${BINVERSION}.tbz2  || die "Moving package failed"

echo "Base - java"
echo "app-office/libreoffice ${IUSES_BASE} ${IUSES_J} ${IUSES_NG} ${IUSES_NK}" > ${USEFILE}
FEATURES="${FEATURES} splitdebug" CFLAGS="${MYFLAGS}" CXXFLAGS="${MYFLAGS}" emerge ${OPTS} =libreoffice-${VERSION} || die "emerge failed"
quickpkg libreoffice --include-config=y
mv ${MYPKGDIR}/app-office/libreoffice-${VERSION}.tbz2 ./libreoffice-base-java-${BINVERSION}.tbz2  || die "Moving package failed"

# kde flavor
echo "KDE"
echo "app-office/libreoffice ${IUSES_BASE} ${IUSES_NJ} ${IUSES_NG} ${IUSES_K}" > ${USEFILE}
FEATURES="${FEATURES} splitdebug" CFLAGS="${MYFLAGS}" CXXFLAGS="${MYFLAGS}" emerge ${OPTS} =libreoffice-${VERSION} || die "emerge failed"
quickpkg libreoffice --include-config=y
mv ${MYPKGDIR}/app-office/libreoffice-${VERSION}.tbz2 ./libreoffice-kde-${BINVERSION}.tbz2  || die "Moving package failed"

echo "KDE - java"
echo "app-office/libreoffice ${IUSES_BASE} ${IUSES_J} ${IUSES_NG} ${IUSES_K}" > ${USEFILE}
FEATURES="${FEATURES} splitdebug" CFLAGS="${MYFLAGS}" CXXFLAGS="${MYFLAGS}" emerge ${OPTS} =libreoffice-${VERSION} || die "emerge failed"
quickpkg libreoffice --include-config=y
mv ${MYPKGDIR}/app-office/libreoffice-${VERSION}.tbz2 ./libreoffice-kde-java-${BINVERSION}.tbz2  || die "Moving package failed"

# gnome flavor
echo "Gnome"
echo "app-office/libreoffice ${IUSES_BASE} ${IUSES_NJ} ${IUSES_G} ${IUSES_NK}" > ${USEFILE}
FEATURES="${FEATURES} splitdebug" CFLAGS="${MYFLAGS}" CXXFLAGS="${MYFLAGS}" emerge ${OPTS} =libreoffice-${VERSION} || die "emerge failed"
quickpkg libreoffice --include-config=y
mv ${MYPKGDIR}/app-office/libreoffice-${VERSION}.tbz2 ./libreoffice-gnome-${BINVERSION}.tbz2  || die "Moving package failed"

echo "Gnome -java"
echo "app-office/libreoffice ${IUSES_BASE} ${IUSES_J} ${IUSES_G} ${IUSES_NK}" > ${USEFILE}
FEATURES="${FEATURES} splitdebug" CFLAGS="${MYFLAGS}" CXXFLAGS="${MYFLAGS}" emerge ${OPTS} =libreoffice-${VERSION} || die "emerge failed"
quickpkg libreoffice --include-config=y
mv ${MYPKGDIR}/app-office/libreoffice-${VERSION}.tbz2 ./libreoffice-gnome-java-${BINVERSION}.tbz2  || die "Moving package failed"


for name in ./libreoffice-*-${BINVERSION}.tbz2 ; do

  BN=`basename $name .tbz2`

  rm -rf tmp.lo
  mkdir -vp tmp.lo/p1 tmp.lo/p2
  cd tmp.lo/p1

  echo "Unpacking complete archive $BN.tbz2"
  tar xfvjp ../../$BN.tbz2

  echo "Moving debug info"
  mkdir -vp ../p2/usr/lib
  mv -v usr/lib/debug ../p2/usr/lib/

  echo "Re-packing program"
  tar cfvJ ../../$ARCH-bin-$BN.tar.xz --owner root --group root ./*

  echo "Re-packing debug info"
  cd ../p2
  tar cfvJ ../../$ARCH-debug-$BN.tar.xz --owner root --group root ./*

  echo "Removing unpacked files"
  cd ../..
  rm -rf tmp.lo

  echo "Done with $BN.tbz2"

done

rm -f ${USEFILE} || die "Removing ${USEFILE} failed"

rm -f libreoffice*${VERSION}*.tbz2 || die "Removing un-split package files failed"
