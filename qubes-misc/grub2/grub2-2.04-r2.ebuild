
EAPI=7

if [[ -n ${GRUB_AUTOGEN} || -n ${GRUB_BOOTSTRAP} ]]; then
	PYTHON_COMPAT=( python{2_7,3_{6,7,8,9}} )
	inherit python-any-r1
fi

if [[ -n ${GRUB_AUTORECONF} ]]; then
	WANT_LIBTOOL=none
	inherit autotools
fi

inherit bash-completion-r1 flag-o-matic multibuild optfeature pax-utils toolchain-funcs

if [[ ${PV} == *9999 ]]; then
	inherit qubes
	EGIT_COMMIT=HEAD
	EGIT_REPO_URI="https://github.com/QubesOS/qubes-${PN}.git"
	S=$WORKDIR/qubes-${PN}
else
	inherit rpm
	MY_PR=${PVR##*r}
	MY_PF=${P}-${MY_PR}
	SRC_URI="${REPO_URI}/${MY_PF}.${DIST}.src.rpm"
	S=$WORKDIR/grub-${PV}
fi

KEYWORDS="amd64 x86"

PATCHES=(
	"${FILESDIR}"/gfxpayload.patch
	"${FILESDIR}"/grub-2.02_beta2-KERNEL_GLOBS.patch
)

DEJAVU=dejavu-sans-ttf-2.37
UNIFONT=unifont-12.1.02
SRC_URI+=" fonts? ( mirror://gnu/unifont/${UNIFONT}/${UNIFONT}.pcf.gz )
	themes? ( mirror://sourceforge/dejavu/${DEJAVU}.zip )"

DESCRIPTION="GNU GRUB boot loader"
HOMEPAGE="https://www.gnu.org/software/grub/"

# Includes licenses for dejavu and unifont
LICENSE="GPL-3+ BSD MIT fonts? ( GPL-2-with-font-exception ) themes? ( CC-BY-SA-3.0 BitstreamVera )"
SLOT="2/${PVR}"
IUSE="device-mapper doc efiemu +fonts mount nls sdl test +themes truetype libzfs"

GRUB_ALL_PLATFORMS=( coreboot efi-32 efi-64 emu ieee1275 loongson multiboot qemu qemu-mips pc uboot xen xen-32 xen-pvh )
IUSE+=" ${GRUB_ALL_PLATFORMS[@]/#/grub_platforms_}"

REQUIRED_USE="
	grub_platforms_coreboot? ( fonts )
	grub_platforms_qemu? ( fonts )
	grub_platforms_ieee1275? ( fonts )
	grub_platforms_loongson? ( fonts )"

BDEPEND="
	${PYTHON_DEPS}
	app-misc/pax-utils
	sys-devel/flex
	sys-devel/bison
	sys-apps/help2man
	sys-apps/texinfo
	grub_platforms_efi-64? (
		qubes-misc/pesign-bin
	)
	fonts? (
		media-libs/freetype:2
		virtual/pkgconfig
	)
	test? (
		app-admin/genromfs
		app-arch/cpio
		app-arch/lzop
		app-emulation/qemu
		dev-libs/libisoburn
		sys-apps/miscfiles
		sys-block/parted
		sys-fs/squashfs-tools
	)
	themes? (
		app-arch/unzip
		media-libs/freetype:2
		virtual/pkgconfig
	)
	truetype? ( virtual/pkgconfig )"
	
DEPEND="app-arch/xz-utils
	>=sys-libs/ncurses-5.2-r5:0=
	grub_platforms_emu? (
		sdl? ( media-libs/libsdl )
	)
	device-mapper? ( >=sys-fs/lvm2-2.02.45 )
	libzfs? ( sys-fs/zfs:= )
	mount? ( sys-fs/fuse:0 )
	truetype? ( media-libs/freetype:2= )
	ppc? ( >=sys-apps/ibm-powerpc-utils-1.3.5 )
	ppc64? ( >=sys-apps/ibm-powerpc-utils-1.3.5 )"
RDEPEND="${DEPEND}
	kernel_linux? (
		grub_platforms_efi-32? ( sys-boot/efibootmgr )
		grub_platforms_efi-64? ( sys-boot/efibootmgr )
	)
	!sys-boot/grub:0
	nls? ( sys-devel/gettext )
"

RESTRICT="!test? ( test )"

QA_EXECSTACK="usr/bin/grub-emu* usr/lib/grub/*"
QA_PRESTRIPPED="usr/lib/grub/.*"
QA_MULTILIB_PATHS="usr/lib/grub/.*"
QA_WX_LOAD="usr/lib/grub/*"

pkg_setup() {
	:
}

GRUB_EFI64_S="${WORKDIR}/grub-${PV}-efi-64"
EFI_ESP_DIR="boot/efi/EFI/qubes"
GRUB_EFI="grubx64.efi"

src_prepare() {
	default
	sed -i -e /autoreconf/d autogen.sh || die

	if [[ -n ${GRUB_AUTOGEN} || -n ${GRUB_BOOTSTRAP} ]]; then
		python_setup
	else
		export PYTHON=true
	fi

	if [[ -n ${GRUB_BOOTSTRAP} ]]; then
		eautopoint --force
		AUTOPOINT=: AUTORECONF=: ./bootstrap || die
	elif [[ -n ${GRUB_AUTOGEN} ]]; then
		./autogen.sh || die
	fi

	if [[ -n ${GRUB_AUTORECONF} ]]; then
		eautoreconf
	fi
}

grub_do() {
	multibuild_foreach_variant run_in_build_dir "$@"
}

grub_do_once() {
	multibuild_for_best_variant run_in_build_dir "$@"
}

grub_configure() {
	local platform

	case ${MULTIBUILD_VARIANT} in
		efi*) platform=efi ;;
		xen-pvh) platform=xen_pvh ;;
		xen*) platform=xen ;;
		guessed) ;;
		*) platform=${MULTIBUILD_VARIANT} ;;
	esac

	case ${MULTIBUILD_VARIANT} in
		*-32)
			if [[ ${CTARGET:-${CHOST}} == x86_64* ]]; then
				local CTARGET=i386
			fi ;;
		*-64)
			if [[ ${CTARGET:-${CHOST}} == i?86* ]]; then
				local CTARGET=x86_64
				local -x TARGET_CFLAGS="-Os -march=x86-64 ${TARGET_CFLAGS}"
				local -x TARGET_CPPFLAGS="-march=x86-64 ${TARGET_CPPFLAGS}"
			fi ;;
	esac

	local myeconfargs=(
		TARGET_CFLAGS="$CFLAGS -I$(pwd)"
		TARGET_CPPFLAGS="${CPPFLAGS} -I$(pwd)"
		TARGET_LDFLAGS=-static	
		--disable-werror
		--program-prefix=
		--libdir="${EPREFIX}"/usr/lib
		--disable-dependency-tracking
		--with-utils=host
		--target=x86_64-pc-linux-gnu
		--with-grubdir=grub2
		--program-transform-name=s,grub,grub2,
		$(use_enable device-mapper)
		$(use_enable mount grub-mount)
		$(use_enable nls)
		$(use_enable themes grub-themes)
		$(use_enable truetype grub-mkfont)
		$(use_enable libzfs)
		$(use_enable sdl grub-emu-sdl)
		${platform:+--with-platform=}${platform}

		# Let configure detect this where supported
		$(usex efiemu '' '--disable-efiemu')
	)

	if use fonts; then
		ln -rs "${WORKDIR}/${UNIFONT}.pcf" unifont.pcf || die
	fi

	if use themes; then
		ln -rs "${WORKDIR}/${DEJAVU}/ttf/DejaVuSans.ttf" DejaVuSans.ttf || die
	fi

	local ECONF_SOURCE="${S}"
	econf "${myeconfargs[@]}"
}

