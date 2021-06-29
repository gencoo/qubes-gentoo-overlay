# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python{2_7,3_{6,7,8,9}} )

inherit bash-completion-r1 flag-o-matic multibuild optfeature pax-utils toolchain-funcs rpm python-any-r1

MY_PR=${PVR##*r}
MY_PF=${P}-${MY_PR}
SRC_URI="${REPO_URI}/${MY_PF}.${DIST}.src.rpm"
S=$WORKDIR/grub-$PV

KEYWORDS="amd64"

PATCHES=(
	"${FILESDIR}"/gfxpayload.patch
	"${FILESDIR}"/grub-2.02_beta2-KERNEL_GLOBS.patch
)

DESCRIPTION="GNU GRUB boot loader"
HOMEPAGE="https://www.gnu.org/software/grub/"


SLOT="2/${PVR}"
IUSE="device-mapper"

GRUB_ALL_PLATFORMS=( xen xen-pvh )
IUSE+=" ${GRUB_ALL_PLATFORMS[@]/#/grub_platforms_}"

BDEPEND="${PYTHON_DEPS}
	app-misc/pax-utils
	sys-devel/flex
	sys-devel/bison
	sys-apps/help2man
	sys-apps/texinfo"
	
DEPEND="app-arch/xz-utils
	>=sys-libs/ncurses-5.2-r5:0=
	device-mapper? ( >=sys-fs/lvm2-2.02.45 )
"
RDEPEND="${DEPEND}
	!sys-boot/grub:0
	sys-devel/gettext"

pkg_setup() {
	:
}

src_prepare() {
	default
	python_setup
	./autogen.sh || die
}

grub_do() {
	multibuild_foreach_variant run_in_build_dir "$@"
}

grub_do_once() {
	multibuild_for_best_variant run_in_build_dir "$@"
}

grub_configure() {
	local ECONF_SOURCE="${S}"

	local baseconf="TARGET_LDFLAGS=-static	\
			--disable-werror \
			--disable-grub-mount \
			"

	local xeneconfargs=(
		CFLAGS="$CFLAGS"
		${baseconf}
		--target=x86_64-pc-linux-gnu
		--with-grubdir=grub2
		--program-transform-name=s,grub,grub2,
		--with-platform=xen
	)

	filter-flags -m64
	local xen_pvheconfargs=(
		CFLAGS="$CFLAGS"
		${baseconf}
		--target=i386-pc-linux-gnu
		--with-grubdir=grub2-pvh
		--program-transform-name=s,grub,grub2-pvh,
		--with-platform=xen_pvh
	)

	use grub_platforms_xen && cd "${S}/grub-xen-x86_64" && econf "${xeneconfargs[@]}" || die
	use grub_platforms_xen-pvh && cd "${S}/grub-xen_pvh-i386" && econf "${xen_pvheconfargs[@]}" || die
}

src_configure() {
	# Bug 508758.
	replace-flags -O3 -O2
	filter-flags -O. -g -fstack-protector-strong -Wp,-D_FORTIFY_SOURCE=2 --param=ssp-buffer-size=4 -mregparm=3 -fexceptions -fasynchronous-unwind-tables -flto=auto

	# We don't want to leak flags onto boot code.
	export HOST_CCASFLAGS=${CCASFLAGS}
	export HOST_CFLAGS=${CFLAGS}
	export HOST_CPPFLAGS=${CPPFLAGS}
	export HOST_LDFLAGS=${LDFLAGS}
	unset CCASFLAGS CFLAGS CPPFLAGS LDFLAGS

	tc-ld-disable-gold #439082 #466536 #526348
	export TARGET_LDFLAGS="${TARGET_LDFLAGS} ${LDFLAGS}"
	unset LDFLAGS

	tc-export CC NM OBJCOPY RANLIB STRIP
	tc-export BUILD_CC BUILD_PKG_CONFIG

	MULTIBUILD_VARIANTS=()
	local p
	for p in "${GRUB_ALL_PLATFORMS[@]}"; do
		use "grub_platforms_${p}" && MULTIBUILD_VARIANTS+=( "${p}" )
	done
	[[ ${#MULTIBUILD_VARIANTS[@]} -eq 0 ]] && MULTIBUILD_VARIANTS=( guessed )
	grub_do grub_configure
}

src_compile() {
	use grub_platforms_xen && cd "${S}/grub-xen-x86_64" && emake || die
	tar cf memdisk.tar grub-xen.cfg
	./grub-mkimage -O x86_64-xen -o grub-x86_64-xen.bin \
		-c grub-bootstrap.cfg -m memdisk.tar -d grub-core grub-core/*.mod

	use grub_platforms_xen-pvh && cd "${S}/grub-xen_pvh-i386" && emake || die
	tar cf memdisk.tar grub-xen.cfg
	./grub-mkimage -O i386-xen_pvh -o grub-i386-xen_pvh.bin \
		-c grub-bootstrap.cfg -m memdisk.tar -d grub-core grub-core/*.mod
}

src_install() {
	set -e
	for dir in grub-xen-x86_64 grub-xen_pvh-i386; do
    		emake -C $dir DESTDIR=${D} install
	done

	find ${D} -iname "*.module" -exec chmod a-x {} \;

	install -d ${D}/var/lib/qubes/vm-kernels/pvgrub2
	install -m 0644 grub-xen-x86_64/grub-x86_64-xen.bin ${D}/var/lib/qubes/vm-kernels/pvgrub2/
	ln -s grub-x86_64-xen.bin ${D}/var/lib/qubes/vm-kernels/pvgrub2/vmlinuz
	# "empty" file file so Qubes tools does not complain
	echo -n | gzip > ${D}/var/lib/qubes/vm-kernels/pvgrub2/initramfs

	install -d ${D}/var/lib/qubes/vm-kernels/pvgrub2-pvh
	install -m 0644 grub-xen_pvh-i386/grub-i386-xen_pvh.bin ${D}/var/lib/qubes/vm-kernels/pvgrub2-pvh/
	ln -s grub-i386-xen_pvh.bin ${D}/var/lib/qubes/vm-kernels/pvgrub2-pvh/vmlinuz
	# "empty" file file so Qubes tools does not complain
	echo -n | gzip > ${D}/var/lib/qubes/vm-kernels/pvgrub2-pvh/initramfs

	# Install ELF files modules and images were created from into
	# the shadow root, where debuginfo generator will grab them from
	find ${D} -name '*.mod' -o -name '*.img' |
	while read MODULE
	do
        	BASE=$(echo $MODULE |sed -r "s,.*/([^/]*)\.(mod|img),\1,")
        	# Symbols from .img files are in .exec files, while .mod
        	# modules store symbols in .elf. This is just because we
        	# have both boot.img and boot.mod ...
        	EXT=$(echo $MODULE |grep -q '.mod' && echo '.elf' || echo '.exec')
        	TGT=$(echo $MODULE |sed "s,${D},.debugroot,")
	#        install -m 755 -D $BASE$EXT $TGT
	done

	rm ${D}/usr/share/info/grub.info
	rm ${D}/usr/share/info/grub-dev.info
	rm ${D}/usr/share/info/dir
	# delete below file collisions
	rm -r ${D}/etc
	rm -rf ${D}/boot
	rm -r ${D}/usr/bin/grub2-editenv
	rm -r ${D}/usr/bin/grub2-file
	rm -r ${D}/usr/bin/grub2-fstest
	rm -r ${D}/usr/bin/grub2-glue-efi
	rm -r ${D}/usr/bin/grub2-mkfont
	rm -r ${D}/usr/bin/grub2-mkimage
	rm -r ${D}/usr/bin/grub2-mklayout
	rm -r ${D}/usr/bin/grub2-mknetdir
	rm -r ${D}/usr/bin/grub2-render-label
	rm -r ${D}/usr/bin/grub2-script-check
	rm -r ${D}/usr/bin/grub2-kbdcomp
	rm -r ${D}/usr/bin/grub2-menulst2cfg
	rm -r ${D}/usr/bin/grub2-mkpasswd-pbkdf2
	rm -r ${D}/usr/bin/grub2-mkrelpath
	rm -r ${D}/usr/bin/grub2-mkrescue
	rm -r ${D}/usr/bin/grub2-mkstandalone
	rm -r ${D}/usr/bin/grub2-syslinux2cfg

	rm -r ${D}/usr/sbin/grub2-bios-setup
	rm -r ${D}/usr/sbin/grub2-install
	rm -r ${D}/usr/sbin/grub2-macbless
	rm -r ${D}/usr/sbin/grub2-mkconfig
	rm -r ${D}/usr/sbin/grub2-ofpathname
	rm -r ${D}/usr/sbin/grub2-probe
	rm -r ${D}/usr/sbin/grub2-reboot
	rm -r ${D}/usr/sbin/grub2-set-default
	rm -r ${D}/usr/sbin/grub2-sparc64-setup

	rm -r ${D}/usr/share/grub
	rm -r ${D}/usr/share/locale
	rm -r ${D}/usr/share/man/man1/grub2-mklayout.1
	rm -r ${D}/usr/share/man/man1/grub2-menulst2cfg.1
	rm -r ${D}/usr/share/man/man1/grub2-mkrescue.1
	rm -r ${D}/usr/share/man/man1/grub2-mkfont.1
	rm -r ${D}/usr/share/man/man1/grub2-mkstandalone.1
	rm -r ${D}/usr/share/man/man1/grub2-fstest.1
	rm -r ${D}/usr/share/man/man1/grub2-mkrelpath.1
	rm -r ${D}/usr/share/man/man1/grub2-glue-efi.1
	rm -r ${D}/usr/share/man/man1/grub2-script-check.1
	rm -r ${D}/usr/share/man/man1/grub2-mkpasswd-pbkdf2.1
	rm -r ${D}/usr/share/man/man1/grub2-render-label.1
	rm -r ${D}/usr/share/man/man1/grub2-file.1
	rm -r ${D}/usr/share/man/man1/grub2-editenv.1
	rm -r ${D}/usr/share/man/man1/grub2-kbdcomp.1
	rm -r ${D}/usr/share/man/man1/grub2-mkimage.1
	rm -r ${D}/usr/share/man/man1/grub2-mknetdir.1
	rm -r ${D}/usr/share/man/man8/grub2-bios-setup.8
	rm -r ${D}/usr/share/man/man8/grub2-install.8
	rm -r ${D}/usr/share/man/man8/grub2-mkconfig.8
	rm -r ${D}/usr/share/man/man8/grub2-ofpathname.8
	rm -r ${D}/usr/share/man/man8/grub2-probe.8
	rm -r ${D}/usr/share/man/man8/grub2-reboot.8
	rm -r ${D}/usr/share/man/man8/grub2-set-default.8
	rm -r ${D}/usr/share/man/man8/grub2-sparc64-setup.8

}
