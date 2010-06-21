# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-fs/samba/samba-3.2.15.ebuild,v 1.1 2009/10/02 13:54:19 patrick Exp $

inherit eutils pam multilib versionator confutils

MY_P=${PN}-${PV/_/}

DESCRIPTION="A suite of SMB and CIFS client/server programs for UNIX"
HOMEPAGE="http://www.samba.org/"
SRC_URI="mirror://samba/${MY_P}.tar.gz"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~sparc-fbsd ~x86 ~x86-fbsd"

# disabled for now
#IUSE_LINGUAS="linguas_ja linguas_pl"

IUSE="${IUSE_LINGUAS} acl ads async automount caps cifsupcall cups doc examples ipv6 kernel_linux ldap fam
	pam quotas readline selinux swat syslog winbind"

RDEPEND="dev-libs/popt
	dev-libs/iniparser
	virtual/libiconv
	acl? ( virtual/acl )
	cifsupcall? ( sys-apps/keyutils )
	cups? ( net-print/cups )
	ipv6? ( sys-apps/xinetd )
	ads? ( virtual/krb5 sys-fs/e2fsprogs )
	ldap? ( net-nds/openldap )
	pam? ( virtual/pam )
	readline? ( sys-libs/readline )
	selinux? ( sec-policy/selinux-samba )
	swat? ( sys-apps/xinetd )
	syslog? ( virtual/logger )
	fam? ( virtual/fam )
	caps? ( sys-libs/libcap )"
DEPEND="${RDEPEND}"

S="${WORKDIR}/${MY_P}"
CONFDIR="${FILESDIR}/config-3.2"
PRIVATE_DST=/var/lib/samba/private

# Tests are currently broken due to hardcoded paths (due to --with-fhs)
# The problem is that --without-fhs lets samba use lockdir (which can be changed in smb.conf)
# which is wrong as well.
RESTRICT="test"

pkg_setup() {
	confutils_use_depend_all ads ldap
	confutils_use_depend_all cifsupcall ads
}

src_unpack() {
	unpack ${A}
	cd "${S}/source"

	# Ok, agreed, this is ugly. But it avoids a patch we
	# need for every samba version and we don't need autotools
	sed -i \
		-e 's|"lib32" ||' \
		-e 's|if test -d "$i/$l" ;|if test -d "$i/$l" -o -L "$i/$l";|' \
		configure || die "sed failed"

	rm "${S}/docs/manpages"/{mount,umount}.cifs.8

	sed -i \
		-e 's|tdbsam|tdbsam:${PRIVATEDIR}/passdb.tdb|' \
		"${S}/source/script/tests/selftest.sh" || die "sed failed"
}

src_compile() {
	cd "${S}/source"

	local myconf
	local mylangs
	local mymod_shared

	# this doesn't seem to work ...
	#mylangs="--with-manpages-langs=en"
	#use linguas_ja && mylangs="${mylangs},ja"
	#use linguas_pl && mylangs="${mylangs},pl"

	use winbind && mymod_shared="--with-shared-modules=idmap_rid"
	if use ldap ; then
		myconf="${myconf} $(use_with ads)"
		use winbind && mymod_shared="${mymod_shared},idmap_ad"
	fi

	[[ ${CHOST} == *-*bsd* ]] && myconf="${myconf} --disable-pie"
	use hppa && myconf="${myconf} --disable-pie"

	use caps && export ac_cv_header_sys_capability_h=yes || export ac_cv_header_sys_capability_h=no

	# Otherwise we get the whole swat stuff installed
	if ! use swat ; then
		sed -i \
			-e 's/^\(install:.*\)installswat \(.*\)/\1\2/' \
			Makefile.in || die "sed failed"
	fi

	econf \
		--with-fhs \
		--sysconfdir=/etc/samba \
		--localstatedir=/var \
		--with-configdir=/etc/samba \
		--with-libdir=/usr/$(get_libdir)/samba \
		--with-pammodulesdir=$(getpam_mod_dir) \
		--with-swatdir=/usr/share/doc/${PF}/swat \
		--with-piddir=/var/run/samba \
		--with-lockdir=/var/cache/samba \
		--with-logfilebase=/var/log/samba \
		--with-privatedir=${PRIVATE_DST} \
		--with-libsmbclient \
		--enable-socket-wrapper \
		--enable-nss-wrapper \
		--with-cifsmount=no \
		--disable-dnssd \
		$(use_with acl acl-support) \
		$(use_with async aio-support) \
		$(use_with automount) \
		$(use_with cifsupcall) \
		$(use_enable cups) \
		$(use_enable fam) \
		$(use_with ads krb5) \
		$(use_with ads dnsupdate) \
		$(use_with ldap) \
		$(use_with pam) $(use_with pam pam_smbpass) \
		$(use_with quotas) $(use_with quotas sys-quotas) \
		$(use_with readline) \
		$(use_with syslog) \
		$(use_with winbind) \
		${myconf} ${mylangs} ${mymod_shared} || die "econf failed"

	emake -j1 proto || die "emake proto failed"
	emake -j1 everything || die "emake everything failed"

}

src_test() {
	cd "${S}/source"
	emake test || die "tests failed"
}

