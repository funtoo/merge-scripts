inherit eutils multilib autotools

DESCRIPTION="Restricted shell designed for sshd."
HOMEPAGE="http://rssh.sourceforge.net/"
SRC_URI="mirror://sourceforge/rssh/${P}.tar.gz"

EAPI='3'
LICENSE="BSD"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE="static subversion"
RDEPEND="virtual/ssh"

src_prepare() {
	sed -i 's:chmod u+s $(:chmod u+s $(DESTDIR)$(:' ${S}/Makefile.am ${S}/Makefile.in

	epatch "${FILESDIR}/rsync-protocol.diff"

	if use subversion; then
		epatch "${FILESDIR}/subversion.diff"
	fi

	eautoreconf
}

src_configure() {
	local myconf=" --libexecdir=/usr/$(get_libdir)/misc"
	myconf+=" --with-scp=/usr/bin/scp"
	myconf+=" --with-sftp-server=/usr/$(get_libdir)/misc/sftp-server"
	myconf+=" $(use_enable static)"

	econf ${myconf} || die
}

src_install() {
	make install DESTDIR="${D}" || die
	dodoc AUTHORS ChangeLog CHROOT INSTALL README TODO
}
