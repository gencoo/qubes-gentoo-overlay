
EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )

inherit eutils multilib distutils-r1 rpm

MY_PR=${PVR##*r}
MY_PF=${P}-${MY_PR}
SRC_URI="${REPO_URI}/${MY_PF}.${DIST}.src.rpm"

KEYWORDS="amd64"
HOMEPAGE="http://www.qubes-os.org"
LICENSE="GPLv2"

SLOT="0"
IUSE=""

DEPEND="qubes-core/libvchan
	app-emulation/libvirt
	dev-python/nose
	dev-python/lxml
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
	sleep 1
}

src_test() {
	${py_opts} setup.py test
}


src_install() {
	${py_opts} install --skip-build --root=${D}
}
