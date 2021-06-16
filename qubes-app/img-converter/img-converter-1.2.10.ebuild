
EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )

inherit eutils multilib

Q=qubes-app-linux
if [[ ${PV} == *9999 ]]; then
	inherit qubes
	Q_PN=${Q}-${PN}
	EGIT_REPO_URI="https://github.com/QubesOS/${Q_PN}.git"
	S=$WORKDIR/${Q_PN}
else
	inherit rpm
	MY_PR=1
	MY_P=qubes-${PN}-dom0-${PV}
	SRC_URI="https://mirrors.tuna.tsinghua.edu.cn/qubesos/repo/yum/r4.1/current-testing/dom0/fc32/rpm/${MY_P}-${MY_PR}.fc32.src.rpm"
	S=$WORKDIR/${MY_P}
fi

KEYWORDS="amd64"
DESCRIPTION="The Qubes service for converting untrusted images into trusted ones"
HOMEPAGE="http://www.qubes-os.org"
LICENSE="GPLv2"

SLOT="0"
IUSE=""

DEPEND="qubes-misc/utils
        ${PYTHON_DEPS}
        "
RDEPEND="${DEPEND}"
PDEPEND=""

src_prepare() {
	export PYTHONDONTWRITEBYTECODE=
	default
}

src_install() {
#	emake install-vm DESTDIR=${D}
	install -d ${D}/usr/bin/
	install -D qvm-get-image ${D}/usr/bin/qvm-get-image
	install -D qvm-get-tinted-image ${D}/usr/bin/qvm-get-tinted-image
}
