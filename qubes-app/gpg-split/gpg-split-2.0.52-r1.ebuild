
EAPI=7

PYTHON_COMPAT=( python3_{6,8,9} )

DISTUTILS_USE_SETUPTOOLS=no

inherit eutils distutils-r1 qubes

KEYWORDS="amd64"
DESCRIPTION="The Qubes service for secure gpg separation"
HOMEPAGE="http://www.qubes-os.org"
LICENSE="GPLv2"

SLOT="0"
IUSE="+pandoc-bin"
RESTRICT="test"
DEPEND="qubes-core/libvchan
        pandoc-bin? (
            app-text/pandoc-bin
        )
        !pandoc-bin? (
            app-text/pandoc
        )
	dev-python/setuptools[${PYTHON_USEDEP}]
        ${PYTHON_DEPS}
        "
RDEPEND="${DEPEND}"
PDEPEND=""

src_compile() { :; }

src_install() {
	insinto /etc/qubes-rpc/policy
	newins qubes.Gpg.policy qubes.Gpg
	newins qubes.GpgImportKey.policy qubes.GpgImportKey
}
