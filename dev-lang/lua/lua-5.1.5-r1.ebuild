# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit eutils multilib portability toolchain-funcs versionator

DESCRIPTION="A powerful light-weight programming language designed for extending applications"
HOMEPAGE="http://www.lua.org/"
SRC_URI="http://www.lua.org/ftp/${P}.tar.gz"

LICENSE="MIT"
SLOT="5.1"
KEYWORDS="*"
IUSE="+deprecated emacs readline static"

RDEPEND="readline? ( sys-libs/readline )"
DEPEND="${RDEPEND} sys-devel/libtool"
PDEPEND="emacs? ( app-emacs/lua-mode )"

src_prepare() {
	local PATCH_PV=$(get_version_component_range 1-2)

	epatch "${FILESDIR}"/${PN}-${PATCH_PV}-make-r2.patch
	epatch "${FILESDIR}"/${PN}-${PATCH_PV}-module_paths.patch

	#EPATCH_SOURCE="${FILESDIR}/${PV}" EPATCH_SUFFIX="upstream.patch" epatch

	# correct lua versioning
	sed -i -e 's/\(LIB_VERSION = \)6:1:1/\16:5:1/' src/Makefile

	sed -i -e 's:\(/README\)\("\):\1.gz\2:g' doc/readme.html

	if ! use deprecated ; then
		# patches from 5.1.4 still apply
		epatch "${FILESDIR}"/${PN}-5.1.4-deprecated.patch
		epatch "${FILESDIR}"/${PN}-5.1.4-test.patch
	fi

	if ! use readline ; then
		epatch "${FILESDIR}"/${PN}-${PATCH_PV}-readline.patch
	fi

	# Using dynamic linked lua is not recommended for performance
	# reasons. http://article.gmane.org/gmane.comp.lang.lua.general/18519
	# Mainly, this is of concern if your arch is poor with GPRs, like x86
	# Note that this only affects the interpreter binary (named lua), not the lua
	# compiler (built statically) nor the lua libraries (both shared and static
	# are installed)
	if use static ; then
		epatch "${FILESDIR}"/${PN}-${PATCH_PV}-make_static-r1.patch
	fi

	# We want packages to find our things...
	sed -i \
		-e 's:/usr/local:'${EPREFIX}'/usr:' \
		-e "s:/\<lib\>:/$(get_libdir):g" \
		etc/lua.pc src/luaconf.h || die
}

# no need for a configure phase
src_configure() { true; }

src_compile() {
	tc-export CC
	myflags=
	# what to link to liblua
	liblibs="-lm"
	liblibs="${liblibs} $(dlopen_lib)"

	# what to link to the executables
	mylibs=
	if use readline; then
		mylibs="-lreadline"
	fi

	cd src
	emake CC="${CC}" CFLAGS="-DLUA_USE_LINUX ${CFLAGS}" \
			RPATH="${EPREFIX}/usr/$(get_libdir)/" \
			LUA_LIBS="${mylibs}" \
			LIB_LIBS="${liblibs}" \
			V=${PV} \
			gentoo_all || die "emake failed"

	mv lua_test ../test/lua.static
}

src_install() {
	emake INSTALL_TOP="${ED}/usr" INSTALL_LIB="${ED}/usr/$(get_libdir)" \
			V=${SLOT} gentoo_install \
	|| die "emake install gentoo_install failed"

	dodoc HISTORY README
	dohtml doc/*.html doc/*.png doc/*.css doc/*.gif

	doicon etc/lua.ico
	insinto /usr/$(get_libdir)/pkgconfig
	newins ${FILESDIR}/lua.pc-${PV} lua-5.1.pc
	# libtool does not do what we want -- we want liblua.so.5.1 not liblua.so.5 (due to upstream lua ABI stuff):
	mv ${ED}/usr/$(get_libdir)/liblua.so.${SLOT%%.*} ${ED}/usr/$(get_libdir)/liblua.so.${SLOT} || die
	if [ -e "${ED}/usr/$(get_libdir)/liblua.a" ]; then
		mv ${ED}/usr/$(get_libdir)/liblua.a ${ED}/usr/$(get_libdir)/liblua-5.1.a || die
	fi
	rm ${ED}/usr/$(get_libdir)/liblua.so || die
	newman doc/lua.1 lua-5.1.1
	newman doc/luac.1 luac-5.1.1
}

src_test() {
	local positive="bisect cf echo env factorial fib fibfor hello printf sieve
	sort trace-calls trace-globals"
	local negative="readonly"
	local test

	cd "${S}"
	for test in ${positive}; do
		test/lua.static test/${test}.lua || die "test $test failed"
	done

	for test in ${negative}; do
		test/lua.static test/${test}.lua && die "test $test failed"
	done
}
