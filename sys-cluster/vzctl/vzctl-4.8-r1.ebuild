# Distributed under the terms of the GNU General Public License v2

EAPI="5"

inherit base bash-completion-r1 eutils toolchain-funcs udev

DESCRIPTION="OpenVZ Containers control utility"
HOMEPAGE="http://openvz.org/"
SRC_URI="http://download.openvz.org/utils/${PN}/${PV}/src/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE="+ploop +vz-kernel +vzmigrate"

RDEPEND="net-firewall/iptables
		sys-apps/ed
		>=sys-apps/iproute2-3.3.0
		vz-kernel? ( >=sys-fs/vzquota-3.1 )
		ploop? (
			>=sys-cluster/ploop-1.12.1
			sys-block/parted
			sys-fs/quota
		)
		>=dev-libs/libcgroup-0.38
		vzmigrate? (
			net-misc/openssh
			net-misc/rsync[xattr,acl]
			app-arch/tar[xattr,acl]
		)
		app-misc/vzstats
		app-arch/xz-utils
		"

DEPEND="${RDEPEND}
	virtual/pkgconfig
	"

src_prepare() {
	# Set default OSTEMPLATE on gentoo
	sed -i -e 's:=redhat-:=funtoo-:' etc/dists/default || die 'sed on etc/dists/default failed'
	# Set proper udev directory
	sed -i -e "s:/lib/udev:$(get_udevdir):" src/lib/dev.c || die 'sed on src/lib/dev.c failed'
	epatch "${FILESDIR}"/${PN}-4.8-vz.conf.patch
}

src_configure() {
	econf \
		--localstatedir=/var \
		--enable-udev \
		--enable-bashcomp \
		--enable-logrotate \
		--with-vz \
		$(use_with ploop) \
		--with-cgroup
}

src_install() {
	emake DESTDIR="${D}" udevdir="$(get_udevdir)"/rules.d install install-gentoo

	# install the bash-completion script into the right location
	rm -rf "${ED}"/etc/bash_completion.d
	newbashcomp etc/bash_completion.d/vzctl.sh ${PN}

	# We need to keep some dirs
	keepdir /vz/{dump,lock,root,private,template/cache}
	keepdir /etc/vz/names /var/lib/vzctl/veip

	# enable bridge auto-add for veth devices:
	insinto /etc/vz
	doins ${FILESDIR}/vznet.conf
	#FL-1540. Restore ve-unlimited.conf-sample file
	insinto /etc/vz/conf
	doins ${FILESDIR}/ve-unlimited.conf-sample

	# install our tweaked Funtoo set-hostname script so FQDN gets set correctly:
	insinto /etc/vz/dists
	doins ${FILESDIR}/${PV}/funtoo.conf

	exeinto /etc/vz/dists/scripts
	doexe ${FILESDIR}/${PV}/funtoo-set_hostname.sh

	newinitd ${FILESDIR}/${PV}/vz.initd vz
}

pkg_postinst() {
	local conf_without_OSTEMPLATE
	for file in \
		$(find "${EROOT}/etc/vz/conf/" \( -name *.conf -a \! -name 0.conf \)); do
		if ! grep '^OSTEMPLATE' $file > /dev/null; then
			conf_without_OSTEMPLATE+=" $file"
		fi
	done

	if [[ -n ${conf_without_OSTEMPLATE} ]]; then
		ewarn
		ewarn "OSTEMPLATE default was changed from Red Hat to Funtoo."
		ewarn "This means that any VEID.conf files without explicit or correct"
		ewarn "OSTEMPLATE set will use Funtoo scripts instead of Red Hat."
		ewarn "Please check the following configs:"
		for file in ${conf_without_OSTEMPLATE}; do
			ewarn "${file}"
		done
		ewarn
	fi

	ewarn "Starting with 3.0.25 there is new vzeventd service to reboot CTs."
	ewarn "Please remove /usr/share/vzctl/scripts/vpsnetclean and"
	ewarn "/usr/share/vzctl/scripts/vpsreboot from crontab and use"
	ewarn "/etc/init.d/vzeventd."

	if ! has_version sys-process/criu; then
		einfo "If you want checkpoint suspend/restore feature in vanilla kernel"
		einfo "please install sys-process/criu."
		einfo "This is experimental and not stable (in Gentoo) at the moment."
	fi

	if ! has_version app-crypt/gnupg; then
		einfo "If you want to check the signature of donwloaded template, install app-crypt/gnupg."
	fi
	# TODO - when Funtoo has an OpenRC with "condrestart", add an 
	# /etc/init.d/vzeventd condrestart when ROOT = "/" to ensure that the
	# latest vzeventd is running. Not doing this can result in containers
	# not rebooting correctly after upgrade or other issues.
}
