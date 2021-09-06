
EAPI=7

PYTHON_COMPAT=( python3_{6,8,9} )

inherit eutils multilib distutils-r1 systemd qubes

KEYWORDS="amd64"
DESCRIPTION="QubesDB libs and daemon service"
HOMEPAGE="http://www.qubes-os.org"
LICENSE="GPLv2"

SLOT="0"
IUSE=""

DEPEND="qubes-core/libvchan
        ${PYTHON_DEPS}
        "
RDEPEND="${DEPEND}"
PDEPEND=""

src_compile() {
	export PYTHONDONTWRITEBYTECODE=
	myopt="${myopt} DESTDIR=${D} PYTHON=/usr/bin/python LIBDIR="${EPREFIX}"/usr/$(get_libdir) BINDIR=/usr/bin SBINDIR=/usr/sbin"
	emake ${myopt} all
}

src_install() {
	emake ${myopt} install

	into /usr/lib/systemd/system/
	systemd_dounit daemon/qubes-db-dom0.service
}

pkg_postinst() {
	systemctl enable qubes-db-dom0.service
}

pkg_postrm() {
	systemctl disable qubes-db-dom0.service
}
