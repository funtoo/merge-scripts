# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit vcs-snapshot games

DESCRIPTION="The main game for the Minetest game engine"
HOMEPAGE="http://github.com/minetest/minetest_game"
SRC_URI="http://github.com/minetest/minetest_game/tarball/${PV} -> ${P}.tar.gz"

LICENSE="GPL-2 CC-BY-SA-3.0"
SLOT="0"
KEYWORDS="*"
IUSE=""

RDEPEND="~games-action/minetest-${PV}[-dedicated]"

src_unpack() {
	vcs-snapshot_src_unpack
}

src_install() {
	insinto "${GAMES_DATADIR}"/minetest/games/${PN}
	doins -r mods menu
	doins game.conf minetest.conf

	dodoc README.txt game_api.txt

	prepgamesdirs
}
