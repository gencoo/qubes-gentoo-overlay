
EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )

inherit eutils multilib distutils-r1 qubes

KEYWORDS="amd64"
HOMEPAGE="http://www.qubes-os.org"
LICENSE="GPLv2"

SLOT="0"
IUSE=""

DEPEND="dev-python/PyQt5[${PYTHON_USEDEP}]
	dev-qt/qtgui
	dev-qt/linguist-tools
        "
RDEPEND="${DEPEND}
	dev-python/pyinotify[${PYTHON_USEDEP}]
	qubes-core/admin
	dev-python/qasync[${PYTHON_USEDEP}]
	qubes-desktop/linux-common
	qubes-misc/artwork
	sys-apps/pmount
	sys-fs/cryptsetup
	x11-misc/wmctrl
	"
PDEPEND=""

src_compile() {
	export PYTHONDONTWRITEBYTECODE=
	emake ui res translations PYTHON=/usr/bin/python
	emake python PYTHON=/usr/bin/python
}

src_install() {
	emake python_install DESTDIR=${D} PYTHON=/usr/bin/python
	emake install DESTDIR=${D} PYTHON=/usr/bin/python
}

pkg_postinst() {
	update-desktop-database &> /dev/null || :
}

pkg_prerm() {
	update-desktop-database &> /dev/null || :
}
