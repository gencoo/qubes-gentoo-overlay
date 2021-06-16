
EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )

inherit eutils multilib distutils-r1

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

DEPEND="dev-python/setuptools[${PYTHON_USEDEP}]
	dev-python/pyyaml
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
	mkdir -p "${D}"/etc/salt/minion.d
	echo -n dom0 > "${D}"/etc/salt/minion_id
	ln -s ../minion.dom0.conf "${D}"/etc/salt/minion.d/
	fowners root:qubes /srv/formulas /srv/pillar /srv/reactor srv/salt
	fperms 750 /srv/formulas /srv/pillar /srv/reactor srv/salt
}

