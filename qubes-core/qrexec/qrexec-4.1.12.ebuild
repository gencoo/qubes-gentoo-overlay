
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
	MY_PR=1
	MY_PF=${Q}-${PN}-dom0-${PV}-${MY_PR}
	SRC_URI="https://mirrors.tuna.tsinghua.edu.cn/qubesos/repo/yum/r4.1/current-testing/dom0/fc32/rpm/${MY_PF}.fc32.src.rpm"
	S=$WORKDIR/${Q}-${P}
fi

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

pkg_prerm() {
	systemctl disable qubes-qrexec-policy-daemon.service
}

pkg_postrm() {
	systemctl try-restart qubes-qrexec-policy-daemon.service
}
