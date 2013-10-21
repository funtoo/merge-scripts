# Distributed under the terms of the GNU General Public License v2

EAPI=4

DESCRIPTION="Virtual package for FFmpeg implementation"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0"
KEYWORDS="~*"
IUSE="X +encode gsm jpeg2k mp3 opus sdl speex theora threads truetype vaapi vdpau x264"

RDEPEND=">=media-video/ffmpeg-1.0:0[X?,encode?,gsm?,jpeg2k?,mp3?,opus?,sdl?,speex?,theora?,threads?,truetype?,vaapi?,vdpau?,x264?]"
DEPEND=""
