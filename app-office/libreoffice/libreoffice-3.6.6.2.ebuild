# Distributed under the terms of the GNU General Public License v2

EAPI=5

KDE_REQUIRED="optional"
QT_MINIMAL="4.7.4"
KDE_SCM="git"
CMAKE_REQUIRED="never"

PYTHON_COMPAT=( python{2_5,2_6,2_7} )
PYTHON_REQ_USE="threads,xml"

# experimental ; release ; old
# Usually the tarballs are moved a lot so this should make
# everyone happy.
DEV_URI="
	http://dev-builds.libreoffice.org/pre-releases/src
	http://download.documentfoundation.org/libreoffice/src/${PV:0:5}/
	http://download.documentfoundation.org/libreoffice/old/${PV}/
"
EXT_URI="http://ooo.itc.hu/oxygenoffice/download/libreoffice"
ADDONS_URI="http://dev-www.libreoffice.org/src/"

BRANDING="${PN}-branding-gentoo-0.6.tar.xz"
# PATCHSET="${P}-patchset-01.tar.xz"

[[ ${PV} == *9999* ]] && SCM_ECLASS="git-2"
inherit base autotools bash-completion-r1 check-reqs eutils java-pkg-opt-2 kde4-base pax-utils python-single-r1 multilib toolchain-funcs flag-o-matic ${SCM_ECLASS}
unset SCM_ECLASS

DESCRIPTION="LibreOffice, a full office productivity suite."
HOMEPAGE="http://www.libreoffice.org"
SRC_URI="branding? ( http://dev.gentoo.org/~dilfridge/distfiles/${BRANDING} )"
[[ -n ${PATCHSET} ]] && SRC_URI+=" http://dev.gentooexperimental.org/~scarabeus/${PATCHSET}"

# Split modules following git/tarballs
# Core MUST be first!
# Help is used for the image generator
MODULES="core binfilter help"
# Only release has the tarballs
if [[ ${PV} != *9999* ]]; then
	for i in ${DEV_URI}; do
		for mod in ${MODULES}; do
			if [[ ${mod} == binfilter ]]; then
				SRC_URI+=" binfilter? ( ${i}/${PN}-${mod}-${PV}.tar.xz )"
			else
				SRC_URI+=" ${i}/${PN}-${mod}-${PV}.tar.xz"
			fi
		done
		unset mod
	done
	unset i
fi
unset DEV_URI

# Really required addons
# These are bundles that can't be removed for now due to huge patchsets.
# If you want them gone, patches are welcome.
ADDONS_SRC+=" ${ADDONS_URI}/ea91f2fb4212a21d708aced277e6e85a-vigra1.4.0.tar.gz"
ADDONS_SRC+=" ${ADDONS_URI}/1f24ab1d39f4a51faf22244c94a6203f-xmlsec1-1.2.14.tar.gz" # modifies source code
ADDONS_SRC+=" java? ( ${ADDONS_URI}/17410483b5b5f267aa18b7e00b65e6e0-hsqldb_1_8_0.zip )"
ADDONS_SRC+=" java? ( ${ADDONS_URI}/ada24d37d8d638b3d8a9985e80bc2978-source-9.0.0.7-bj.zip )"
ADDONS_SRC+=" libreoffice_extensions_wiki-publisher? ( ${ADDONS_URI}/a7983f859eafb2677d7ff386a023bc40-xsltml_2.1.2.zip )" # no release for 8 years, should we package it?
ADDONS_SRC+=" libreoffice_extensions_scripting-javascript? ( ${ADDONS_URI}/798b2ffdc8bcfe7bca2cf92b62caf685-rhino1_5R5.zip )" # Does not build with 1.6 rhino at all
ADDONS_SRC+=" libreoffice_extensions_scripting-javascript? ( ${ADDONS_URI}/35c94d2df8893241173de1d16b6034c0-swingExSrc.zip )" # requirement of rhino
ADDONS_SRC+=" odk? ( http://download.go-oo.org/extern/185d60944ea767075d27247c3162b3bc-unowinreg.dll )" # not packageable
SRC_URI+=" ${ADDONS_SRC}"

