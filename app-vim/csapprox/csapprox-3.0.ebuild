
VIM_PLUGIN_VIM_VERSION=7.0
inherit vim-plugin

DESCRIPTION="vim plugin: bring GVim colorschemes to the terminal."
HOMEPAGE="http://www.vim.org/scripts/script.php?script_id=2390"
SRC_URI="http://www.vim.org/scripts/download_script.php?src_id=9849"
KEYWORDS="~amd64 ~x86"
LICENSE=""
IUSE=""

MY_PN="CSApprox"

VIM_PLUGIN_HELPTEXT=\
"This plugin works best with a terminal that 
has 256 color support and is configured to use it.
To see the number of colors supported in your current terminal, issue
  tput colors
For rxvt-unicode, you will need a newer version with 'xterm-color' USE enabled.
You will also need to follow a guide like this:
  http://scie.nti.st/2008/10/13/get-rxvt-unicode-with-256-color-support-on-ubunut
For GNU Screen, you will need to add 'term xterm-256color' to your ~/.screenrc "

# gvim provides a gui enabled version of /usr/bin/vim, needed for csapprox
RDEPEND="!app-editors/vim >=app-editors/gvim-${VIM_PLUGIN_VIM_VERSION}"
DEPEND="${RDEPEND} app-arch/unzip"
S="${WORKDIR}"

src_unpack(){
	unzip "${DISTDIR}/${A}" || die "unpack failed"
}
