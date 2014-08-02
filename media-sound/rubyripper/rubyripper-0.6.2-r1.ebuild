# Distributed under the terms of the GNU General Public License v2

EAPI="5"

VIRTUALX_REQUIRED=gtk
VIRTUALX_COMMAND=./configure
USE_RUBY="ruby18 ruby19"

inherit ruby-ng virtualx

DESCRIPTION="A secure audio ripper for Linux"
HOMEPAGE="http://code.google.com/p/rubyripper"
SRC_URI="http://${PN}.googlecode.com/files/${P}.tar.bz2"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="*"
IUSE="cli cdrdao flac +gtk +mp3 normalize +vorbis wav"

ILINGUAS="bg de es fr hu it nl ru se"

for lingua in $ILINGUAS; do
	IUSE="${IUSE} linguas_${lingua}"
done

RDEPEND="media-sound/cdparanoia
	media-sound/cd-discid
	virtual/eject
	cdrdao? ( app-cdr/cdrdao )
	flac? ( media-libs/flac )
	vorbis? ( media-sound/vorbis-tools )
	mp3? ( media-sound/lame )
	wav? ( media-sound/wavpack )
	normalize? ( media-sound/normalize )
	wav? ( media-sound/wavegain )
	vorbis? ( media-sound/vorbisgain )
	mp3? ( media-sound/mp3gain )"
DEPEND="${RDEPEND}"

ruby_add_rdepend ">=dev-ruby/ruby-gettext-2.1.0-r1
	gtk? ( >=dev-ruby/ruby-gtk2-0.19.3 )"

# fix for bug 203737
RUBY_PATCHES=( "${FILESDIR}/${PN}-0.5.2-require-rubygems.patch" )

each_ruby_configure() {
	local myconf=--prefix=/usr
	local enable_linguas

	for lingua in $ILINGUAS; do
		use linguas_$lingua && enable_linguas="${enable_linguas},${lingua}"
	done

	[[ -n ${enable_linguas} ]] && myconf="${myconf} --enable-lang=${enable_linguas#,}"

	use gtk && myconf="${myconf} --enable-gtk2"
	use cli && myconf="${myconf} --enable-cli"

	virtualmake ${myconf}
}

each_ruby_install() {
	default
}
