# Distributed under the terms of the GNU General Public License v2

EAPI="4"

inherit eutils toolchain-funcs multilib

DESCRIPTION="GNU awk pattern-matching language"
HOMEPAGE="http://www.gnu.org/software/gawk/gawk.html"
SRC_URI="mirror://gnu/gawk/${P}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE="nls readline"

# older gawk's provided shared lib for baselayout-1
RDEPEND="!<sys-apps/baselayout-2.0.1
	readline? ( sys-libs/readline )
	dev-libs/mpfr"
DEPEND="${RDEPEND}
	nls? ( sys-devel/gettext )"

src_prepare() {
	epatch "${FILESDIR}"/${P}-sandbox_issue.patch
	epatch "${FILESDIR}"/${P}-sigpipe.patch #507340

	# use symlinks rather than hardlinks, and disable version links
	sed -i \
		-e '/^LN =/s:=.*:= $(LN_S):' \
		-e '/install-exec-hook:/s|$|\nfoo:|' \
		Makefile.in doc/Makefile.in || die
	sed -i '/^pty1:$/s|$|\n_pty1:|' test/Makefile.in #413327

	# disable pointless build time hack that breaks cross-compiling #493362
	sed -i \
	-e '/check-recursive all-recursive: check-for-shared-lib-support/d' \
	extension/Makefile.in || die

}

src_configure() {
	export ac_cv_libsigsegv=no
	econf \
		--libexec='$(libdir)/misc' \
		$(use_enable nls) \
		$(use_with readline)
}

src_install() {
	rm -rf README_d # automatic dodocs barfs
	default

	# Install headers
	insinto /usr/include/awk
	doins *.h || die
	rm "${ED}"/usr/include/awk/config.h || die
}

pkg_postinst() {
	# symlink creation here as the links do not belong to gawk, but to any awk
	if has_version app-admin/eselect && has_version app-eselect/eselect-awk ; then
		eselect awk update ifunset
	else
		local l
		for l in "${EROOT}"usr/share/man/man1/gawk.1* "${EROOT}"usr/bin/gawk; do
			[[ -e ${l} && ! -e ${l/gawk/awk} ]] && ln -s "${l##*/}" "${l/gawk/awk}"
		done
		[[ ! -e ${EROOT}bin/awk ]] && ln -s "../usr/bin/gawk" "${EROOT}bin/awk"
	fi
}

pkg_postrm() {
	if has_version app-admin/eselect && has_version app-eselect/eselect-awk ; then
		eselect awk update ifunset
	fi
}