src_install() {
	cd "${S}/source"

	emake -j1 DESTDIR="${D}" install-everything || die "emake install-everything failed"

	# Extra rpctorture progs
	local extra_bins="rpctorture"
	for i in ${extra_bins} ; do
		[[ -x "${S}/bin/${i}" ]] && dobin "${S}/bin/${i}"
	done

	# remove .old stuff from /usr/bin:
	rm -f "${D}"/usr/bin/*.old

	# Removing executable bits from header-files
	fperms 644 /usr/include/libsmbclient.h

	# Nsswitch extensions. Make link for wins and winbind resolvers
	if use winbind ; then
		dolib.so nsswitch/libnss_wins.so
		dosym libnss_wins.so /usr/$(get_libdir)/libnss_wins.so.2
		dolib.so nsswitch/libnss_winbind.so
		dosym libnss_winbind.so /usr/$(get_libdir)/libnss_winbind.so.2
	fi

	# bug #46389: samba doesn't create symlink anymore
	# beaviour seems to be changed in 3.0.6, see bug #61046
	dosym samba/libsmbclient.so /usr/$(get_libdir)/libsmbclient.so
	dosym samba/libsmbclient.so.0 /usr/$(get_libdir)/libsmbclient.so.0
	dosym samba/libtalloc.so /usr/$(get_libdir)/libtalloc.so
	dosym samba/libtalloc.so.1 /usr/$(get_libdir)/libtalloc.so.1
	dosym samba/libtdb.so /usr/$(get_libdir)/libtdb.so
	dosym samba/libtdb.so.1 /usr/$(get_libdir)/libtdb.so.1
	dosym samba/libwbclient.so.0 /usr/$(get_libdir)/libwbclient.so.0
	dosym samba/libsmbsharemodes.so.0 /usr/$(get_libdir)/libsmbsharemodes.so.0

	# make the smb backend symlink for cups printing support (bug #133133)
	if use cups ; then
		dodir $(cups-config --serverbin)/backend
		dosym /usr/bin/smbspool $(cups-config --serverbin)/backend/smb
	fi

	cd "${S}/source"

	# General config files
	insinto /etc/samba
	doins "${CONFDIR}"/{smbusers,lmhosts}
	newins "${CONFDIR}/smb.conf.example-samba3" smb.conf.example

	newpamd "${CONFDIR}/samba.pam" samba
	use winbind && dopamd "${CONFDIR}/system-auth-winbind"
	if use swat ; then
		insinto /etc/xinetd.d
		newins "${CONFDIR}/swat.xinetd" swat
	else
		rm -f "${D}/usr/sbin/swat"
		rm -f "${D}/usr/share/man/man8/swat.8"
	fi

	newinitd "${FILESDIR}/samba-init" samba
	newconfd "${FILESDIR}/samba-conf" samba

	if use ldap ; then
		insinto /etc/openldap/schema
		doins "${S}/examples/LDAP/samba.schema"
	fi

	if use ipv6 ; then
		insinto /etc/xinetd.d
		newins "${FILESDIR}/samba-xinetd" smb
	fi

	# dirs
	diropts -m0700 ; keepdir "${PRIVATE_DST}"
	diropts -m1777 ; keepdir /var/spool/samba

	diropts -m0755
	keepdir /var/{log,run,cache}/samba
	keepdir /var/lib/samba/{netlogon,profiles}
	keepdir /var/lib/samba/printers/{W32X86,WIN40,W32ALPHA,W32MIPS,W32PPC,X64,IA64,COLOR}
	keepdir /usr/$(get_libdir)/samba/{rpc,idmap,auth}

	# docs
	dodoc "${FILESDIR}/README.gentoo"
	dodoc "${S}"/{MAINTAINERS,README,Roadmap,WHATSNEW.txt}
	dodoc "${CONFDIR}/nsswitch.conf-wins"
	use winbind && dodoc "${CONFDIR}/nsswitch.conf-winbind"

	if use examples ; then
		insinto /usr/share/doc/${PF}
		doins -r "${S}/examples/"
		find "${D}/usr/share/doc/${PF}" -type d -print0 | xargs -0 chmod 755
		find "${D}/usr/share/doc/${PF}/examples" ! -type d -print0 | xargs -0 chmod 644
	fi

	if ! use doc ; then
		if ! use swat ; then
			rm -rf "${D}/usr/share/doc/${PF}/swat"
		else
			rm -rf "${D}/usr/share/doc/${PF}/swat/help"/{guide,howto,devel}
			rm -rf "${D}/usr/share/doc/${PF}/swat/using_samba"
		fi
	fi

}

pkg_preinst() {
	local PRIVATE_SRC=/etc/samba/private
	if [[ ! -r "${ROOT}/${PRIVATE_DST}/secrets.tdb" \
		&& -r "${ROOT}/${PRIVATE_SRC}/secrets.tdb" ]] ; then
		ebegin "Copying ${ROOT}/${PRIVATE_SRC}/* to ${ROOT}/${PRIVATE_DST}/"
			mkdir -p "${D}/${PRIVATE_DST}"
			cp -pPRf "${ROOT}/${PRIVATE_SRC}"/* "${D}/${PRIVATE_DST}/"
		eend $?
	fi

	if [[ ! -f "${ROOT}/etc/samba/smb.conf" ]] ; then
		touch "${D}/etc/samba/smb.conf"
	fi
}

pkg_postinst() {
	if use swat ; then
		einfo "swat must be enabled by xinetd:"
		einfo "  change the /etc/xinetd.d/swat configuration"
	fi

	if use ipv6 ; then
		einfo "ipv6 support must be enabled by xinetd:"
		einfo "  change the /etc/xinetd.d/smb configuration"
	fi

	elog "It is possible to start/stop daemons separately:"
	elog "  Create a symlink from /etc/init.d/samba.{smbd,nmbd,winbind} to"
	elog "  /etc/init.d/samba. Calling /etc/init.d/samba directly will start"
	elog "  the daemons configured in /etc/conf.d/samba"

	elog "The mount/umount.cifs helper applications are not included anymore."
	elog "Please install net-fs/mount-cifs instead."

	ewarn "If you're upgrading from 3.0.24 or earlier, please make sure to"
	ewarn "restart your clients to clear any cached information about the server."
	ewarn "Otherwise they might not be able to connect to the volumes."
}
