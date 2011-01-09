# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-admin/collectd/collectd-4.10.2-r2.ebuild,v 1.1 2010/12/21 21:14:24 dilfridge Exp $

EAPI="2"

inherit eutils base linux-info perl-app autotools

DESCRIPTION="A small daemon which collects system performance statistics - with a near-infinite number of plugins"
HOMEPAGE="http://collectd.org"
SRC_URI="${HOMEPAGE}/files/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="contrib debug kernel_linux kernel_FreeBSD kernel_Darwin"

# The plugin lists have to follow here since they extend IUSE

# Plugins that to my knowledge cannot be supported (eg. dependencies not in gentoo)
COLLECTD_IMPOSSIBLE_PLUGINS="netapp pinba xmms"

# Plugins that still need some work
COLLECTD_UNTESTED_PLUGINS="ipvs apple_sensors routeros tape zfs_arc nut modbus"

# Plugins that have been (compile) tested and can be enabled via COLLECTD_PLUGINS
COLLECTD_TESTED_PLUGINS="apache apcups ascent battery bind conntrack contextswitch
	cpu cpufreq curl curl_json curl_xml dbi df disk dns email entropy exec filecount fscache gmond
	hddtemp interface ipmi iptables irq java libvirt load madwifi mbmon memcachec
	memcached memory multimeter mysql netlink network nfs nginx ntpd olsrd
	onewire openvpn perl ping postgresql powerdns processes protocols python
	rrdcached sensors serial snmp swap table tail tcpconns teamspeak2 ted thermal
	tokyotyrant uptime users vmem vserver wireless csv exec logfile network
	notify_desktop notify_email oracle perl python rrdcached rrdtool syslog unixsock write_http
	match_empty_counter match_hashed match_regex match_timediff match_value
	target_notification target_replace target_scale target_set uuid"

COLLECTD_DISABLED_PLUGINS="${COLLECTD_IMPOSSIBLE_PLUGINS} ${COLLECTD_UNTESTED_PLUGINS}"

COLLECTD_ALL_PLUGINS=${COLLECTD_TESTED_PLUGINS}

for plugin in ${COLLECTD_ALL_PLUGINS}; do
	IUSE="${IUSE} collectd_plugins_${plugin}"
done
unset plugin

# Now come the dependencies.

COMMON_DEPEND="
	collectd_plugins_apache?		( net-misc/curl )
	collectd_plugins_ascent?		( net-misc/curl dev-libs/libxml2 )
	collectd_plugins_bind?			( dev-libs/libxml2 )
	collectd_plugins_curl?			( net-misc/curl )
	collectd_plugins_curl_json?		( net-misc/curl dev-libs/yajl )
	collectd_plugins_curl_xml?		( net-misc/curl dev-libs/libxml2 )
	collectd_plugins_dbi?			( dev-db/libdbi )
	collectd_plugins_dns?			( net-libs/libpcap )
	collectd_plugins_gmond?			( sys-cluster/ganglia )
	collectd_plugins_ipmi?			( >=sys-libs/openipmi-2.0.16-r1 )
	collectd_plugins_iptables?		( >=net-firewall/iptables-1.4.9.1-r2 )
	collectd_plugins_java?			( virtual/jre dev-java/java-config-wrapper )
	collectd_plugins_libvirt?		( app-emulation/libvirt dev-libs/libxml2 )
	collectd_plugins_memcachec?		( dev-libs/libmemcached )
	collectd_plugins_mysql?			( >=virtual/mysql-5.0 )
	collectd_plugins_netlink?		( >=sys-apps/iproute2-2.6.34 )
	collectd_plugins_network?		( dev-libs/libgcrypt )
	collectd_plugins_nginx?			( net-misc/curl )
	collectd_plugins_notify_desktop?	( x11-libs/libnotify )
	collectd_plugins_notify_email?		( >=net-libs/libesmtp-1.0.4 dev-libs/openssl )
	collectd_plugins_onewire?		( sys-fs/owfs )
	collectd_plugins_oracle?		( >=dev-db/oracle-instantclient-basic-11.2.0.1.0 )
	collectd_plugins_perl?			( dev-lang/perl[ithreads] ( || ( sys-devel/libperl[ithreads] >=sys-devel/libperl-5.10 ) ) )
	collectd_plugins_ping?			( net-libs/liboping )
	collectd_plugins_postgresql?		( >=dev-db/postgresql-base-8.2 )
	collectd_plugins_python?		( =dev-lang/python-2* )
	collectd_plugins_rrdcached?		( >=net-analyzer/rrdtool-1.4 )
	collectd_plugins_rrdtool?		( >=net-analyzer/rrdtool-1.2.27 )
	collectd_plugins_sensors?		( sys-apps/lm_sensors )
	collectd_plugins_snmp?			( net-analyzer/net-snmp )
	collectd_plugins_tokyotyrant?		( net-misc/tokyotyrant )
	collectd_plugins_uuid? 			( sys-apps/hal )
	collectd_plugins_write_http?		( net-misc/curl )

	kernel_FreeBSD?	(
		collectd_plugins_disk?		( >=sys-libs/libstatgrab-0.16 )
		collectd_plugins_interface?	( >=sys-libs/libstatgrab-0.16 )
		collectd_plugins_load?		( >=sys-libs/libstatgrab-0.16 )
		collectd_plugins_memory?	( >=sys-libs/libstatgrab-0.16 )
		collectd_plugins_swap?		( >=sys-libs/libstatgrab-0.16 )
		collectd_plugins_users?		( >=sys-libs/libstatgrab-0.16 )
	)"

