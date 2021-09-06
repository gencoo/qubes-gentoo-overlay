
EAPI=7

PYTHON_COMPAT=( python3_{6,8,9} )

inherit eutils python-single-r1 qubes

KEYWORDS="amd64"
HOMEPAGE="http://www.qubes-os.org"
LICENSE="GPLv2"

SLOT="0"
IUSE=""

DEPEND=""

RDEPEND="${DEPEND}
	qubes-mgmt/salt
	"
PDEPEND=""

src_compile() { :; }

src_install() {
	emake install DESTDIR="${D}" LIBDIR=/usr/$(get_libdir) BINDIR=/usr/bin SBINDIR=/usr/sbin SYSCONFDIR=/etc
}

