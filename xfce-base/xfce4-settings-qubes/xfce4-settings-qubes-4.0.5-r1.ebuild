
EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )

inherit git-r3 eutils rpm

if [[ ${PV} == *9999 ]]; then
	EGIT_COMMIT=HEAD
	EGIT_REPO_URI="https://github.com/QubesOS/qubes-desktop-linux-xfce4.git"
else
	MY_PR=${PVR##*r}
	MY_PF=${P}-${MY_PR}
	SRC_URI="${REPO_URI}/${MY_PF}.${DIST}.src.rpm"
fi

KEYWORDS="amd64"
DESCRIPTION="The Qubes GUI Agent for AppVMs"
HOMEPAGE="http://www.qubes-os.org"
LICENSE="GPLv2"

SLOT="0"
IUSE=" "

DEPEND=""
RDEPEND="xfce-base/xfce4-meta
	xfce-base/garcon
	xfce-extra/xfce4-notifyd
	xfce-base/xfce4-panel
	x11-misc/xss-lock
	qubes-misc/artwork
	sys-apps/util-linux"
PDEPEND=""

src_prepare() {
	default
}

src_configure() { :; }

src_install() {
	export PYTHONDONTWRITEBYTECODE=
	emake install DESTDIR="${D}" INSTALL="/usr/bin/install -p"
	elog 'One of "xfce4-panel xfce4-settings xfce4-session xfce4-power-manager libxfce4ui xscreensaver-base" reinstall or upgrade,you need reinstall xfce4-settings-qubes.'
}

settings_replace(){
	qubesfile="$1"
	origfile=${qubesfile%.qubes}
	backupfile=${origfile}.xfce4
	if [ -r "$origfile" ] && [ ! -r "$backupfile" ]; then
		mv -f "$origfile" "$backupfile"
	fi
	cp -f "$qubesfile" "$origfile"
}

pkg_postinst() {
	#triggerin -- xfce4-panel
	settings_replace /etc/xdg/xfce4/panel/default.xml.qubes


	#triggerin -- xfce4-settings
	settings_replace /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml.qubes


	#triggerin -- xfce4-session
	settings_replace /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml.qubes


	#triggerin -- xfce4-power-manager
	settings_replace /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-power-manager.xml.qubes


	#triggerin -- libxfce4ui
	settings_replace /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml.qubes


	#triggerin -- xscreensaver-base

	conffile=/etc/xscreensaver/XScreenSaver.ad.tail

	if ! grep -q "! Qubes options begin" $conffile; then
    		( echo -e "! Qubes options begin - do not edit\n! Qubes options end"; cat $conffile) > $conffile.tmp
    		mv $conffile.tmp $conffile
	fi

	sed -e '/! Qubes options begin/,/! Qubes options end/c \
		! Qubes options begin - do not edit\
		*newLoginCommand:\
		*fade: False\
		! Qubes options end' -i $conffile

	update-xscreensaver-hacks
}

pkg_prerm() {
	REPLACEFILE="${REPLACEFILE} /etc/xdg/xfce4/panel/default.xml.qubes"
	REPLACEFILE="${REPLACEFILE} /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml.qubes"
	REPLACEFILE="${REPLACEFILE} /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml.qubes"
	REPLACEFILE="${REPLACEFILE} /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-power-manager.xml.qubes"
	REPLACEFILE="${REPLACEFILE} /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml.qubes"

	for file in ${REPLACEFILE}; do
		origfile=${file%.qubes}
		backupfile=${origfile}.xfce4
		mv -f "$backupfile" "$origfile"
	done
}
