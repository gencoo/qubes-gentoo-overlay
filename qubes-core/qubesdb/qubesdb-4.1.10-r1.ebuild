
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
	MY_P=qubes-db-${PV}
	SRC_URI="${REPO_URI}/${MY_P}-${MY_PR}.${DIST}.src.rpm"
	S=$WORKDIR/${MY_P}
fi

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

src_prepare() {
	default
}

src_compile() {
	export PYTHONDONTWRITEBYTECODE=
	myopt="${myopt} DESTDIR=${D} PYTHON=/usr/bin/python LIBDIR=/usr/$(get_libdir) BINDIR=/usr/bin SBINDIR=/usr/sbin"
	emake ${myopt} all
}

src_install() {
	emake ${myopt} install

	dodir /usr/lib/systemd/system/
	insopts -m 0644
	insinto /usr/lib/systemd/system/
	doins daemon/qubes-db-dom0.service
}

pkg_postinst() {
	systemctl enable qubes-db-dom0.service
}

pkg_postrm() {
	systemctl disable qubes-db-dom0.service
}
