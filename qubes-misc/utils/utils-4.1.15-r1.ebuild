
EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )

inherit eutils multilib distutils-r1 qubes

KEYWORDS="amd64"
DESCRIPTION="Common Linux files for Qubes VM"
HOMEPAGE="http://www.qubes-os.org"
LICENSE="GPLv2"

SLOT="0"
IUSE="+dom0 domU"

DEPEND="app-emulation/xen-tools
	dev-python/setuptools[${PYTHON_USEDEP}]
        dev-python/pycairo[${PYTHON_USEDEP}]
        dev-python/pillow[${PYTHON_USEDEP}]
        dev-python/numpy[${PYTHON_USEDEP}]
        ${PYTHON_DEPS}
        "
RDEPEND="${DEPEND}
        media-gfx/imagemagick"
PDEPEND=""

src_prepare() {
	default
}

src_compile() {
	export PYTHONDONTWRITEBYTECODE=
	myopt="${myopt} DESTDIR="${D}" BACKEND_VMM=xen PYTHON=/usr/bin/python3"
	emake ${myopt} all
}

src_install() {
	emake ${myopt} install
}

pkg_postinst() {
	use dom0 && systemctl enable qubes-meminfo-writer-dom0.service
	use domU && systemctl enable qubes-meminfo-writer.service
}

pkg_prerm() {
	use dom0 && systemctl disable qubes-meminfo-writer-dom0.service
	use domU && systemctl disable qubes-meminfo-writer.service
}

pkg_postrm() {
	use dom0 && systemctl try-restart qubes-meminfo-writer-dom0.service
	use domU && systemctl try-restart qubes-meminfo-writer.service
}
