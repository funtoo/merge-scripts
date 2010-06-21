# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-lang/ruby/ruby-1.8.6_p369.ebuild,v 1.10 2009/06/21 14:17:24 ranger Exp $

inherit autotools eutils flag-o-matic multilib versionator

MY_P="${PN}-$(replace_version_separator 3 '-')"
S=${WORKDIR}/${MY_P}

SLOT=$(get_version_component_range 1-2)
MY_SUFFIX=$(delete_version_separator 1 ${SLOT})

DESCRIPTION="An object-oriented scripting language"
HOMEPAGE="http://www.ruby-lang.org/"
SRC_URI="mirror://ruby/${SLOT}/${MY_P}.tar.bz2"

LICENSE="|| ( Ruby GPL-2 )"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd"
IUSE="berkdb debug doc emacs examples gdbm ipv6 rubytests socks5 ssl threads tk xemacs"

RDEPEND="
	berkdb? ( sys-libs/db )
	gdbm? ( sys-libs/gdbm )
	ssl? ( dev-libs/openssl )
	socks5? ( >=net-proxy/dante-1.1.13 )
	tk? ( dev-lang/tk )
	app-admin/eselect-ruby
	!=dev-lang/ruby-cvs-${SLOT}*
	!<dev-ruby/rdoc-2
	!dev-ruby/rexml"
DEPEND="${RDEPEND}"
PDEPEND="emacs? ( app-emacs/ruby-mode )
	xemacs? ( app-xemacs/ruby-modes )"

PROVIDE="virtual/ruby"

pkg_setup() {
	use tk || return

	# Note for EAPI-2 lovers: We'd like to show that custom message.
	# *If* you can make USE dependencies show that, too, feel free to migrate.
	if (use threads && ! built_with_use dev-lang/tk threads) \
		|| (! use threads && built_with_use dev-lang/tk threads) ; then
		eerror
		eerror "You have Tk support enabled."
		eerror
		eerror "Ruby and Tk need the same 'threads' USE flag settings."
		eerror "Either change the USE flag on dev-lang/ruby or on dev-lang/tk"
		eerror "and recompile tk."

		die "threads USE flag mismatch"
	fi
}

src_unpack() {
	unpack ${A}

	cd "${S}/ext/dl"
	epatch "${FILESDIR}/${PN}-1.8.6-memory-leak.diff"
	cd "${S}"

	epatch "${FILESDIR}/${PN}-mkconfig.patch"
	epatch "${FILESDIR}/${PN}${MY_SUFFIX}-mkmf-parallel-install.patch"
	epatch "${FILESDIR}/${PN}-1.8.6-uclibc-udp.patch"

	# Fix a hardcoded lib path in configure script
	sed -i -e "s:\(RUBY_LIB_PREFIX=\"\${prefix}/\)lib:\1$(get_libdir):" \
		configure.in || die "sed failed"

	eautoreconf
}

src_compile() {
	# -fomit-frame-pointer makes ruby segfault, see bug #150413.
	filter-flags -fomit-frame-pointer
	# In many places aliasing rules are broken; play it safe
	# as it's risky with newer compilers to leave it as it is.
	append-flags -fno-strict-aliasing

	# Socks support via dante
	if use socks5 ; then
		# Socks support can't be disabled as long as SOCKS_SERVER is
		# set and socks library is present, so need to unset
		# SOCKS_SERVER in that case.
		unset SOCKS_SERVER
	fi

	# Increase GC_MALLOC_LIMIT if set (default is 8000000)
	if [ -n "${RUBY_GC_MALLOC_LIMIT}" ] ; then
		append-flags "-DGC_MALLOC_LIMIT=${RUBY_GC_MALLOC_LIMIT}"
	fi

	econf --program-suffix=$MY_SUFFIX --enable-shared \
		$(use_enable socks5 socks) \
		$(use_enable doc install-doc) \
		$(use_enable threads pthread) \
		$(use_enable ipv6) \
		$(use_enable debug) \
		$(use_with berkdb dbm) \
		$(use_with gdbm) \
		$(use_with ssl openssl) \
		$(use_with tk) \
		${myconf} \
		--with-sitedir=/usr/$(get_libdir)/ruby/site_ruby \
		--enable-option-checking=no \
		|| die "econf failed"

	emake EXTLDFLAGS="${LDFLAGS}" || die "emake failed"
}

src_test() {
	emake -j1 test || die "make test failed"

	elog "Ruby's make test has been run. Ruby also ships with a make check"
	elog "that cannot be run until after ruby has been installed."
	elog
	if use rubytests; then
		elog "You have enabled rubytests, so they will be installed to"
		elog "/usr/share/${PN}-${SLOT}/test. To run them you must be a user other"
		elog "than root, and you must place them into a writeable directory."
		elog "Then call: "
		elog
		elog "ruby -C /location/of/tests runner.rb"
	else
		elog "Enable the rubytests USE flag to install the make check tests"
	fi
}

src_install() {
	# Ruby is involved in the install process, we don't want interference here.
	unset RUBYOPT

	LD_LIBRARY_PATH="${D}/usr/$(get_libdir)"
	RUBYLIB="${S}:${D}/usr/$(get_libdir)/ruby/${SLOT}"
	for d in $(find "${S}/ext" -type d) ; do
		RUBYLIB="${RUBYLIB}:$d"
	done
	export LD_LIBRARY_PATH RUBYLIB

	emake DESTDIR="${D}" install || die "make install failed"

	MINIRUBY=$(echo -e 'include Makefile\ngetminiruby:\n\t@echo $(MINIRUBY)'|make -f - getminiruby)
	keepdir $(${MINIRUBY} -rrbconfig -e "print Config::CONFIG['sitelibdir']")
	keepdir $(${MINIRUBY} -rrbconfig -e "print Config::CONFIG['sitearchdir']")

	if use doc; then
		make DESTDIR="${D}" install-doc || die "make install-doc failed"
	fi

	if use examples; then
		dodir /usr/share/doc/${PF}
		cp -pPR sample "${D}/usr/share/doc/${PF}"
	fi

	dosym libruby$MY_SUFFIX$(get_libname ${PV%_*}) /usr/$(get_libdir)/libruby$(get_libname ${PV%.*})
	dosym libruby$MY_SUFFIX$(get_libname ${PV%_*}) /usr/$(get_libdir)/libruby$(get_libname ${PV%_*})

	dodoc ChangeLog NEWS README* ToDo

	if use rubytests; then
		dodir /usr/share/${PN}-${SLOT}
		cp -pPR test "${D}/usr/share/${PN}-${SLOT}"
	fi
}

pkg_postinst() {
	if [[ ! -n $(readlink "${ROOT}"usr/bin/ruby) ]] ; then
		eselect ruby set ruby${MY_SUFFIX}
	fi

	elog
	elog "This ebuild is compatible to eselect-ruby"
	elog "To switch between available Ruby profiles, execute as root:"
	elog "\teselect ruby set ruby(18|19|...)"
	elog
}

pkg_postrm() {
	if [[ ! -n $(readlink "${ROOT}"usr/bin/ruby) ]] ; then
		eselect ruby set ruby${MY_SUFFIX}
	fi
}
