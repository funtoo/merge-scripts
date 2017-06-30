# Distributed under the terms of the GNU General Public License v2

EAPI=5

DESCRIPTION="Virtual for mail implementations"
SLOT="0"
KEYWORDS="*"

RDEPEND="|| (	net-mail/mailutils
				mail-client/mailx
				mail-client/nail
				mail-client/s-nail
				sys-freebsd/freebsd-ubin )"
