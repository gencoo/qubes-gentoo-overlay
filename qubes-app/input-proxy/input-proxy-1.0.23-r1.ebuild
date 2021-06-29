
EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )

inherit eutils distutils-r1

Q=qubes-app-linux
if [[ ${PV} == *9999 ]]; then
	inherit qubes
	Q_PN=${Q}-${PN}
	EGIT_REPO_URI="https://github.com/QubesOS/${Q_PN}.git"
	S=$WORKDIR/${Q_PN}
else
	inherit rpm
	MY_PR=${PVR##*r}
	MY_P=qubes-${P}
	SRC_URI="${REPO_URI}/${MY_P}-${MY_PR}.${DIST}.src.rpm"
	S=$WORKDIR/${MY_P}
fi

KEYWORDS="amd64"
DESCRIPTION="Simple input device proxy"
HOMEPAGE="http://www.qubes-os.org"
LICENSE="GPLv2"

SLOT="0"
IUSE=""

DEPEND="sys-apps/usbutils
	dev-python/setuptools[${PYTHON_USEDEP}]
        ${PYTHON_DEPS}
        "
RDEPEND="${DEPEND}"
PDEPEND=""

src_prepare() {
	default
}

src_compile() {
	export PYTHONDONTWRITEBYTECODE=
	emake all
}

src_install() {
	emake ${myopt} install DESTDIR=${D} PYTHON=/usr/bin/python
	fdir="${D}/etc/qubes-rpc/policy/qubes.*"
	chown root:qubes $fdir && chmod 0664 $fdir
	rm -rf ${D}/usr/lib/systemd ${D}/lib/udev
	rm -rf ${D}/etc/sudoers.d ${D}/etc/xdg
}
