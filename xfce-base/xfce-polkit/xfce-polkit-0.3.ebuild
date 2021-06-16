# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit flag-o-matic toolchain-funcs rpm

MY_PR=6
MY_PF=${P}-${MY_PR}
SRC_URI="https://download-ib01.fedoraproject.org/pub/fedora/linux/development/rawhide/Everything/source/tree/Packages/x/${MY_PF}.fc34.src.rpm"

KEYWORDS="amd64"
LICENSE="GPLv2"

SLOT="0"
IUSE=" "

DEPEND="xfce-base/libxfce4ui
	sys-auth/polkit"
RDEPEND=""
PDEPEND=""

src_unpack() {
	rpm_unpack ${A}
	mkdir -p $S
}

src_install() {
	rpmbuild -bi $WORKDIR/*.spec --nodeps --noclean --nodebuginfo --buildroot=$D
	default
}
