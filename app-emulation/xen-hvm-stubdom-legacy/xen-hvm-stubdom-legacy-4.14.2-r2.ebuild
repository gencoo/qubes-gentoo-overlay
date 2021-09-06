# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{7..9} )
PYTHON_REQ_USE='xml,threads(+)'

inherit flag-o-matic multilib python-single-r1 toolchain-funcs rhel
MY_PR=${PVR##*r}
MY_PV=${PV/_/-}

XEN_EXTFILES_URL="http://xenbits.xensource.com/xen-extfiles"
LIBPCI_URL=ftp://atrey.karlin.mff.cuni.cz/pub/linux/pci
GRUB_URL=https://alpha.gnu.org/gnu/grub

UPSTREAM_VER=
[[ -n ${UPSTREAM_VER} ]] && \
	UPSTREAM_PATCHSET_URI="https://dev.gentoo.org/~dlan/distfiles/${P/-pvgrub/}-upstream-patches-${UPSTREAM_VER}.tar.xz
		https://github.com/hydrapolic/gentoo-dist/raw/master/xen/${P/-pvgrub/}-upstream-patches-${UPSTREAM_VER}.tar.xz"
	Q_PN=qubes-vmm-xen-stubdom-legacy
	Q_PVR=4.13.0-1
	Q_PF=${Q_PN}-${Q_PVR}
	GUI_AGENT=gui-agent-xen-hvm-stubdom
	GUI_COMMON=gui-common
	CORE_VCHAN_XEN=core-vchan-xen
	SRC_URI="https://github.com/QubesOS/qubes-${GUI_AGENT}/archive/refs/tags/mm_5f57a593.tar.gz -> ${GUI_AGENT}.tar.gz
		https://github.com/QubesOS/qubes-${GUI_COMMON}/archive/refs/tags/v4.1.1.tar.gz -> ${GUI_COMMON}.tar.gz
		https://github.com/QubesOS/qubes-${CORE_VCHAN_XEN}/archive/refs/tags/v4.1.7.tar.gz -> ${CORE_VCHAN_XEN}.tar.gz
		https://github.com/QubesOS/${Q_PN}/archive/refs/tags/v${Q_PVR}.tar.gz -> ${Q_PF}.tar.gz
		http://mirrors.163.com/fedora/updates/34/Everything/SRPMS/Packages/x/xen-${MY_PV}-${MY_PR}.fc34.src.rpm
		$XEN_EXTFILES_URL/zlib-1.2.3.tar.gz
		$XEN_EXTFILES_URL/gmp-4.3.2.tar.bz2
		$XEN_EXTFILES_URL/tpm_emulator-0.7.4.tar.gz
		${UPSTREAM_PATCHSET_URI}"

S="${WORKDIR}/xen-${MY_PV}"
QS="${WORKDIR}/${Q_PF}"

DESCRIPTION="allows to boot Xen domU kernels from a menu.lst laying inside guest filesystem"
HOMEPAGE="https://www.xenproject.org"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~x86"
IUSE=""

REQUIRED_USE="${PYTHON_REQUIRED_USE}"

DEPEND="sys-devel/gettext
	sys-devel/bin86
	sys-apps/texinfo
	x11-libs/pixman"

RDEPEND="${PYTHON_DEPS}
	>=app-emulation/xen-tools-${PV}"

# python2 only
RESTRICT="test"

pkg_setup() {
	python-single-r1_pkg_setup
	export PYTHONDONTWRITEBYTECODE=
	export EXTRA_CFLAGS_QEMU_TRADITIONAL="$CFLAGS"
	export EXTRA_CFLAGS_QEMU_XEN="$CFLAGS"
	export KCONFIG_CONFIG=config
	export XEN_CONFIG_EXPERT=y
	export PATH="/usr/bin:$PATH"
	export C_INCLUDE_PATH=$C_INCLUDE_PATH:/usr/include:"$S"/extras/mini-os/include:
}

retar-externals() {
	# Purely to unclutter src_prepare
	local set="tpm_emulator-0.7.4.tar.gz  zlib-1.2.3.tar.gz"

	# eapply can't patch in $WORKDIR, requires a sed; Bug #455194. Patchable, but sed informative
	sed -e s':AR=${AR-"ar rc"}:AR=${AR-"ar"}:' \
		-i "${WORKDIR}"/zlib-1.2.3/configure || die
	sed -e 's:^AR=ar rc:AR=ar:' \
		-e s':$(AR) $@:$(AR) rc $@:' \
		-i "${WORKDIR}"/zlib-1.2.3/{Makefile,Makefile.in} || die
	einfo "zlib Makefile edited"

	cd "${WORKDIR}" || die
	tar czp zlib-1.2.3 -f zlib-1.2.3.tar.gz || die
	tar czp tpm_emulator-0.7.4 -f tpm_emulator-0.7.4.tar.gz || die
	mv $set "${S}"/stubdom/ || die
	einfo "tarballs moved to source"
}

src_unpack() {
	rhel_unpack ${A}
	sed -i "/patch5 -p1/d" ${WORKDIR}/xen.spec
	sed -i 's/EFI_VENDOR=fedora/EFI_VENDOR=qubes/g' ${S}/xen/Makefile
	rpmbuild --rmsource -bp $WORKDIR/*.spec --nodeps
	rpm_clean
	unpack ${DISTDIR}/*.tar.*
	rm $S/xen/.config
	cp -v ${QS}/config $S/xen/
	cp -v ${QS}/config $S/xen/.config
}

src_prepare() {
	mkdir tools/qubes-gui/
	mv ../qubes-${GUI_AGENT}*/* tools/qubes-gui/
	mv ../qubes-${GUI_COMMON}*/include/qubes-gui*.h tools/qubes-gui/include/
	mv ../qubes-${CORE_VCHAN_XEN}*/vchan tools/
	sed -e 's/ioemu-qemu-xen/qemu-xen-traditional/g' tools/qubes-gui/gui-agent-qemu/qemu-glue.patch | patch -p1
	cp -a $QS/stubdom-dhcp/* tools/qemu-xen-traditional/
	patch -d tools/qemu-xen-traditional -p4 < $QS/stubdom-dhcp/lwip-dhcp-qemu-glue.patch
	rm $QS/patch-0105-stubdom-make-libvchan-available-in-stubdom.patch
	rm $QS/patch-xen-stubdom-qubes-gui.patch
	rm $QS/patch-xen-gcc10-fixes.patch
	eapply $QS
	eapply "${FILESDIR}"/patch-xen-stubdom-libvchan-qubes-gui.patch

	# Upstream's patchset
	if [[ -n ${UPSTREAM_VER} ]]; then
		einfo "Try to apply Xen Upstream patch set"
		EPATCH_SUFFIX="patch" \
		EPATCH_FORCE="yes" \
		EPATCH_OPTS="-p1" \
			eapply "${WORKDIR}"/patches-upstream
	fi

	# Patch the unmergeable newlib, fix most of the leftover gcc QA issues
	cp "${FILESDIR}"/newlib-implicits.patch stubdom || die

	#Substitute for internal downloading. pciutils copied only due to the only .bz2
	cp "${FILESDIR}"/pciutils-2.2.9.tar.bz2 ./stubdom/ || die "pciutils not copied to stubdom"

	retar-externals || die "re-tar procedure failed"

	default
}

src_configure() {
	local myconf="--prefix=${PREFIX}/usr \
		--libdir=${PREFIX}/usr/$(get_libdir) \
		--libexecdir=${PREFIX}/usr/libexec \
		--disable-vtpm-stubdom \
    		--disable-vtpmmgr-stubdom \
    		--disable-seabios \
    		--disable-docs \
    		--disable-largefile \
    		--disable-githttp \
    		--disable-monitors\
    		--disable-ocamltools \
    		--disable-xsmpolicy \
    		--disable-ovmf \
    		--disable-blktap2 \
    		--disable-rombios \
    		--disable-ipxe \
    		--disable-systemd \
    		--disable-9pfs \
		--disable-werror \
		--disable-xen"

	econf ${myconf}
}

src_compile() {
	emake mini-os-dir
	emake -C stubdom build
	filter-flags -flto=auto -m64 -fstack-protector-strong --param=ssp-buffer-size=4
	export EXTRA_CFLAGS_XEN_TOOLS="$CFLAGS"
	if use x86; then
		emake CC="$(tc-getCC)" LD="$(tc-getLD)" AR="$(tc-getAR)" \
		XEN_TARGET_ARCH="x86_32" -C stubdom pv-grub
	elif use amd64; then
		emake CC="$(tc-getCC)" LD="$(tc-getLD)" AR="$(tc-getAR)" \
		XEN_TARGET_ARCH="x86_64" -C stubdom pv-grub
		if has_multilib_profile; then
			multilib_toolchain_setup x86
			emake CC="$(tc-getCC)" AR="$(tc-getAR)" \
			XEN_TARGET_ARCH="x86_32" -C stubdom pv-grub
		fi
	fi
}

src_install() {
	if use x86; then
		emake XEN_TARGET_ARCH="x86_32" DESTDIR="${D}" OCAML_TOOLS=n prefix=/usr -C install-stubdom
	fi
	if use amd64; then
		emake XEN_TARGET_ARCH="x86_64" DESTDIR="${D}" OCAML_TOOLS=n prefix=/usr -C install-stubdom
		if has_multilib_profile; then
			emake XEN_TARGET_ARCH="x86_32" DESTDIR="${D}" OCAML_TOOLS=n prefix=/usr -C install-stubdom
		fi
	fi
	# remove unwanted
	rm -rf $D/etc \
    	$D/usr/include \
    	$D/usr/bin \
    	$D/usr/lib \
    	$D/usr/lib64 \
    	$D/usr/sbin \
    	$D/usr/share \
    	$D/usr/lib/debug \
    	$D/usr/libexec/bin \
    	$D/usr/libexec/xen/bin \
    	$D/usr/libexec/xen/boot/hvmloader \
    	$D/usr/libexec/xen/boot/xen-shim \
    	$D/usr/libexec/qemu-bridge-helper
    	
    	# stubdom: newlib
	rm -rf $D/usr/*-xen-elf
}

pkg_postinst() {
	elog "Official Xen Guide and the offical wiki page:"
	elog "https://wiki.gentoo.org/wiki/Xen"
	elog "https://wiki.xen.org/wiki/Main_Page"
}
