
EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )

inherit eutils distutils-r1

if [[ ${PV} == *9999 ]]; then
	inherit qubes
	EGIT_COMMIT=HEAD
	EGIT_REPO_URI="https://github.com/QubesOS/qubes-${PN}.git"
	S=$WORKDIR/qubes-${PN}
else
	inherit rpm
	MY_PR=1
	MY_PF=${P}-${MY_PR}
	SRC_URI="https://mirrors.tuna.tsinghua.edu.cn/qubesos/repo/yum/r4.1/current-testing/dom0/fc32/rpm/${MY_PF}.fc32.src.rpm"
fi

KEYWORDS="amd64"
HOMEPAGE="http://www.qubes-os.org"
LICENSE="GPLv2"

SLOT="0"
IUSE=""

DEPEND="dev-libs/json-c"
RDEPEND="dev-python/pyudev"
PDEPEND=""

src_configure() { :; }

src_compile() {
	emake client
}

src_install() {
	export PYTHONDONTWRITEBYTECODE=
	emake install  DESTDIR=${D} INSTALL="/usr/lib/portage/python3.8/ebuild-helpers/xattr/install -p"
	rm ${D}/usr/lib/systemd/system/module-load-dummy-psu.service
}

pkg_postinst() {
	systemctl enable qubes-psu-client@.service
}
