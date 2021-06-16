EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )

inherit eutils multilib python-single-r1

Q=qubes-mgmt
if [[ ${PV} == *9999 ]]; then
	inherit qubes
	Q_PN=${Q}-${PN}
	EGIT_REPO_URI="https://github.com/QubesOS/${Q_PN}.git"
	S=$WORKDIR/${Q_PN}
else
	inherit rpm
	MY_PR=1
	MY_P=${Q}-${P}
	SRC_URI="https://mirrors.tuna.tsinghua.edu.cn/qubesos/repo/yum/r4.1/current-testing/dom0/fc32/rpm/${MY_P}-${MY_PR}.fc32.src.rpm"
	S=$WORKDIR/${MY_P}
fi

KEYWORDS="amd64"
HOMEPAGE="http://www.qubes-os.org"
LICENSE="GPLv2"

SLOT="0"
IUSE="pandoc-bin"

DEPEND=""
        
RDEPEND="qubes-mgmt/salt
	qubes-mgmt/salt-base-topd
	"

PDEPEND=""

src_compile() {
	export PYTHONDONTWRITEBYTECODE=
	emake DESTDIR="${D}" LIBDIR=/usr/$(get_libdir) BINDIR=/usr/bin SBINDIR=/usr/sbin SYSCONFDIR=/etc PYTHON="/usr/bin/python3"
}

src_install() {
	emake install DESTDIR="${D}" LIBDIR=/usr/$(get_libdir) BINDIR=/usr/bin SBINDIR=/usr/sbin SYSCONFDIR=/etc PYTHON="/usr/bin/python3"
	fowners root:root /srv/salt/qubes && fperms 750 /srv/salt/qubes
}

pkg_postinst() {
	# disable formula which used to be in this package
	rm -f /srv/salt/_tops/base/config.top
	rm -f /srv/pillar/_tops/base/config.top
	rm -f /srv/pillar/_tops/base/config.modules.top
	rm -f /srv/pillar/_tops/dom0/config.top
	rm -f /srv/pillar/_tops/dom0/config.modules.top
}
