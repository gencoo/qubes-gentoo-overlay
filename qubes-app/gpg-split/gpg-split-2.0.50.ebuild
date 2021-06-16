
EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )

inherit eutils multilib distutils-r1

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
	S=$WORKDIR/qubes-${P}
fi



KEYWORDS="amd64"
DESCRIPTION="The Qubes service for secure gpg separation"
HOMEPAGE="http://www.qubes-os.org"
LICENSE="GPLv2"

SLOT="0"
IUSE="+pandoc-bin"

DEPEND="qubes-core/libvchan
        pandoc-bin? (
            app-text/pandoc-bin
        )
        !pandoc-bin? (
            app-text/pandoc
        )
	dev-python/setuptools[${PYTHON_USEDEP}]
        ${PYTHON_DEPS}
        "
RDEPEND="${DEPEND}"
PDEPEND=""

src_prepare() {
    default
}

src_compile() { :; }

src_install() {
	export PYTHONDONTWRITEBYTECODE=
	# Remove related /var/run
	#sed -i 's|/etc/tmpfiles\.d/|/usr/lib/tmpfiles.d/|g' Makefile
	#sed -i '/^.*\/var\/run\/.*$/d' Makefile
	# Ensure qubes.Gpg service script will use the correct path
	#sed -i "s|/usr/lib/qubes-gpg-split|/usr/$(get_libdir)/qubes-gpg-split|" qubes.Gpg.service

	install -m 0664 -D qubes.Gpg.policy ${D}/etc/qubes-rpc/policy/qubes.Gpg
	install -m 0664 -D qubes.GpgImportKey.policy ${D}/etc/qubes-rpc/policy/qubes.GpgImportKey
	emake -C tests install-dom0-py3 DESTDIR=${D} PYTHON2=/usr/bin/python
}