unset ADDONS_URI
unset EXT_URI
unset ADDONS_SRC

IUSE="binfilter binfilterdebug +branding +cups dbus eds gnome gstreamer +gtk
jemalloc kde mysql odk opengl postgres test +vba +webdav"

LO_EXTS="nlpsolver pdfimport presenter-console presenter-minimizer scripting-beanshell scripting-javascript wiki-publisher"
# Unpackaged separate extensions:
# diagram: lo has 0.9.5 upstream is weirdly patched 0.9.4 -> wtf?
# hunart: only on ooo extensions -> fubared download path somewhere on sf
# numbertext, typo, validator, watch-window: ^^
# oooblogger: no homepage or anything
# Extensions that need extra work:
# report-builder: missing java packages
for lo_xt in ${LO_EXTS}; do
	IUSE+=" libreoffice_extensions_${lo_xt}"
done
unset lo_xt

LICENSE="|| ( LGPL-3 MPL-1.1 )"
SLOT="0"
[[ ${PV} == *9999* ]] || \
KEYWORDS="amd64 ~arm ppc x86 ~amd64-linux ~x86-linux"

COMMON_DEPEND="
	${PYTHON_DEPS}
	app-arch/zip
	app-arch/unzip
	>=app-text/hunspell-1.3.2-r3
	app-text/mythes
	>=app-text/libexttextcat-3.2
	app-text/libwpd:0.9[tools]
	app-text/libwpg:0.2
	>=app-text/libwps-0.2.2
	>=dev-cpp/clucene-2.3.3.4-r2
	>=dev-cpp/libcmis-0.2:0.2
	dev-db/unixODBC
	dev-libs/expat
	>=dev-libs/glib-2.28
	>=dev-libs/hyphen-2.7.1
	>=dev-libs/icu-4.8.1.1
	>=dev-libs/nspr-4.8.8
	>=dev-libs/nss-3.12.9
	>=dev-lang/perl-5.0
	>=dev-libs/openssl-1.0.0d
	>=dev-libs/redland-1.0.14[ssl]
	gnome-base/librsvg
	media-gfx/graphite2
	>=media-libs/fontconfig-2.8.0
	media-libs/freetype:2
	media-libs/lcms:2
	>=media-libs/libpng-1.4
	>=media-libs/libcdr-0.0.5
	media-libs/libvisio
	>=net-misc/curl-7.21.4
	sci-mathematics/lpsolve
	>=sys-libs/db-4.8
	virtual/jpeg
	>=x11-libs/cairo-1.10.0[X]
	x11-libs/libXinerama
	x11-libs/libXrandr
	x11-libs/libXrender
	cups? ( net-print/cups )
	dbus? ( >=dev-libs/dbus-glib-0.92 )
	eds? ( gnome-extra/evolution-data-server )
	gnome? ( gnome-base/gconf:2 )
	gtk? (
		x11-libs/gdk-pixbuf[X]
		>=x11-libs/gtk+-2.24:2
	)
	gstreamer? (
		>=media-libs/gstreamer-0.10:0.10
		>=media-libs/gst-plugins-base-0.10:0.10
	)
	jemalloc? ( dev-libs/jemalloc )
	libreoffice_extensions_pdfimport? ( >=app-text/poppler-0.16:=[xpdf-headers(+),cxx] )
	libreoffice_extensions_scripting-beanshell? ( >=dev-java/bsh-2.0_beta4 )
	libreoffice_extensions_scripting-javascript? ( dev-java/rhino:1.6 )
	libreoffice_extensions_wiki-publisher? (
		dev-java/commons-codec:0
		dev-java/commons-httpclient:3
		dev-java/commons-lang:2.1
		dev-java/commons-logging:0
		dev-java/tomcat-servlet-api:3.0
	)
	mysql? ( >=dev-db/mysql-connector-c++-1.1.0 )
	opengl? (
		virtual/glu
		virtual/opengl
	)
	postgres? ( >=dev-db/postgresql-base-9.0[kerberos] )
	webdav? ( net-libs/neon )
