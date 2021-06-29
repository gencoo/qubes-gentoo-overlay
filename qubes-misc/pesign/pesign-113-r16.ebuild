# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit flag-o-matic toolchain-funcs rpm

MY_PR=${PVR##*r}
MY_PF=${P}-${MY_PR}
SRC_URI="https://download-ib01.fedoraproject.org/pub/fedora/linux/releases/34/Everything/source/tree/Packages/p/${MY_PF}.fc34.src.rpm"
DESCRIPTION="Tools for manipulating signed PE-COFF binaries"
HOMEPAGE="https://github.com/rhboot/pesign"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"

RDEPEND="dev-libs/nspr
	dev-libs/nss
	dev-libs/openssl:0=
	dev-libs/popt
	sys-apps/util-linux
	sys-libs/efivar
"
DEPEND="${RDEPEND}"
BDEPEND="
	sys-apps/help2man
	sys-boot/gnu-efi
	virtual/pkgconfig
"
src_prepare() {
	eapply ${FILESDIR}/fix-flag.patch
	default
}

src_compile() {
	emake PREFIX=/usr LIBDIR=/usr/lib64
}

src_install() {
	emkdir -p ${D}/usr/lib64
	emake PREFIX=/usr LIBDIR=/usr/lib64 INSTALLROOT=${D} \
		install
	emake PREFIX=/usr LIBDIR=/usr/lib64 INSTALLROOT=${D} \
		install_systemd
	# there's some stuff that's not really meant to be shipped yet
	rm -rf ${D}/boot ${D}/usr/include
	rm -rf ${D}/usr/lib64/libdpe*
	mkdir -p ${D}/etc/pki/pesign/
	mkdir -p ${D}/etc/pki/pesign-rh-test/
	cp -a etc/pki/pesign/* ${D}/etc/pki/pesign/
	cp -a etc/pki/pesign-rh-test/* ${D}/etc/pki/pesign-rh-test/
	# remove some files that don't make sense for Gentoo installs
	rm -rf "${ED}/var" "${ED}/usr/share/doc/${PF}/COPYING" || die
	install -d -m 0755 ${D}/usr/lib/python3.9/site-packages/mockbuild/plugins/
	install -m 0755 -p $WORKDIR/pesign.py ${D}/usr/lib/python3.9/site-packages/mockbuild/plugins/
}

pkg_preinst() {
	getent group pesign >/dev/null || groupadd -r pesign
	getent passwd pesign >/dev/null || \
		useradd -r -g pesign -d /run/pesign -s /sbin/nologin \
			-c "Group for the pesign signing daemon" pesign
}
pkg_postinst() {
	certutil -d /etc/pki/pesign/ -X -L > /dev/null
	systemctl enable pesign.service
}

pkg_prerm() {
	systemctl disable pesign.service
}

pkg_postrm() {
	systemctl restart pesign.service
}
