
EAPI=7

PYTHON_COMPAT=( python3_{6,8,9} )

inherit distutils-r1

SRC_URI="https://github.com/CabbageDevelopment/qasync/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

KEYWORDS="amd64"
HOMEPAGE="http://www.qubes-os.org"
LICENSE="GPLv2"

SLOT="0"
IUSE=""

DEPEND="dev-python/setuptools[${PYTHON_USEDEP}]
        ${PYTHON_DEPS}
        "
RDEPEND="${DEPEND}"
PDEPEND=""