src_configure() {
	# Bug 508758.
	replace-flags -O3 -O2
	filter-flags -O2 -g -fstack-protector-strong -Wp,-D_FORTIFY_SOURCE=2 --param=ssp-buffer-size=4 -mregparm=3 -fexceptions -fasynchronous-unwind-tables -fcf-protection -flto=auto
	append-cflags -g3 -fno-strict-aliasing

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
	# Sandbox bug 404013.
	use libzfs && addpredict /etc/dfs:/dev/zfs
	grub_do emake
	use doc && grub_do_once emake -C docs html

	if use grub_platforms_efi-64 ; then
	 	GRUB_MODULES="all_video boot btrfs cat \
			efifwsetup efinet ext2 fat font gfxmenu \
			gfxterm gzio halt hfsplus http increment iso9660 jpeg \
			loadenv loopback linux lvm lsefi lsefimmap \
			mdraid09 mdraid1x minicmd multiboot multiboot2 \
			net normal part_apple part_msdos part_gpt \
			password_pbkdf2 png reboot \
			search search_fs_uuid search_fs_file \
			search_label serial sleep syslinuxcfg test tftp \
			video xfs"

		
		cd ${GRUB_EFI64_S}
		./grub-mkimage -O x86_64-efi -o ${GRUB_EFI}.orig -p /EFI/qubes -d grub-core ${GRUB_MODULES} || die

		RHTC='Red Hat Test Certificate'
		PKIDIR="/etc/pki/pesign-rh-test"
		/usr/bin/pesign -c "${RHTC}" --certdir "${PKIDIR}" -i ${GRUB_EFI}.orig -o ${GRUB_EFI} -s || die

	fi
}

