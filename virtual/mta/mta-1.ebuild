# Distributed under the terms of the GNU General Public License v2

EAPI=4

DESCRIPTION="Virtual for Message Transfer Agents"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0"
KEYWORDS="*"
IUSE=""

DEPEND=""

# mail-mta/citadel is from sunrise
RDEPEND="|| (	mail-mta/postfix	
				mail-mta/nullmailer
				mail-mta/msmtp[mta]
				mail-mta/ssmtp[mta]
				mail-mta/courier
				mail-mta/esmtp
				mail-mta/exim
				mail-mta/mini-qmail
				mail-mta/netqmail
				mail-mta/qmail-ldap
				mail-mta/sendmail
				mail-mta/opensmtpd
				mail-mta/citadel[-postfix] )"
