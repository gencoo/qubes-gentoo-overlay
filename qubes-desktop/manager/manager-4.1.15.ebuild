
EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )

inherit eutils multilib distutils-r1

Q=qubes
if [[ ${PV} == *9999 ]]; then
	inherit qubes
	Q_PN=${Q}-${PN}
	EGIT_REPO_URI="https://github.com/QubesOS/${Q_PN}.git"
	S=$WORKDIR/${Q_PN}
else
	inherit rpm
	MY_PR=1
	MY_P=${Q}-${P}
	SRC_URI="https://mirrors.tuna.tsinghua.edu.cn/qubesos/repo/yum/r4.1/current-testing/dom0/fc32/rpm/${MY_P}-${MY_PR}.fc32.src.rpm"
	S=$WORKDIR/${MY_P}
fi

KEYWORDS="amd64"
HOMEPAGE="http://www.qubes-os.org"
LICENSE="GPLv2"

SLOT="0"
IUSE=""

DEPEND="dev-python/PyQt5
	dev-qt/qtgui
	dev-qt/linguist-tools
        "
RDEPEND="${DEPEND}
	dev-python/pyinotify
	qubes-core/admin
	dev-python/qasync
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
