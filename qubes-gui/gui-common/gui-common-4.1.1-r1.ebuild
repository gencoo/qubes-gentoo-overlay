
EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )

inherit eutils multilib distutils-r1 qubes

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
    insinto /usr/include
    doins -r include/qubes-{gui-protocol,xorg-tray-defs}.h
}
