
EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )

inherit eutils qubes

KEYWORDS="amd64"
HOMEPAGE="http://www.qubes-os.org"
LICENSE="GPLv2"

SLOT="0"
IUSE=""

DEPEND="sys-devel/make"
RDEPEND=""
PDEPEND=""

src_configure() { :; }
src_compile() { :; }

src_install() {
	export PYTHONDONTWRITEBYTECODE=
	emake install  DESTDIR=${D} INSTALL="/usr/lib/portage/python3.8/ebuild-helpers/xattr/install -p"
	dosym /etc/udev/rules.d/90-backlight.rules /lib/udev/rules.d/90-backlight.rules
	rm ${D}/etc/udev/rules.d/80-qubes-backlight.rules
}
