# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit rhel

SRC_URI="${REPO_URI}/xen-hvm-stubdom-legacy-4.13.0-1.${DIST}.x86_64.rpm
	${REPO_URI}/xen-hvm-stubdom-linux-1.2.0-1.${DIST}.x86_64.rpm"
DESCRIPTION="xen-hvm-stubdom-legacy xen-hvm-stubdom-linux binaries"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64"
IUSE="+binary"

RDEPEND=">=app-arch/rpm-4.16.0.0
	app-emulation/xen-tools"
DEPEND="${RDEPEND}"
BDEPEND=""

src_install() {
	rhel_bin_install
}
