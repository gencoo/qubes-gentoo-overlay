
EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )

inherit eutils multilib distutils-r1
Q=qubes-gui
Q_PN=${Q}-${PN}
if [[ ${PV} == *9999 ]]; then
	inherit qubes
	EGIT_REPO_URI="https://github.com/QubesOS/${Q_PN}.git"
	S=$WORKDIR/${Q_PN}
else
	inherit rpm
	MY_PR=${PVR##*r}
	MY_P=${Q_PN}-devel-${PV}
	SRC_URI="${REPO_URI}/${MY_P}-${MY_PR}.${DIST}.src.rpm"
	S=$WORKDIR/${MY_P}
fi

KEYWORDS="amd64"
HOMEPAGE="http://www.qubes-os.org"
LICENSE="GPLv2"

SLOT="0"
IUSE=""

DEPEND=""
RDEPEND=""
PDEPEND=""

S=$WORKDIR/${MY_P}

src_configure() { :; }

src_compile() { :; }

src_install() {
    insinto 'usr/include'
    doins 'include/qubes-gui-protocol.h'
    doins 'include/qubes-xorg-tray-defs.h'
}
