# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6..9} )

DISTUTILS_USE_SETUPTOOLS=no

inherit distutils-r1 qubes

if [[ ${PV} = *9999* ]]; then
	RDEPEND="app-emulation/libvirt:=[-python(-)]"
else
	KEYWORDS="amd64 ~arm64 ~ppc64 x86"
	RDEPEND="app-emulation/libvirt:0/${PV}"
fi

DESCRIPTION="libvirt Python bindings"
HOMEPAGE="https://www.libvirt.org"
LICENSE="LGPL-2"
SLOT="0"
IUSE="examples test"
RESTRICT="!test? ( test )"

DEPEND="virtual/pkgconfig"
BDEPEND="test? (
	dev-python/lxml[${PYTHON_USEDEP}]
	dev-python/nose[${PYTHON_USEDEP}]
)"

distutils_enable_tests setup.py

python_install_all() {
	if use examples; then
		dodoc -r examples
		docompress -x /usr/share/doc/${PF}/examples
	fi
	distutils-r1_python_install_all
}

