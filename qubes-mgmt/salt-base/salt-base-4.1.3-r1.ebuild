
EAPI=7

PYTHON_COMPAT=( python3_{6,8,9} )

inherit eutils multilib python-single-r1 qubes

KEYWORDS="amd64"
HOMEPAGE="http://www.qubes-os.org"
LICENSE="GPLv2"

SLOT="0"
IUSE=""

DEPEND=""
RDEPEND="qubes-mgmt/salt-base-topd
	qubes-mgmt/salt-base-config
	"
PDEPEND=""

src_compile() {
	export PYTHONDONTWRITEBYTECODE=
	emake DESTDIR="${D}" LIBDIR=/usr/$(get_libdir) BINDIR=/usr/bin SBINDIR=/usr/sbin SYSCONFDIR=/etc PYTHON="/usr/bin/python3"
}

src_install() {
	emake install DESTDIR="${D}" LIBDIR=/usr/$(get_libdir) BINDIR=/usr/bin SBINDIR=/usr/sbin SYSCONFDIR=/etc PYTHON="/usr/bin/python3"

	fowners -R root:root /srv/salt/_* && fperms -R 750 /srv/salt/ _*
}

pkg_postinst() {
	# Update Salt Configuration
	qubesctl saltutil.clear_cache -l quiet --out quiet > /dev/null || true
	qubesctl saltutil.sync_all refresh=true -l quiet --out quiet > /dev/null || true
}

