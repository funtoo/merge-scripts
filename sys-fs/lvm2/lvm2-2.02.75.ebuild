# Distributed under the terms of the GNU General Public License v2

EAPI="2"
inherit multilib autotools flag-o-matic toolchain-funcs

DESCRIPTION="User-land utilities for LVM2 (device-mapper) software."
HOMEPAGE="http://sources.redhat.com/lvm2/"
SRC_URI="ftp://sources.redhat.com/pub/lvm2/${PN/lvm/LVM}.${PV}.tgz
		 ftp://sources.redhat.com/pub/lvm2/old/${PN/lvm/LVM}.${PV}.tgz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"

IUSE="rc_enable"

RDEPEND=">=sys-fs/udev-151-r4 !<sys-fs/cryptsetup-1.1.2"
DEPEND="${RDEPEND} dev-util/pkgconfig"
MYDIR="$FILESDIR/2.02.70"

S="${WORKDIR}/${PN/lvm/LVM}.${PV}"

src_prepare() {
	#cat $MYDIR/patches/lvm2-2.02.65-libdir.patch | patch -p1 || die "patch failed"
	eautoreconf
}

src_configure() {

	# --with-dmeventd path for bug #312321

	filter-ldflags -Wl,--as-needed --as-needed
	./configure \
	--enable-lvm1_fallback \
	--enable-static_link \
	--enable-fsadm \
	--with-pool=internal \
	--with-user= --with-group= \
	--with-usrlibdir=/usr/$(get_libdir) \
	--with-usrsbindir=/usr/sbin \
	--with-device-uid=0 --with-device-gid=6 \
	--with-device-mode=0660 \
	--enable-applib --enable-cmdlib \
	--enable-dmeventd \
	--with-dmeventd-path=/sbin/dmeventd \
	--enable-udev_sync \
	--with-udevdir=/$(get_libdir)/udev/rules.d/ \
	--disable-selinux --libdir=/$(get_libdir) --enable-pkgconfig \
	--disable-readline \
	CFLAGS="-fPIC -O2" CLDFLAGS="${LDFLAGS}" || die "configure failed"
}

src_compile() {
	emake || die "build failed"
}

src_install() {
	make install DESTDIR="$D" || die "install failed"

	# missing goodies:

	dosbin "${S}"/scripts/lvm2create_initrd/lvm2create_initrd || die
	doman  "${S}"/scripts/lvm2create_initrd/lvm2create_initrd.8 || die
	newdoc "${S}"/scripts/lvm2create_initrd/README README.lvm2create_initrd || die

	# docs:

	dodoc README VERSION WHATS_NEW doc/*.{conf,c,txt}

	# For now, we are deprecating dmtab until a man page can be provided for it.

	# the following add-ons are used by the initscripts:

	insinto /$(get_libdir)/rcscripts/addons
	for addon in lvm-start lvm-stop dm-start
	do
		doins "${MYDIR}/${addon}.sh" || die
	done

	# install initscripts and corresponding conf.d files:

	for rc in lvm device-mapper dmeventd lvm-monitoring
	do
		newinitd "${MYDIR}/${rc}.rc" ${rc} || die
		if [ -e "${MYDIR}/${rc}.confd" ] 
		then
			newconfd "${MYDIR}/${rc}.confd" ${rc} || die
		fi
	done

	# do not rely on /lib -> /libXX link on multilib systems:

	sed -e "s-/lib/rcscripts/-/$(get_libdir)/rcscripts/-" -i "${D}"/etc/init.d/* || die

}

add_init() {
	local runl=$1
	shift
	if [ ! -e ${ROOT}etc/runlevels/${runl} ]
	then
		install -d -m0755 ${ROOT}etc/runlevels/${runl}
	fi
	for initd in $*
	do
		einfo "Auto-adding '${initd}' service to your ${runl} runlevel"
		[[ -e ${ROOT}etc/runlevels/${runl}/${initd} ]] && continue
		[[ ! -e ${ROOT}etc/init.d/${initd} ]] && die "initscript $initd not found; aborting"
		ln -snf /etc/init.d/${initd} "${ROOT}etc/runlevels/${runl}/${initd}"
	done
}

pkg_postinst() {
	if use rc_enable; then
		einfo
		add_init boot device-mapper lvm
		einfo
		einfo "Type \"rc\" to enable new services."
		echo
	fi
}