"

RDEPEND="${COMMON_DEPEND}
	!app-office/libreoffice-bin
	!app-office/libreoffice-bin-debug
	!<app-office/openoffice-bin-3.4.0-r1
	!app-office/openoffice
	media-fonts/libertine-ttf
	media-fonts/liberation-fonts
	media-fonts/urw-fonts
	java? ( >=virtual/jre-1.6 )
"

PDEPEND="
	=app-office/libreoffice-l10n-3.6*
"

# FIXME: cppunit should be moved to test conditional
#        after everything upstream is under gbuild
#        as dmake execute tests right away
DEPEND="${COMMON_DEPEND}
	>=dev-libs/boost-1.46
	>=dev-libs/libxml2-2.7.8
	dev-libs/libxslt
	dev-perl/Archive-Zip
	dev-util/cppunit
	>=dev-util/gperf-3
	dev-util/intltool
	<dev-util/mdds-0.8.0
	virtual/pkgconfig
	net-misc/npapi-sdk
	>=sys-apps/findutils-4.4.2
	sys-devel/bison
	sys-apps/coreutils
	sys-devel/flex
	sys-devel/gettext
	>=sys-devel/make-3.82
	sys-libs/zlib
	x11-libs/libXt
	x11-libs/libXtst
	x11-proto/randrproto
	x11-proto/xextproto
	x11-proto/xineramaproto
	x11-proto/xproto
	java? (
		>=virtual/jdk-1.6
		>=dev-java/ant-core-1.7
	)
	odk? ( app-doc/doxygen )
	test? ( dev-util/cppunit )
"

PATCHES=(
	# not upstreamable stuff
	"${FILESDIR}/${PN}-3.6-system-pyuno.patch"
	"${FILESDIR}/${PN}-3.6-separate-checks.patch"
)

REQUIRED_USE="
	gnome? ( gtk )
	eds? ( gnome )
	libreoffice_extensions_nlpsolver? ( java )
	libreoffice_extensions_scripting-beanshell? ( java )
	libreoffice_extensions_scripting-javascript? ( java )
	libreoffice_extensions_wiki-publisher? ( java )
"

S="${WORKDIR}/${PN}-core-${PV}"

CHECKREQS_MEMORY="512M"
CHECKREQS_DISK_BUILD="6G"

pkg_pretend() {
	local pgslot

	if [[ ${MERGE_TYPE} != binary ]]; then
		check-reqs_pkg_pretend

		if [[ $(gcc-major-version) -lt 4 ]] || \
				 ( [[ $(gcc-major-version) -eq 4 && $(gcc-minor-version) -lt 5 ]] ) \
				; then
			eerror "Compilation with gcc older than 4.5 is not supported"
			die "Too old gcc found."
		fi
	fi

}

pkg_setup() {
	java-pkg-opt-2_pkg_setup
	kde4-base_pkg_setup
	python-single-r1_pkg_setup

	[[ ${MERGE_TYPE} != binary ]] && check-reqs_pkg_setup
}

