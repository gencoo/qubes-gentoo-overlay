
EAPI=7

PYTHON_COMPAT=( python3_{6,8,9} )

inherit eutils multilib distutils-r1 qubes

KEYWORDS="amd64"
HOMEPAGE="http://www.qubes-os.org"
LICENSE="GPLv2"

SLOT="0"
IUSE=""

DEPEND="dev-python/setuptools[${PYTHON_USEDEP}]
        dev-python/sphinx[${PYTHON_USEDEP}]
	dev-python/lxml[${PYTHON_USEDEP}]
        dev-python/dbus-python[${PYTHON_USEDEP}]
	dev-python/pyyaml[${PYTHON_USEDEP}]
	sys-fs/inotify-tools
	dev-python/xcffib[${PYTHON_USEDEP}]
        ${PYTHON_DEPS}
        "
RDEPEND="${DEPEND}
	dev-python/python-daemon[${PYTHON_USEDEP}]
	dev-python/docutils[${PYTHON_USEDEP}]
	dev-python/scrypt[${PYTHON_USEDEP}]
	net-misc/socat"
PDEPEND=""

src_configure() {
	PYTHON="/usr/bin/python3"
	pyconf="${pyconf} PYTHON=${PYTHON} SPHINXBUILD=sphinx-build"
}

src_compile() {
        emake  -C doc $pyconf man
}

src_install() {
	rm -rf build
	emake install PYTHON=${PYTHON} DESTDIR="${D}"
	emake -C doc DESTDIR="${D}" $pyconf install
}

