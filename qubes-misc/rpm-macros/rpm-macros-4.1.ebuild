# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit eutils rpm

fc_repo="https://download-ib01.fedoraproject.org/pub/fedora/linux/"
fc_repo_tail="33/Everything/x86_64/Packages"

releases_uri="${fc_repo}/releases/${fc_repo_tail}"
for macro in efi-srpm-macros-4-5 kernel-srpm-macros-1.0-3 perl-srpm-macros-1-38 python-srpm-macros-3.9-15 \
	python-qt5-rpm-macros-5.15.0-2 qt5-srpm-macros-5.15.1-1 redhat-rpm-config-172-1 ;
do
SRC_URI="${SRC_URI} ${releases_uri}/${macro:0:1}/${macro}.fc33.noarch.rpm"
done

update_uri="${fc_repo}/updates/${fc_repo_tail}"
for macro in lua-srpm-macros-1-3 python3-rpm-macros-3.9-15 python-srpm-macros-3.9-15 qt5-rpm-macros-5.15.1-1 systemd-rpm-macros-246.14-1;
do
SRC_URI="${SRC_URI} ${update_uri}/${macro:0:1}/${macro}.fc33.noarch.rpm"
done

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64"

RDEPEND="app-arch/rpm"
DEPEND="${RDEPEND}"
BDEPEND=""

src_unpack() {
	rpm_unpack ${A} && mkdir $S
}

src_install() {
	rm -rf $D $S
	ln -s ${WORKDIR} ${PORTAGE_BUILDDIR}/image
	rm -rf $D/usr/lib/.build-id
}
