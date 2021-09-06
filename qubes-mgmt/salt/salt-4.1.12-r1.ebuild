
EAPI=7

PYTHON_COMPAT=( python3_{6,8,9} )

inherit eutils multilib distutils-r1 qubes

KEYWORDS="amd64"
HOMEPAGE="http://www.qubes-os.org"
LICENSE="GPLv2"

SLOT="0"
IUSE="pandoc-bin"

DEPEND="dev-python/setuptools[${PYTHON_USEDEP}]
	dev-python/pyyaml[${PYTHON_USEDEP}]
	app-text/tree
        pandoc-bin? (
            app-text/pandoc-bin
        )
        !pandoc-bin? (
            app-text/pandoc
        )
        ${PYTHON_DEPS}
        "
RDEPEND="${DEPEND}
	qubes-mgmt/salt-base
	app-admin/salt
	"
PDEPEND=""

src_configure() { :; }

src_install() {
	export PYTHONDONTWRITEBYTECODE=
	emake install DESTDIR="${D}" LIBDIR=/usr/$(get_libdir) BINDIR=/usr/bin SBINDIR=/usr/sbin SYSCONFDIR=/etc PYTHON="/usr/bin/python3"
	emake install-dom0 DESTDIR="${D}" PYTHON="/usr/bin/python3"
	dodir /etc/salt/minion.d
	echo -n dom0 > "${D}"/etc/salt/minion_id

	dosym ../minion.dom0.conf /etc/salt/minion.d/minion.dom0.conf

	fowners -R root:qubes /srv/{formulas,pillar,reactor,salt}
	fperms -R 750 /srv/{formulas,pillar,reactor,salt}
}

