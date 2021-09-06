# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{7..9} )

inherit flag-o-matic multilib-build python-any-r1 toolchain-funcs qubes

LICENSE="GPL-2"
SLOT="0"
IUSE="+qemu +pulseaudio +busybox +rootfs"

DEPEND="${PYTHON_DEPS}
	dev-util/quilt
	sys-devel/flex
	sys-devel/bc
	sys-devel/binutils[-default-gold]
	qemu? (
		dev-libs/glib:2
		sys-devel/autoconf
		sys-devel/automake
		sys-firmware/edk2-ovmf
		sys-devel/libtool
		sys-libs/libseccomp
		x11-libs/pixman
	)
	pulseaudio? (
		sys-devel/gettext
		dev-libs/libltdl
		media-libs/libsndfile
		sys-devel/m4
	)
	busybox? (
		sys-libs/libselinux
		sys-libs/libsepol
		dev-lang/perl
	)
	rootfs? (
		sys-kernel/dracut
		sys-fs/inotify-tools
	)"
RDEPEND=""
PDEPEND="app-emulation/xen-tools"

src_prepare() {
	eapply ${FILESDIR}/version.patch
	ln -s  ${DISTDIR}/pulseaudio-14.2.tar.xz pulseaudio-14.2.tar.xz
	ln -s  ${DISTDIR}/linux-5.4.125.tar.xz linux-5.4.125.tar.xz
	default
}

src_configure() {
	export ARCH=x86
	filter-flags -fcf-protection -flto=auto -Wunused-result
	append-flags -w
	unset LDFLAGS
	tc-ld-disable-gold
}

src_compile() {
	emake LD="$(tc-getLD)" -f Makefile.stubdom
}

src_install() {
	emake LD="$(tc-getLD)" -f Makefile.stubdom DESTDIR="${D}" \
	STUBDOM_BINDIR=/usr/libexec/xen/boot install
}
