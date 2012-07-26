# Distributed under the terms of the GNU General Public License v2

EAPI=4-python

PYTHON_MULTIPLE_ABIS=1
PYTHON_RESTRICTED_ABIS="2.[45] 3.* *-jython *-pypy-*"

inherit distutils

if [ "$PV" = "9999" ]; then
	inherit git-2
	EGIT_REPO_URI="https://github.com/openstack/keystone.git"
else
	SRC_URI="http://launchpad.net/${PN}/essex/${PV}/+download/${P}.tar.gz"
fi

DESCRIPTION="Keystone is a cloud identity service written in Python, which
provides authentication, authorization, and an OpenStack service catalog. It
implements OpenStack's Identity API."
HOMEPAGE="https://launchpad.net/keystone"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="*"
IUSE="+doc"

DEPEND="$( python_abi_depend dev-python/setuptools dev-python/pep8 dev-python/lxml dev-python/python-daemon !dev-python/keystoneclient ) doc? ( dev-python/sphinx )"
RDEPEND="${DEPEND} $( python_abi_depend dev-python/python-novaclient dev-python/python-ldap dev-python/passlib dev-python/eventlet dev-python/routes dev-python/webob dev-python/sqlalchemy dev-python/sqlalchemy-migrate dev-python/prettytable dev-python/pastedeploy ) sys-auth/keystone-client"
# note above: sys-auth/keystone-client provides "keystone" binary, but "keystone" hooks into the server
# via API calls. Because of this de-coupling, not using python_abi_depend as it's not necessary for
# python versions to match (even though it's a good idea.)

src_compile() {
	distutils_src_compile
	if use doc; then
		cd ${S}/doc || die
		make man singlehtml || die
	fi
}

src_install() {
	distutils_src_install
	newconfd "${FILESDIR}/keystone.confd" keystone
	newinitd "${FILESDIR}/keystone.initd" keystone

	diropts -m 0750
	keepdir /var/run/keystone /var/log/keystone /etc/keystone

	dodoc -r ${S}/etc
	if use doc; then
		doman ${S}/doc/build/man/keystone.1
		dodoc -r ${S}/doc/build/singlehtml
	fi
	docompress -x /usr/share/doc/$PF/etc /usr/share/doc/$PF/scripts
	sed -i 's|^connection =.*|connection = sqlite:////etc/keystone/keystone.db|' ${S}/etc/keystone.conf.sample || die
	docinto etc
	dodoc ${S}/etc/keystone.conf.sample
	exeinto /usr/share/doc/$PF/scripts
	doexe ${FILESDIR}/keystone_data.sh
}

pkg_postinst() {
	if [ ! -e $ROOT/etc/keystone/keystone.conf ]; then
		einfo "Installing default keystone.conf"
		cp $ROOT/usr/share/doc/$PF/etc/keystone.conf.sample $ROOT/etc/keystone/keystone.conf
	fi
}

pkg_config() {
	export SERVICE_TOKEN=$(sed -ne 's/^[[:space:]]*admin_token[[:space:]]*=[[:space:]]*\([^[:space:]]*\)[:space:]*/\1/p' /etc/keystone/keystone.conf)
	[ -z "$SERVICE_TOKEN" ] && die "Please set an admin_token in /etc/keystone/keystone.conf and restart keystone to allow configuration to continue."
	einfo "Got admin_token (SERVICE_TOKEN) of '$SERVICE_TOKEN'"
	export SERVICE_ENDPOINT=http://127.0.0.1:35357/v2.0/
	keystone-manage db_sync || die "Could not perform initial database configuration."
	keystone tenant-list > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		die "Error connecting to Keystone API. Please ensure that you have added keystone to your current runlevel and started it."
	fi
	einfo "Please specify a password to use for the Keystone admin account:"
	read -rsp "    >" pwd1 ; echo

	einfo "Retype the password"
	read -rsp "    >" pwd2 ; echo

	if [[ "x$pwd1" != "x$pwd2" ]] ; then
		die "Passwords are not the same"
	fi
	export ADMIN_PASSWORD="${pwd1}"
	unset pwd1 pwd2
	einfo "Please specify a password to use for the Keystone service account:"
	read -rsp "    >" pwd1 ; echo

	einfo "Retype the password"
	read -rsp "    >" pwd2 ; echo

	if [[ "x$pwd1" != "x$pwd2" ]] ; then
		die "Passwords are not the same"
	fi
	export SERVICE_PASSWORD="${pwd1}"
	unset pwd1 pwd2
	einfo "Initializing Keystone database"
	/usr/share/doc/$PF/scripts/keystone_data.sh || die "Error initializing Keystone - please ensure you have an empty DB"
	einfo "Completed successfully!"
}
