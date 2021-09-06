
EAPI=7

PYTHON_COMPAT=( python3_{6,8,9} )

inherit eutils multilib distutils-r1 qubes

KEYWORDS="amd64"
DESCRIPTION="The Qubes qrexec files (qube side)"
HOMEPAGE="http://www.qubes-os.org"
LICENSE="GPLv2"

SLOT="0"
IUSE="+pandoc-bin socket"

DEPEND="dev-python/setuptools[${PYTHON_USEDEP}]
        dev-python/sphinx[${PYTHON_USEDEP}]
        dev-python/dbus-python[${PYTHON_USEDEP}]
	dev-python/recommonmark[${PYTHON_USEDEP}]
        sys-libs/pam
        qubes-core/libvchan
        socket? ( qubes-core/libvchan[socket] )
        pandoc-bin? (
            app-text/pandoc-bin
        )
        !pandoc-bin? (
            app-text/pandoc
        )
        ${PYTHON_DEPS}
        "
RDEPEND="${DEPEND}
	qubes-core/admin
	dev-python/gbulb"
PDEPEND=""

src_prepare() {
	eapply ${FILESDIR}/print.patch
	default
}

src_compile() {
	export PYTHONDONTWRITEBYTECODE=
	export BACKEND_VMM=xen
	use socket && export BACKEND_VMM=socket
	
	emake all-base PYTHON=/usr/bin/python BACKEND_VMM=${BACKEND_VMM}
	emake all-dom0 BACKEND_VMM=${BACKEND_VMM}
}

src_install() {
  myopt="${myopt} DESTDIR=${D} \
	UNITDIR=/usr/lib/systemd/system \
	INCLUDEDIR=/usr/include \
	LIBDIR=/usr/$(get_libdir) \
	PYTHON=/usr/bin/python \
	PYTHON_SITEPATH=${sitedir} \
	BACKEND_VMM=${BACKEND_VMM} \
	SYSCONFDIR=/etc"
	
	emake install-base ${myopt} 
	emake install-dom0 ${myopt}

	fowners root:qubes /etc/qubes-rpc/policy
	chmod 2775  ${D}/etc/qubes-rpc/policy
}

pkg_postinst() {
	systemctl enable qubes-qrexec-policy-daemon.service
}

pkg_postrm() {
	systemctl restart qubes-qrexec-policy-daemon.service
}
