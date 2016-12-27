# Distributed under the terms of the GNU General Public License v2

EAPI=6
inherit linux-info

DESCRIPTION="Daemon for Advanced Configuration and Power Interface"
HOMEPAGE="https://sourceforge.net/projects/acpid2"
SRC_URI="mirror://sourceforge/${PN}2/${P}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ia64 ~x86"
IUSE="selinux"

RDEPEND="selinux? ( sec-policy/selinux-apm )"
DEPEND=">=sys-kernel/linux-headers-3"

pkg_pretend() {
	local CONFIG_CHECK="~INPUT_EVDEV"
	local WARNING_INPUT_EVDEV="CONFIG_INPUT_EVDEV is required for ACPI button event support."
	[[ ${MERGE_TYPE} != buildonly ]] && check_extra_config
}

pkg_setup() { :; }

PATCHES=(
	"${FILESDIR}"/${PV}/rename-gnome-power-management-system-process.patch #FL-1329
	"${FILESDIR}"/${PV}/add-cinnamon-power-management-system-process.patch #FL-1439
	"${FILESDIR}"/${PV}/${PN}-2.0.25-kde4.patch #515088
)

src_install() {
	emake DESTDIR="${D}" install

	newdoc kacpimon/README README.kacpimon
	dodoc -r samples
	rm -f "${D}"/usr/share/doc/${PF}/COPYING || die

	exeinto /etc/acpi
	newexe "${FILESDIR}"/${PV}/${PN}-1.0.6-default.sh-r2 default.sh
	exeinto /etc/acpi/actions
	newexe samples/powerbtn/powerbtn.sh powerbtn.sh
	insinto /etc/acpi/events
	newins "${FILESDIR}"/${PV}/${PN}-1.0.4-default default

	newinitd "${FILESDIR}"/${PV}/${PN}-2.0.26-init.d ${PN}
	newconfd "${FILESDIR}"/${PV}/${PN}-2.0.16-conf.d ${PN}

}

pkg_postinst() {
	if [[ -z ${REPLACING_VERSIONS} ]]; then
		elog
		elog "You may wish to read the Gentoo Linux Power Management Guide,"
		elog "which can be found online at:"
		elog "https://wiki.gentoo.org/wiki/Power_management/Guide"
		elog
	fi

}
