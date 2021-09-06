
EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )

inherit git-r3 eutils

EGIT_COMMIT=HEAD
EGIT_REPO_URI="https://github.com/QubesOS/qubes-meta-packages.git"

KEYWORDS="amd64"
DESCRIPTION="metapackage"
HOMEPAGE="http://www.qubes-os.org"
LICENSE="GPLv2"

SLOT="0"
IUSE="+xfce xfce-extra hardware-support"

DEPEND=""
RDEPEND="
	app-arch/rpm
	xfce? (
		xfce-extra? (
			xfce-extra/xfce4-battery-plugin
			xfce-extra/xfce4-cpugraph-plugin 
			xfce-extra/xfce4-diskperf-plugin
			xfce-extra/xfce4-eyes-plugin
			xfce-extra/xfce4-fsguard-plugin
			xfce-extra/xfce4-genmon-plugin
			xfce-extra/xfce4-mailwatch-plugin
			xfce-extra/xfce4-mount-plugin		
			xfce-extra/xfce4-sensors-plugin
			xfce-extra/xfce4-systemload-plugin
			xfce-extra/xfce4-time-out-plugin
			xfce-extra/xfce4-timer-plugin
			xfce-extra/xfce4-verve-plugin
			xfce-extra/xfce4-xkb-plugin
		)
		xfce-base/linux-xfce4
		x11-misc/lightdm[gtk]
		xfce-extra/xfce4-datetime-plugin
		xfce-extra/xfce4-places-plugin
		xfce-extra/xfce4-pulseaudio-plugin
		xfce-extra/xfce4-screensaver
		xfce-extra/xfce4-screenshooter
		xfce-extra/xfce4-taskmanager
		x11-terms/xfce4-terminal
		x11-apps/xsm
		x11-wm/twm
		x11-apps/xclock
		x11-terms/xterm
		x11-misc/xdg-utils
		sys-fs/mdadm
		sys-fs/multipath-tools
		net-misc/dhcpcd
		media-sound/pavucontrol
	)
	hardware-support? (
		app-laptop/i8kutils
		sys-power/acpitool
		sys-firmware/alsa-firmware
		app-admin/hddtemp
		sys-apps/hdparm
		media-libs/libifp
		sys-fs/lsscsi
		dev-libs/openct
		dev-libs/opensc
		sys-apps/pcsc-lite
	)
	sys-fs/quota
	app-admin/rsyslog
	sys-apps/smartmontools
	app-admin/sudo
	app-misc/symlinks
	sys-process/time
	app-admin/tmpwatch
	app-text/tree
	sys-apps/usbutils
	sys-apps/hwids
	gui-libs/display-manager-init
	app-editors/vim-core[minimal]
	app-editors/vim
	qubes-core/admin
	qubes-gui/gui-daemon
	qubes-desktop/manager
	qubes-desktop/linux-manager
	qubes-app/gpg-split
	qubes-app/img-converter
	qubes-app/usb-proxy
	app-emulation/libvirt
	dev-python/libvirt-python
	app-emulation/xen
	qubes-mgmt/salt
	qubes-mgmt/salt-dom0-qvm
	qubes-misc/grub2
	qubes-misc/grub2-xen
	qubes-mgmt/salt-dom0-virtual-machines
	qubes-misc/qubes-release
	qubes-mgmt/infrastructure
	"
PDEPEND=""

src_prepare() {
	default
}

src_install() {
	# comps file
	install -d -m 755 ${D}/usr/share/qubes
	install -m 644 comps/comps-dom0.xml ${D}/usr/share/qubes/qubes-comps.xml
	mkdir -p ${D}/etc/conf.d/
	use xfce && cp ${FILESDIR}/display-manager ${D}/etc/conf.d/
}

pkg_postinst() {
	use xfce && systemctl enable lightdm
	systemctl enable pulseaudio
	systemctl disable libvirt-guests salt-minion
	hostnamectl set-hostname dom0
	ln -s /usr/share/misc /usr/share/hwdata
}
