# Copyright 2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6,8,9} )

inherit eutils multilib distutils-r1 qubes

KEYWORDS="amd64"
DESCRIPTION="Simple input device proxy (dom0)"
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

src_compile() {
	emake all
}

src_install() {
	emake install DESTDIR=${D} 
	fowners -R root:qubes /etc/qubes-rpc/policy/qubes.Input{Mouse,Keyboard,Tablet}
}

