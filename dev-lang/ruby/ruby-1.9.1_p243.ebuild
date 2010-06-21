# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-lang/ruby/ruby-1.9.1_p243.ebuild,v 1.2 2009/10/12 23:07:03 jer Exp $

EAPI=2

inherit autotools eutils flag-o-matic multilib versionator

# Add patchlevel
MY_P="${P/_/-}"

# 1.9.1.0 -> 1.9
SLOT=$(get_version_component_range 1-2)

# 1.9.1.0 -> 1.9.1 (used in libdirs)
RUBYVERSION=$(get_version_component_range 1-3)

# 1.9 -> 19
MY_SUFFIX=$(delete_version_separator 1 ${SLOT})

DESCRIPTION="An object-oriented scripting language"
HOMEPAGE="http://www.ruby-lang.org/"
SRC_URI="mirror://ruby/${MY_P}.tar.bz2
		http://dev.a3li.info/gentoo/distfiles/${PN}-patches-${PVR}.tar.bz2"

LICENSE="|| ( Ruby GPL-2 )"
KEYWORDS="~amd64 ~hppa ~x86 ~x86-fbsd"
IUSE="berkdb debug doc emacs examples gdbm ipv6 rubytests socks5 ssl tk xemacs"

RDEPEND="
	berkdb? ( sys-libs/db )
	gdbm? ( sys-libs/gdbm )
	ssl? ( dev-libs/openssl )
	socks5? ( >=net-proxy/dante-1.1.13 )
	tk? ( dev-lang/tk[threads] )
	>=app-admin/eselect-ruby-20090909
	!=dev-lang/ruby-cvs-${SLOT}*
	!<dev-ruby/rdoc-2
	!dev-ruby/rexml"
DEPEND="${RDEPEND}"
PDEPEND="
	emacs? ( app-emacs/ruby-mode )
	xemacs? ( app-xemacs/ruby-modes )"

PROVIDE="virtual/ruby"

S="${WORKDIR}/${MY_P}"

pkg_setup() {
	ewarn
	ewarn "It is highly recommended to install >=dev-ruby/rubygems-1.3.1-r30"
	ewarn "if you have Ruby 1.8 on this system installed, too."
	ewarn
	epause 5
}

src_prepare() {
	cd "${S}"

	EPATCH_FORCE="yes" EPATCH_SUFFIX="patch" \
	epatch "${WORKDIR}/patches-${PVR}"

	# Strip rake
	rm "bin/rake"
	rm "lib/rake.rb"
	rm -rf "lib/rake"

	# Fix a hardcoded lib path in configure script
	sed -i -e "s:\(RUBY_LIB_PREFIX=\"\${prefix}/\)lib:\1$(get_libdir):" \
		configure.in || die "sed failed"

	eautoreconf
}

src_configure() {
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

	# ipv6 hack, bug 168939. Needs --enable-ipv6.
	use ipv6 || myconf="--with-lookup-order-hack=INET"

	econf --program-suffix=${MY_SUFFIX} --enable-shared --enable-pthread \
		$(use_enable socks5 socks) \
		$(use_enable doc install-doc) \
		--enable-ipv6 \
		$(use_enable debug) \
		$(use_with berkdb dbm) \
		$(use_with gdbm) \
		$(use_with ssl openssl) \
		$(use_with tk) \
		${myconf} \
		--enable-option-checking=no \
		|| die "econf failed"
}

src_compile() {
	emake EXTLDFLAGS="${LDFLAGS}" || die "emake failed"
}

src_test() {
	emake test || die "make test failed"

	elog "Ruby's make test has been run. Ruby also ships with a make check"
	elog "that cannot be run until after ruby has been installed."
	elog
	if use rubytests; then
		elog "You have enabled rubytests, so they will be installed to"
		elog "/usr/share/${PN}-${RUBYVERSION}/test. To run them you must be a user other"
		elog "than root, and you must place them into a writeable directory."
		elog "Then call: "
		elog
		elog "ruby19 -C /location/of/tests runner.rb"
	else
		elog "Enable the rubytests USE flag to install the make check tests"
	fi
}

src_install() {
	# Ruby is involved in the install process, we don't want interference here.
	unset RUBYOPT

	# Creating the rubygems directories, bug #230163 once more.
	local MINIRUBY=$(echo -e 'include Makefile\ngetminiruby:\n\t@echo $(MINIRUBY)'|make -f - getminiruby)
	keepdir /usr/$(get_libdir)/ruby${MY_SUFFIX}/gems/${RUBYVERSION}/{doc,gems,cache,specifications}

	export GEM_HOME="${D}/usr/$(get_libdir)/ruby${MY_SUFFIX}/gems/${RUBYVERSION}"
	export GEM_PATH="${GEM_HOME}/"

	LD_LIBRARY_PATH="${D}/usr/$(get_libdir)${LD_LIBRARY_PATH+:}${LD_LIBRARY_PATH}"
	RUBYLIB="${S}:${D}/usr/$(get_libdir)/ruby/${RUBYVERSION}"
	for d in $(find "${S}/ext" -type d) ; do
		RUBYLIB="${RUBYLIB}:$d"
	done
	export LD_LIBRARY_PATH RUBYLIB

	emake DESTDIR="${D}" install || die "make install failed"

	keepdir $(${MINIRUBY} -rrbconfig -e "print Config::CONFIG['sitelibdir']")
	keepdir $(${MINIRUBY} -rrbconfig -e "print Config::CONFIG['sitearchdir']")

	if use doc; then
		make DESTDIR="${D}" install-doc || die "make install-doc failed"
	fi

	if use examples; then
		dodir /usr/share/doc/${PF}
		cp -pPR sample "${D}/usr/share/doc/${PF}"
	fi

	dosym "libruby${MY_SUFFIX}$(get_libname ${PV%_*})" \
		"/usr/$(get_libdir)/libruby$(get_libname ${PV%.*})"
	dosym "libruby${MY_SUFFIX}$(get_libname ${PV%_*})" \
		"/usr/$(get_libdir)/libruby$(get_libname ${PV%_*})"

	dodoc ChangeLog NEWS doc/NEWS-1.8.7 README* ToDo

	if use rubytests; then
		dodir /usr/share/${PN}-${RUBYVERSION}
		cp -pPR test "${D}/usr/share/${PN}-${RUBYVERSION}"
	fi

	insinto /usr/$(get_libdir)/ruby${MY_SUFFIX}/vendor_ruby/${RUBYVERSION}/
	newins "${FILESDIR}/auto_gem.rb" auto_gem.rb
}

pkg_postinst() {
	if [[ ! -n $(readlink "${ROOT}"usr/bin/ruby) ]] ; then
		eselect ruby set ruby${MY_SUFFIX}
	fi

	elog
	elog "To switch between available Ruby profiles, execute as root:"
	elog "\teselect ruby set ruby(18|19|...)"
	elog
}

pkg_postrm() {
	eselect ruby cleanup
}
