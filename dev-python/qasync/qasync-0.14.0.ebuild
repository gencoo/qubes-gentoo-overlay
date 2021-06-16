
EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )

inherit eutils multilib distutils-r1

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

src_prepare() {
	default
}

src_compile() {
	export PYTHONDONTWRITEBYTECODE=
	py_opts="${py_opts} /usr/bin/python setup.py"
	${py_opts} build
}

src_install() {
	${py_opts} install --skip-build --root=${D}
} 
