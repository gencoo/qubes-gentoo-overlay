
EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )

inherit eutils distutils-r1 qubes

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