src_test() {
	# The qemu dependency is a bit complex.
	# You will need to adjust QEMU_SOFTMMU_TARGETS to match the cpu/platform.
	grub_do emake check
}

src_install() {
	grub_do emake install DESTDIR="${D}" bashcompletiondir="$(get_bashcompdir)"
	use doc && grub_do_once emake -C docs install-html DESTDIR="${D}"

	einstalldocs

	insinto /etc/default
	newins "${FILESDIR}"/grub.default-3 grub

	# https://bugs.gentoo.org/231935
	dostrip -x /usr/lib/grub

	if use grub_platforms_efi-64 ; then
		cd ${GRUB_EFI64_S}
		install -d -m 0700 ${D}/${EFI_ESP_DIR}
		install -d -m 0700 ${D}/boot/grub2/
		install -d -m 0700 ${D}/boot/loader/entries
		install -d -m 0700 ${D}/boot/grub2/themes/system
		install -d -m 0700 ${D}/etc/default
		install -d -m 0700 ${D}/etc/sysconfig

		ln -sf ../default/grub ${D}/etc/sysconfig/grub

		touch ${D}/boot/grub2/grub.cfg
		touch ${D}/${EFI_ESP_DIR}/grub.cfg
		ln -sf ../${EFI_ESP_DIR}/grub.cfg ${D}/etc/grub2-efi.cfg

		install -m 700 ${GRUB_EFI} ${D}/${EFI_ESP_DIR}/${GRUB_EFI}
		install -D -m 700 unicode.pf2 ${D}/${EFI_ESP_DIR}/fonts/unicode.pf2

		${D}/usr/bin/grub2-editenv ${D}/${EFI_ESP_DIR}/grubenv create
		ln -sf ../efi/EFI/qubes/grubenv ${D}/boot/grub2/grubenv
	fi
}

pkg_postinst() {
	elog "For information on how to configure GRUB2 please refer to the guide:"
	elog "    https://wiki.gentoo.org/wiki/GRUB2_Quick_Start"

	if has_version 'sys-boot/grub:0'; then
		elog "A migration guide for GRUB Legacy users is available:"
	fi

	if [[ -z ${REPLACING_VERSIONS} ]]; then
		elog
		optfeature "detecting other operating systems (grub-mkconfig)" sys-boot/os-prober
		optfeature "creating rescue media (grub-mkrescue)" dev-libs/libisoburn
		optfeature "enabling RAID device detection" sys-fs/mdadm
	fi

	if has_version sys-boot/os-prober; then
		ewarn "Due to security concerns, os-prober is disabled by default."
		ewarn "Set GRUB_DISABLE_OS_PROBER=false in /etc/default/grub to enable it."
	fi
}

