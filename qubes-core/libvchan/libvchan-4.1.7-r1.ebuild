# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
PYTHON_COMPAT=( python3_{6,8,9} )

inherit eutils distutils-r1 qubes

QS_PN=${Q}-socket
EGIT_COMMIT=HEAD
EGIT_REPO_URI="${EGIT_REPO_URI} socket? ( https://github.com/QubesOS/${QS_PN}.git )"
SS=$WORKDIR/${QS_PN}

KEYWORDS="amd64"
DESCRIPTION="QubesOS libvchan cross-domain communication library"
HOMEPAGE="http://www.qubes-os.org"
LICENSE="GPLv2"

SLOT="0"
IUSE="socket"

DEPEND="app-emulation/xen-tools"
RDEPEND="${DEPEND}"
PDEPEND=""

pkg_setup() {
	export LIBDIR="${EPREFIX}"/usr/$(get_libdir)
	export INCLUDEDIR=/usr/include
}

src_unpack() {
	rhel_src_unpack ${A}
	use socket && git clone ${EGIT_REPO_URI}
}

src_compile() {
	emake all
	use socket && cd $SS && emake all
}

src_install() {
	emake DESTDIR=${D} install
	use socket && cd $SS && emake DESTDIR=${D} install
}
