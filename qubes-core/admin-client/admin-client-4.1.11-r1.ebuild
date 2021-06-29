
EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )

inherit eutils multilib distutils-r1
Q=qubes-core
if [[ ${PV} == *9999 ]]; then
	inherit qubes
	EGIT_COMMIT=HEAD
	Q_PN=${Q}-${PN}
	EGIT_REPO_URI="https://github.com/QubesOS/${Q_PN}.git"
	S=$WORKDIR/${Q_PN}
else
	inherit rpm
	MY_PR=${PVR##*r}
	MY_P=${Q}-${P}
	SRC_URI="${REPO_URI}/${MY_P}-${MY_PR}.${DIST}.src.rpm"
	S=$WORKDIR/${MY_P}
fi

KEYWORDS="amd64"
HOMEPAGE="http://www.qubes-os.org"
LICENSE="GPLv2"

SLOT="0"
IUSE=""

DEPEND="dev-python/setuptools[${PYTHON_USEDEP}]
        dev-python/sphinx[${PYTHON_USEDEP}]
	dev-python/lxml
        dev-python/dbus-python[${PYTHON_USEDEP}]
	dev-python/pyyaml
	sys-fs/inotify-tools
	dev-python/xcffib
        ${PYTHON_DEPS}
        "
RDEPEND="${DEPEND}
	dev-python/python-daemon
	dev-python/docutils
	dev-python/scrypt
	net-misc/socat"
PDEPEND=""

src_prepare() {
	default
}

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

