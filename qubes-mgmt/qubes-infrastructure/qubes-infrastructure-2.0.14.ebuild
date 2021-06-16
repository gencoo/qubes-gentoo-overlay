
EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )

inherit eutils python-single-r1

if [[ ${PV} == *9999 ]]; then
	inherit qubes
	EGIT_REPO_URI="https://github.com/QubesOS/${Q_PN}.git"
	S=$WORKDIR/${PN}
else
	inherit rpm
	MY_PR=1
	MY_P=qubes-mgmt-salt-dom0-${P}
	SRC_URI="https://mirrors.tuna.tsinghua.edu.cn/qubesos/repo/yum/r4.1/current-testing/dom0/fc32/rpm/${MY_P}-${MY_PR}.fc32.src.rpm"
	S=$WORKDIR/${MY_P}
fi

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

