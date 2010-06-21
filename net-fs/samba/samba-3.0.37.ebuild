# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-fs/samba/samba-3.0.37.ebuild,v 1.8 2010/04/25 15:42:48 arfrever Exp $

inherit autotools eutils pam python multilib versionator confutils

VSCAN_P="samba-vscan-0.3.6c-beta5"
MY_P=${PN}-${PV/_/}

DESCRIPTION="A suite of SMB and CIFS client/server programs for UNIX"
HOMEPAGE="http://www.samba.org/"
SRC_URI="mirror://samba/${MY_P}.tar.gz
	mirror://samba/old-versions/${MY_P}.tar.gz
	oav? ( http://www.openantivirus.org/download/${VSCAN_P}.tar.gz )"
LICENSE="GPL-3 oav? ( GPL-2 LGPL-2.1 )"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~sparc-fbsd ~x86-fbsd"
IUSE="acl ads async automount caps cups debug doc examples ipv6 kernel_linux ldap fam
	pam python quotas readline selinux swat syslog winbind oav"

RDEPEND="dev-libs/popt
	virtual/libiconv
	acl?       ( virtual/acl )
	cups?      ( net-print/cups )
	ipv6?      ( sys-apps/xinetd )
	ads?       ( virtual/krb5 )
	ldap?      ( net-nds/openldap )
	pam?       ( virtual/pam )
	python?    ( dev-lang/python )
	readline?  ( sys-libs/readline )
	selinux?   ( sec-policy/selinux-samba )
	swat?      ( sys-apps/xinetd )
	syslog?    ( virtual/logger )
	fam?       ( virtual/fam )
	caps?      ( sys-libs/libcap )"
DEPEND="${RDEPEND}"

# Tests are broken now :-(
RESTRICT="test"

S=${WORKDIR}/${MY_P}
CONFDIR=${FILESDIR}/config
PRIVATE_DST=/var/lib/samba/private

pkg_setup() {
	confutils_use_depend_all ads ldap
}

src_unpack() {
	unpack ${A}
	cd "${S}/source"

	# lazyldflags.patch: adds "-Wl,-z,now" to smb{mnt,umount}
	# invalid-free-fix.patch: Bug #196015 (upstream: #5021)

	epatch \
		"${FILESDIR}/3.0.26a-lazyldflags.patch" \
		"${FILESDIR}/3.0.26a-invalid-free-fix.patch" \
		"${FILESDIR}/3.0.28-fix_broken_readdir_detection.patch" \
		"${FILESDIR}/3.0.28a-wrong_python_ldflags.patch"

	eautoconf -I. -Ilib/replace

	# Ok, agreed, this is ugly. But it avoids a patch we
	# need for every samba version and we don't need autotools
	sed -i \
		-e 's|"lib32" ||' \
		-e 's|if test -d "$i/$l" ;|if test -d "$i/$l" -o -L "$i/$l";|' \
		configure || die "sed failed"

	rm "${S}/docs/manpages"/{mount,umount}.cifs.8

}

src_compile() {
	cd "${S}/source"

	local myconf
	local mylangs
	local mymod_shared

	myconf="--with-python=no"
	use python && myconf="--with-python=$(PYTHON -a)"

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
		--with-cifsmount=no \
		$(use_with acl acl-support) \
		$(use_with async aio-support) \
		$(use_with automount) \
		$(use_enable cups) \
		$(use_enable debug) \
		$(use_enable fam) \
		$(use_with ads krb5) \
		$(use_with ldap) \
		$(use_with pam) $(use_with pam pam_smbpass) \
		$(use_with quotas) $(use_with quotas sys-quotas) \
		$(use_with readline) \
		$(use_with kernel_linux smbmount) \
		$(use_with syslog) \
		$(use_with winbind) \
		${myconf} ${mylangs} ${mymod_shared}

	emake -j1 proto || die "emake proto failed"
	emake -j1 everything || die "emake everything failed"

	if use python ; then
		emake -j1 python_ext || die "emake python_ext failed"
	fi

	if use oav ; then
		# maintainer-info:
		# - there are no known releases of mks or kavdc,
		#   setting to builtin to disable auto-detection
		cd "${WORKDIR}/${VSCAN_P}"
		econf \
			--with-fhs \
			--with-samba-source="${S}/source" \
			--with-libmksd-builtin \
			--with-libkavdc-builtin \
			--without-symantec \
			--with-filetype \
			--with-fileregexp \
			$(use_enable debug)
		emake -j1 || die "emake oav plugins failed"
	fi
}

src_test() {
	cd "${S}/source"
	emake test || die "tests failed"
}

src_install() {
	cd "${S}/source"

	emake DESTDIR="${D}" install-everything || die "emake install-everything failed"

	# Extra rpctorture progs
	local extra_bins="rpctorture"
	for i in ${extra_bins} ; do
		[[ -x "${S}/bin/${i}" ]] && dobin "${S}/bin/${i}"
	done

	# remove .old stuff from /usr/bin:
	rm -f "${D}"/usr/bin/*.old

	# Removing executable bits from header-files
	fperms 644 /usr/include/lib{msrpc,smbclient}.h

	# Nsswitch extensions. Make link for wins and winbind resolvers
	if use winbind ; then
		dolib.so nsswitch/libnss_wins.so
		dosym libnss_wins.so /usr/$(get_libdir)/libnss_wins.so.2
		dolib.so nsswitch/libnss_winbind.so
		dosym libnss_winbind.so /usr/$(get_libdir)/libnss_winbind.so.2
	fi

	if use kernel_linux ; then
		# Warning: this can byte you if /usr is
		# on a separate volume and you have to mount
		# a smb volume before the local mount
		dosym ../usr/bin/smbmount /sbin/mount.smbfs
		fperms 4755 /usr/bin/smbmnt
		fperms 4755 /usr/bin/smbumount
	fi

	# bug #46389: samba doesn't create symlink anymore
	# beaviour seems to be changed in 3.0.6, see bug #61046
	dosym samba/libsmbclient.so /usr/$(get_libdir)/libsmbclient.so.0
	dosym samba/libsmbclient.so /usr/$(get_libdir)/libsmbclient.so

	# make the smb backend symlink for cups printing support (bug #133133)
	if use cups ; then
		dodir $(cups-config --serverbin)/backend
		dosym /usr/bin/smbspool $(cups-config --serverbin)/backend/smb
	fi

	if use python ; then
		emake DESTDIR="${D}" python_install || die "emake installpython failed"
		# We're doing that manually
		find "${D}$(python_get_sitedir)" -iname "*.pyc" -delete
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
		if use python ; then
			insinto /usr/share/doc/${PF}/python
			doins -r "${S}/source/python/examples"
		fi
	fi

	if ! use doc ; then
		if ! use swat ; then
			rm -rf "${D}/usr/share/doc/${PF}/swat"
		else
			rm -rf "${D}/usr/share/doc/${PF}/swat/help"/{guide,howto,devel}
			rm -rf "${D}/usr/share/doc/${PF}/swat/using_samba"
		fi
	else
		cd "${S}/docs"
		insinto /usr/share/doc/${PF}
		doins *.pdf
		doins -r registry
		dohtml -r htmldocs/*
	fi

	if use oav ; then
		cd "${WORKDIR}/${VSCAN_P}"
		emake DESTDIR="${D}" install || die "emake install oav plugins failed"
		docinto samba-vscan
		dodoc AUTHORS ChangeLog FAQ INSTALL NEWS README TODO
		find . -iname "*.conf" -print0 | xargs -0 dodoc
	fi
}

pkg_preinst() {
	local PRIVATE_SRC=/etc/samba/private
	if [[ ! -r "${ROOT}/${PRIVATE_DST}/secrets.tdb" \
		&& -r "${ROOT}/${PRIVATE_SRC}/secrets.tdb" ]] ; then
		ebegin "Copying "${ROOT}"/${PRIVATE_SRC}/* to ${ROOT}/${PRIVATE_DST}/"
			mkdir -p "${D}/${PRIVATE_DST}"
			cp -pPRf "${ROOT}/${PRIVATE_SRC}"/* "${D}/${PRIVATE_DST}/"
		eend $?
	fi

	if [[ ! -f "${ROOT}/etc/samba/smb.conf" ]] ; then
		touch "${D}/etc/samba/smb.conf"
	fi
}

pkg_postinst() {
	if use python ; then
		python_mod_optimize $(python_get_sitedir)/samba
	fi

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

	if use oav ; then
		elog "The configure snippets for various antivirus plugins are available here:"
		elog "  /usr/share/doc/${PF}/samba-vscan"
	fi

	ewarn "If you're upgrading from 3.0.24 or earlier, please make sure to"
	ewarn "restart your clients to clear any cached information about the server."
	ewarn "Otherwise they might not be able to connect to the volumes."
}

pkg_postrm() {
	if use python ; then
		python_mod_cleanup $(python_get_sitedir)/samba
	fi
}
