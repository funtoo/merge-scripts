# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sci-biology/repeatmasker/repeatmasker-3.2.7.ebuild,v 1.2 2009/08/17 19:41:31 weaver Exp $

inherit versionator

MY_PV=$(replace_all_version_separators '-')

DESCRIPTION="Screen DNA sequences for interspersed repeats and low complexity DNA"
HOMEPAGE="http://repeatmasker.org/"
SRC_URI="http://www.repeatmasker.org/RepeatMasker-open-${MY_PV}.tar.gz"

LICENSE="OSL-2.1"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND=""
RDEPEND="sci-biology/phrap
	sci-biology/trf
	>=sci-biology/repeatmasker-libraries-20090120"

S="${WORKDIR}/RepeatMasker"

src_compile() {
	sed -i -e 's/system( "clear" );//' \
		-e 's|> \($rmLocation/Libraries/RepeatMasker.lib\)|> '${D}'/\1|' "${S}/configure" || die
	echo "
env
/usr/share/${PN}
/usr/bin
1
/usr/bin
Y
4" | "${S}/configure" || die "configure failed"
	sed -i -e 's|use lib $FindBin::RealBin;|use lib "/usr/share/'${PN}'/lib";|' \
		-e 's|".*\(taxonomy.dat\)"|"/usr/share/'${PN}'/\1"|' \
		-e '/$REPEATMASKER_DIR/ s|$FindBin::RealBin|/usr/share/'${PN}'|' \
		"${S}"/{DateRepeats,ProcessRepeats,RepeatMasker,DupMasker,RepeatProteinMask,RepeatMaskerConfig.pm,Taxonomy.pm} || die
}

src_install() {
	exeinto /usr/share/${PN}
	for i in DateRepeats ProcessRepeats RepeatMasker DupMasker RepeatProteinMask; do
		doexe $i
		dosym /usr/share/${PN}/$i /usr/bin/$i
	done

	dodir /usr/share/${PN}/lib
	insinto /usr/share/${PN}/lib
	doins "${S}"/*.pm

	insinto /usr/share/${PN}
	doins -r util Matrices Libraries taxonomy.dat
	keepdir /usr/share/${PN}/Libraries

	dodoc README INSTALL *.help
}