src_unpack() {
	local mod dest tmplfile tmplname mypv

	[[ -n ${PATCHSET} ]] && unpack ${PATCHSET}
	if use branding; then
		unpack "${BRANDING}"
	fi

	if [[ ${PV} != *9999* ]]; then
		for mod in ${MODULES}; do
			if [[ ${mod} == binfilter ]] && ! use binfilter; then
				continue
			fi
			unpack "${PN}-${mod}-${PV}.tar.xz"
			if [[ ${mod} != core ]]; then
				mv -n "${WORKDIR}/${PN}-${mod}-${PV}"/* "${S}"
				rm -rf "${WORKDIR}/${PN}-${mod}-${PV}"
			fi
		done
	else
		for mod in ${MODULES}; do
			if [[ ${mod} == binfilter ]] && ! use binfilter; then
				continue
			fi
			mypv=${PV/.9999}
			[[ ${mypv} != ${PV} ]] && EGIT_BRANCH="${PN}-${mypv/./-}"
			EGIT_PROJECT="${PN}/${mod}"
			EGIT_SOURCEDIR="${WORKDIR}/${PN}-${mod}-${PV}"
			EGIT_REPO_URI="git://anongit.freedesktop.org/${PN}/${mod}"
			EGIT_NOUNPACK="true"
			git-2_src_unpack
			if [[ ${mod} != core ]]; then
				mv -n "${WORKDIR}/${PN}-${mod}-${PV}"/* "${S}"
				rm -rf "${WORKDIR}/${PN}-${mod}-${PV}"
			fi
		done
		unset EGIT_PROJECT EGIT_SOURCEDIR EGIT_REPO_URI EGIT_BRANCH
	fi
}

src_prepare() {
	# optimization flags
	export ARCH_FLAGS="${CXXFLAGS}"
	export LINKFLAGSOPTIMIZE="${LDFLAGS}"
	export GMAKE_OPTIONS="${MAKEOPTS}"

	# patchset
	if [[ -n ${PATCHSET} ]]; then
		EPATCH_FORCE="yes" \
		EPATCH_SOURCE="${WORKDIR}/${PATCHSET/.tar.xz/}" \
		EPATCH_SUFFIX="patch" \
		epatch
	fi

	base_src_prepare

	# please no debug in binfilter, it blows up things insanely
	if use binfilter && ! use binfilterdebug ; then
		for name in $(find "${S}/binfilter" -name makefile.mk) ; do
			sed -i -e '1i\CFLAGS+= -g0' $name || die
		done
	fi

	AT_M4DIR="m4"
	eautoreconf
	# hack in the autogen.sh
	touch autogen.lastrun

	# system pyuno mess
	sed \
		-e "s:%eprefix%:${EPREFIX}:g" \
		-e "s:%libdir%:$(get_libdir):g" \
		-i pyuno/source/module/uno.py \
		-i scripting/source/pyprov/officehelper.py || die
}

src_configure() {
	local java_opts
	local internal_libs
	local lo_ext
	local ext_opts
	local jbs=$(sed -ne 's/.*\(-j[[:space:]]*\|--jobs=\)\([[:digit:]]\+\).*/\2/;T;p' <<< "${MAKEOPTS}")

	# Workaround the boost header include issue for older gccs
	if [[ $(gcc-major-version) -eq 4 && $(gcc-minor-version) -lt 6 ]]; then
		append-cppflags -DBOOST_NO_0X_HDR_TYPEINDEX
		append-cppflags -DBOOST_NO_CXX11_HDR_TYPEINDEX
	fi

	# recheck that there is some value in jobs
	[[ -z ${jbs} ]] && jbs="1"

	# sane: just sane.h header that is used for scan in writer, not
	#       linked or anything else, worthless to depend on
	# vigra: just uses templates from there
	#        it is serious pain in the ass for packaging
	#        should be replaced by boost::gil if someone interested
	internal_libs+="
		--without-system-sane
		--without-system-vigra
	"

	# libreoffice extensions handling
	for lo_xt in ${LO_EXTS}; do
		ext_opts+=" $(use_enable libreoffice_extensions_${lo_xt} ext-${lo_xt})"
	done

	if use java; then
		# hsqldb: system one is too new
		# saxon: system one does not work properly
		java_opts="
			--without-junit
			--without-system-hsqldb
			--without-system-saxon
			--with-ant-home="${ANT_HOME}"
			--with-jdk-home=$(java-config --jdk-home 2>/dev/null)
			--with-java-target-version=$(java-pkg_get-target)
			--with-jvm-path="${EPREFIX}/usr/$(get_libdir)/"
		"

		use libreoffice_extensions_scripting-beanshell && \
			java_opts+=" --with-beanshell-jar=$(java-pkg_getjar bsh bsh.jar)"

		use libreoffice_extensions_scripting-javascript && \
			java_opts+=" --with-rhino-jar=$(java-pkg_getjar rhino-1.6 js.jar)"

		if use libreoffice_extensions_wiki-publisher; then
			java_opts+="
				--with-commons-codec-jar=$(java-pkg_getjar commons-codec commons-codec.jar)
				--with-commons-httpclient-jar=$(java-pkg_getjar commons-httpclient-3 commons-httpclient.jar)
				--with-commons-lang-jar=$(java-pkg_getjar commons-lang-2.1 commons-lang.jar)
				--with-commons-logging-jar=$(java-pkg_getjar commons-logging commons-logging.jar)
				--with-servlet-api-jar=$(java-pkg_getjar tomcat-servlet-api-3.0 servlet-api.jar)
			"
		fi
	fi

	if use branding; then
		# hack...
		mv -v "${WORKDIR}/branding-intro.png" "${S}/icon-themes/galaxy/brand/intro.png" || die
	fi

	# system headers/libs/...: enforce using system packages
	# --enable-unix-qstart-libpng: use libpng splashscreen that is faster
	# --enable-cairo: ensure that cairo is always required
	# --enable-*-link: link to the library rather than just dlopen on runtime
	# --enable-release-build: build the libreoffice as release
	# --disable-fetch-external: prevent dowloading during compile phase
	# --disable-gnome-vfs: old gnome virtual fs support
	# --disable-kdeab: kde3 adressbook
	# --disable-kde: kde3 support
	# --disable-ldap: ldap requires internal mozilla stuff, same like mozab
	# --disable-mozilla: disable mozilla build that is used for adresbook, not
	#   affecting the nsplugin that is always ON
	# --disable-pch: precompiled headers cause build crashes
	# --disable-rpath: relative runtime path is not desired
	# --disable-systray: quickstarter does not actually work at all so do not
	#   promote it
	# --disable-zenity: disable build icon
	# --enable-extension-integration: enable any extension integration support
	# --with-{max-jobs,num-cpus}: ensuring parallel building
	# --without-{afms,fonts,myspell-dicts,ppsd}: prevent install of sys pkgs
	# --without-stlport: disable deprecated extensions framework
	# --disable-ext-report-builder: too much java packages pulled in
	econf \
		--docdir="${EPREFIX}/usr/share/doc/${PF}/" \
		--with-system-headers \
		--with-system-libs \
		--with-system-jars \
		--with-system-dicts \
		--enable-graphite \
		--enable-cairo-canvas \
		--enable-largefile \
		--enable-mergelibs \
		--enable-python=system \
		--enable-librsvg=system \
		--enable-randr \
		--enable-randr-link \
		--enable-release-build \
		--enable-unix-qstart-libpng \
		--enable-xmlsec \
		--disable-ccache \
		--disable-crashdump \
		--disable-dependency-tracking \
		--disable-epm \
		--disable-fetch-external \
		--disable-gnome-vfs \
		--disable-ext-report-builder \
		--disable-kdeab \
		--disable-kde \
		--disable-ldap \
		--disable-mozilla \
		--disable-nsplugin \
		--disable-online-update \
		--disable-pch \
		--disable-rpath \
		--disable-systray \
		--disable-zenity \
		--with-alloc=$(use jemalloc && echo "jemalloc" || echo "system") \
		--with-build-version="Gentoo official package" \
		--enable-extension-integration \
		--with-external-dict-dir="${EPREFIX}/usr/share/myspell" \
		--with-external-hyph-dir="${EPREFIX}/usr/share/myspell" \
		--with-external-thes-dir="${EPREFIX}/usr/share/myspell" \
		--with-external-tar="${DISTDIR}" \
		--with-lang="" \
		--with-max-jobs=${jbs} \
		--with-num-cpus=${jbs} \
		--with-unix-wrapper=libreoffice \
		--with-vendor="Gentoo Foundation" \
		--with-x \
		--without-afms \
		--without-fonts \
		--without-myspell-dicts \
		--without-stlport \
		--without-system-mozilla \
		--without-help \
		--with-helppack-integration \
		--without-sun-templates \
		--disable-gtk3 \
		$(use_enable binfilter) \
		$(use_enable cups) \
		$(use_enable dbus) \
		$(use_enable eds evolution2) \
		$(use_enable gnome gconf) \
		$(use_enable gnome gio) \
		$(use_enable gnome lockdown) \
		$(use_enable gstreamer) \
		$(use_enable gtk) \
		$(use_enable kde kde4) \
		$(use_enable mysql ext-mysql-connector) \
		$(use_enable odk) \
		$(use_enable opengl) \
		$(use_enable postgres postgresql-sdbc) \
		$(use_enable test linkoo) \
		$(use_enable vba) \
		$(use_enable webdav neon) \
		$(use_with java) \
		$(use_with mysql system-mysql-cppconn) \
		$(use_with odk doxygen) \
		${internal_libs} \
		${java_opts} \
		${ext_opts}
}