DEPEND="${COMMON_DEPEND}
	dev-util/pkgconfig
	kernel_linux?	(
		collectd_plugins_vserver?	( sys-kernel/vserver-sources )
	)"

RDEPEND="${COMMON_DEPEND}
	collectd_plugins_syslog?		( virtual/logger )"

PATCHES=( "${FILESDIR}/${PN}-4.10.1"-{libperl,libiptc,noowniptc}.patch
	"${FILESDIR}/${P}"-libocci.patch )

# @FUNCTION: collectd_plugin_kernel_linux
# @DESCRIPTION:
# USAGE: <plug-in name> <kernel_options> <severity>
# kernel_options is a list of kernel configurations options; the check tests whether at least
#   one of them is enabled. If no, depending on the third argument an elog, ewarn, or eerror message
#   is emitted.
collectd_plugin_kernel_linux() {
	local multi_opt opt
	if has ${1} ${COLLECTD_ALL_PLUGINS}; then
		if use collectd_plugins_${1}; then
			for opt in ${2}; do
				if linux_chkconfig_present ${opt}; then return 0; fi
			done
			multi_opt=${2//\ /\ or\ }
			case ${3} in
				(info)
					elog "The ${1} plug-in can use kernel features that are disabled now; enable ${multi_opt} in your kernel"
				;;
				(warn)
					ewarn "The ${1} plug-in uses kernel features that are disabled now; enable ${multi_opt} in your kernel"
				;;
				(error)
					eerror "The ${1} plug-in needs kernel features that are disabled now; enable ${multi_opt} in your kernel"
				;;
				(*)
					die "function collectd_plugin_kernel_linux called with invalid third argument"
				;;
			esac
		fi
	fi
}

collectd_linux_kernel_checks() {
	linux-info_pkg_setup

	# battery.c:/proc/pmu/battery_%i
	# battery.c:/proc/acpi/battery
	collectd_plugin_kernel_linux battery ACPI_BATTERY warn

	# cpufreq.c:/sys/devices/system/cpu/cpu%d/cpufreq/
	collectd_plugin_kernel_linux cpufreq SYSFS warn
	collectd_plugin_kernel_linux cpufreq CPU_FREQ_STAT warn

	# nfs.c:/proc/net/rpc/nfs
	# nfs.c:/proc/net/rpc/nfsd
	collectd_plugin_kernel_linux nfs NFS_COMMON warn

	# serial.c:/proc/tty/driver/serial
	# serial.c:/proc/tty/driver/ttyS
	collectd_plugin_kernel_linux serial SERIAL_CORE warn

	# swap.c:/proc/meminfo
	collectd_plugin_kernel_linux swap SWAP warn

	# thermal.c:/proc/acpi/thermal_zone
	# thermal.c:/sys/class/thermal
	collectd_plugin_kernel_linux thermal "PROC_FS SYSFS" warn
	collectd_plugin_kernel_linux thermal ACPI_THERMAL warn

	# vmem.c:/proc/vmstat
	collectd_plugin_kernel_linux vmem VM_EVENT_COUNTERS warn

	# uuid.c:/sys/hypervisor/uuid
	collectd_plugin_kernel_linux uuid SYSFS info

	# wireless.c:/proc/net/wireless
	collectd_plugin_kernel_linux wireless "MAC80211 IEEE80211" warn
}

pkg_setup() {
	if use kernel_linux; then
		if linux_config_exists; then
			einfo "Checking your linux kernel configuration:"
			collectd_linux_kernel_checks
		else
			elog "Cannot find a linux kernel configuration. Continuing anyway."
		fi
	fi

	enewgroup collectd
}

src_prepare() {
	base_src_prepare

	# There's some strange prefix handling in the default config file, resulting in
	# paths like "/usr/var/..."
	sed -i -e "s:@prefix@/var:/var:g" src/collectd.conf.in || die

	eautoreconf
}

src_configure() {
	# Now come the lists of os-dependent plugins. Any plugin that is not listed anywhere here
	# should work independent of the operating system.

	local linux_plugins="battery cpu cpufreq disk entropy interface iptables ipvs irq load
		memory netlink nfs processes serial swap tcpconns thermal users vmem vserver
		wireless"

	local libstatgrab_plugins="cpu disk interface load memory swap users"
	local bsd_plugins="cpu tcpconns ${libstatgrab_plugins}"

	local darwin_plugins="apple_sensors battery cpu disk interface memory processes tcpconns"

	local osdependent_plugins="${linux_plugins} ${bsd_plugins} ${darwin_plugins}"
	local myos_plugins=""
	if use kernel_linux; then
		einfo "Enabling Linux plugins."
		myos_plugins=${linux_plugins}
	elif use kernel_FreeBSD; then
		einfo "Enabling FreeBSD plugins."
		myos_plugins=${bsd_plugins}
	elif use kernel_Darwin; then
		einfo "Enabling Darwin plugins."
		myos_plugins=${darwin_plugins}
	fi

	# Do we debug?
	local myconf="$(use_enable debug)"

	local plugin

	# Disable what needs to be disabled.
	for plugin in ${COLLECTD_DISABLED_PLUGINS}; do
		myconf+=" --disable-${plugin}"
	done

	# Set enable/disable for each single plugin.
	for plugin in ${COLLECTD_ALL_PLUGINS}; do
		if has ${plugin} ${osdependent_plugins}; then
			# plugin is os-dependent ...
			if has ${plugin} ${myos_plugins}; then
				# ... and available in this os
				myconf+=" $(use_enable collectd_plugins_${plugin} ${plugin})"
			else
				# ... and NOT available in this os
				if use collectd_plugins_${plugin}; then
					ewarn "You try to enable the ${plugin} plugin, but it is not available for this"
					ewarn "kernel. Disabling it automatically."
				fi
				myconf+=" --disable-${plugin}"
			fi
		else
			myconf+=" $(use_enable collectd_plugins_${plugin} ${plugin})"
		fi
	done

	# Need JAVA_HOME for java.
	if use collectd_plugins_java; then
		myconf+=" --with-java=$(java-config -g JAVA_HOME)"
	fi

	# Need libiptc ONLY for iptables. If we try to use it otherwise bug 340109 happens.
	if ! use collectd_plugins_iptables; then
		myconf+=" --with-libiptc=no"
	fi

	# Finally, run econf.
	KERNEL_DIR="${KERNEL_DIR}" econf --config-cache --without-included-ltdl --localstatedir=/var ${myconf}
}

src_install() {
	emake DESTDIR="${D}" install || die

	fixlocalpod

	dodoc AUTHORS ChangeLog NEWS README TODO || die

	if use contrib ; then
		insinto /usr/share/doc/${PF}
		doins -r contrib || die
	fi

	keepdir /var/lib/${PN} || die

	newinitd "${FILESDIR}/${PN}.initd" ${PN} || die
	newconfd "${FILESDIR}/${PN}.confd" ${PN} || die

	insinto /etc/logrotate.d
	newins "${FILESDIR}/logrotate" collectd || die
}

collectd_rdeps() {
	if (use collectd_plugins_${1} && ! has_version "${2}"); then
		elog "The ${1} plug-in needs ${2} to be installed locally or remotely to work."
	fi
}

pkg_postinst() {
	collectd_rdeps apcups sys-power/apcupsd
	collectd_rdeps hddtemp app-admin/hddtemp
	collectd_rdeps mbmon sys-apps/xmbmon
	collectd_rdeps memcached ">=net-misc/memcached-1.2.2-r2"
	collectd_rdeps ntpd net-misc/ntp
	collectd_rdeps openvpn ">=net-misc/openvpn-2.0.9"

	if use collectd_plugins_email; then
		ewarn "The email plug-in is deprecated. To submit statistics please use the unixsock plugin."
	fi
	if use contrib; then
		elog "The scripts in /usr/share/doc/${PF}/collection3 for generating graphs need dev-perl/HTML-Parser,"
		elog "dev-perl/config-general, dev-perl/regexp-common, and net-analyzer/rrdtool[perl] to be installed."
	fi
}
