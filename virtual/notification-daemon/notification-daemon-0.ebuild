# Distributed under the terms of the GNU General Public License v2

EAPI=5

DESCRIPTION="Virtual for notification daemon dbus service"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0"
KEYWORDS="*"
IUSE="gnome xfce"

RDEPEND="
	gnome? ( || ( x11-misc/notification-daemon
		gnome-base/gnome-shell ) )
	!gnome? ( || (
	xfce? ( xfce-extra/xfce4-notifyd )
		x11-misc/notification-daemon
		gnome-extra/cinnamon
		x11-misc/qtnotifydaemon
		x11-misc/notify-osd
		x11-misc/dunst
		>=x11-wm/awesome-3.4.4
		x11-wm/enlightenment[enlightenment_modules_notification]
		x11-wm/enlightenment[e_modules_notification]
		kde-apps/knotify
		x11-misc/mate-notification-daemon
		lxqt-base/lxqt-notificationd
		kde-frameworks/knotifications ) )"
DEPEND=""