src_compile() {
	# hack for offlinehelp, this needs fixing upstream at some point
	# it is broken because we send --without-help
	# https://bugs.freedesktop.org/show_bug.cgi?id=46506
	(
		source "${S}/config_host.mk" 2&> /dev/null

		local path="${SOLARVER}/${INPATH}/res/img"
		mkdir -p "${path}" || die

		echo "perl \"${S}/helpcontent2/helpers/create_ilst.pl\" -dir=icon-themes/galaxy/res/helpimg > \"${path}/helpimg.ilst\""
		perl "${S}/helpcontent2/helpers/create_ilst.pl" \
			-dir=icon-themes/galaxy/res/helpimg \
			> "${path}/helpimg.ilst"
		[[ -s "${path}/helpimg.ilst" ]] || ewarn "The help images list is empty, something is fishy, report a bug."
	)

	# this is not a proper make script
	make build || die
}

src_test() {
	make unitcheck || die
	make slowcheck || die
}

src_install() {
	# This is not Makefile so no buildserver
	make DESTDIR="${D}" distro-pack-install -o build -o check || die

	# Fix bash completion placement
	newbashcomp "${ED}"/etc/bash_completion.d/libreoffice.sh ${PN}
	rm -rf "${ED}"/etc/

	if use branding; then
		insinto /usr/$(get_libdir)/${PN}/program
		newins "${WORKDIR}/branding-sofficerc" sofficerc
	fi

	# Hack for offlinehelp, this needs fixing upstream at some point.
	# It is broken because we send --without-help
	# https://bugs.freedesktop.org/show_bug.cgi?id=46506
	insinto /usr/$(get_libdir)/libreoffice/help
	doins xmlhelp/util/*.xsl

	# Remove desktop files for support to old installs that can't parse mime
	rm -rf "${ED}"/usr/share/mimelnk/
}

pkg_preinst() {
	# Cache updates - all handled by kde eclass for all environments
	kde4-base_pkg_preinst
}

pkg_postinst() {
	kde4-base_pkg_postinst

	pax-mark -m "${EPREFIX}"/usr/$(get_libdir)/libreoffice/program/soffice.bin
	pax-mark -m "${EPREFIX}"/usr/$(get_libdir)/libreoffice/program/unopkg.bin

	use java || \
		ewarn 'If you plan to use lbase application you should enable java or you will get various crashes.'
}

pkg_postrm() {
	kde4-base_pkg_postrm
}
