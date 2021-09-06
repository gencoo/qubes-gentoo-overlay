
EAPI=7

PYTHON_COMPAT=( python3_{6,8,9} )

inherit eutils multilib distutils-r1 qubes

KEYWORDS="amd64"
HOMEPAGE="http://www.qubes-os.org"
LICENSE="GPLv2"

SLOT="0"
IUSE=" "

DEPEND="sys-devel/gettext"
RDEPEND="${DEPEND}
	dev-python/setuptools[${PYTHON_USEDEP}]
	dev-libs/libappindicator
	qubes-core/admin-client
	qubes-misc/artwork
	dev-python/gbulb[${PYTHON_USEDEP}]
        ${PYTHON_DEPS}"
PDEPEND=""
#qubes-mgmt-salt-dom0

src_prepare() {
	default
}

src_configure() {
	py_opts="${py_opts} /usr/bin/python setup.py"
	export PYTHONDONTWRITEBYTECODE=
}

src_compile() {
	${py_opts} build --executable="/usr/bin/python -s"
	sleep 1
}

src_install() {
	${py_opts} install -O1 --skip-build --root ${D}
	emake install DESTDIR=${D}
	elog 'posttrans gtk-update-icon-cache /usr/share/icons/Adwaita &>/dev/null || :'
}

pkg_postinst() {
	touch --no-create %{_datadir}/icons/Adwaita &>/dev/null || :
}

pkg_prerm() {
	touch --no-create %{_datadir}/icons/Adwaita &>/dev/null || :
	gtk-update-icon-cache %{_datadir}/icons/Adwaita &>/dev/null || :
}
