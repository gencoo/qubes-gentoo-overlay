# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
PYTHON_COMPAT=( python3_{7,8,9} )
inherit eutils distutils-r1 

Q=qubes-core-vchan
if [[ ${PV} == *9999 ]]; then
	inherit qubes
	EGIT_COMMIT=HEAD
	Q_PN=${Q}-xen
	EGIT_REPO_URI="https://github.com/QubesOS/${Q_PN}.git"
	S=$WORKDIR/${Q_PN}
else
	inherit rpm
	MY_PR=1
	MY_P=qubes-${PN}-xen-${PV}
	SRC_URI="https://mirrors.tuna.tsinghua.edu.cn/qubesos/repo/yum/r4.1/current-testing/dom0/fc32/rpm/${MY_P}-${MY_PR}.fc32.src.rpm"
	S=$WORKDIR/${MY_P}
fi

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
	CFLAGS="${CFLAGS:--O2 -g}" ; export CFLAGS ; 
  	CXXFLAGS="${CXXFLAGS:--O2 -g}" ; export CXXFLAGS ; 
  	FFLAGS="${FFLAGS:--O2 -g }" ; export FFLAGS ; 
  	FCFLAGS="${FCFLAGS:--O2 -g }" ; export FCFLAGS ; 
  	LDFLAGS="${LDFLAGS:-}" ; export LDFLAGS

	export LIBDIR=/usr/$(get_libdir)
	export INCLUDEDIR=/usr/include
}

src_prepare() {
	if use socket; then
		inherit qubes git-r3
		Q_PN=${Q}-socket
		EGIT_COMMIT=HEAD
		EGIT_REPO_URI="https://github.com/QubesOS/${Q_PN}.git"
		SS=$WORKDIR/${Q_PN}
	fi
	default
}

src_compile() {
	emake all
	use socket && cd $SS && emake all
}

src_install() {
	emake DESTDIR=${D} install
	use socket && cd $SS && emake DESTDIR=${D} install
}
