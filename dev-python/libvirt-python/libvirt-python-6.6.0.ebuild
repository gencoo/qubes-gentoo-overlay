
EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )

inherit eutils multilib distutils-r1 rpm

MY_PR=2
MY_PF=${P}-${MY_PR}
SRC_URI="https://mirrors.tuna.tsinghua.edu.cn/qubesos/repo/yum/r4.1/current-testing/dom0/fc32/rpm/${MY_PF}.fc32.src.rpm"

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
