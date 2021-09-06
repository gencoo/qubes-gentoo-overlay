
EAPI=7

PYTHON_COMPAT=( python3_{6,8,9} )

inherit eutils multilib distutils-r1 qubes

KEYWORDS="amd64"
DESCRIPTION="USBIP wrapper to run it over Qubes RPC connection"
HOMEPAGE="http://www.qubes-os.org"
LICENSE="GPLv2"

SLOT="0"
IUSE=""

DEPEND="sys-apps/usbutils
        ${PYTHON_DEPS}
        "
RDEPEND="${DEPEND}"
PDEPEND=""

src_install() {
	emake install-dom0 DESTDIR=${D}

	fowners root:qubes /etc/qubes-rpc/policy/qubes.USB
}
