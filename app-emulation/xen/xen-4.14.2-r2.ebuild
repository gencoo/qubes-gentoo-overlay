# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{7..9} )

inherit flag-o-matic mount-boot multilib python-any-r1 toolchain-funcs rpm
MY_PR=${PVR##*r}
MY_PF=${P}-${MY_PR}

MY_PV=${PV/_/-}
MY_P=${PN}-${MY_PV}

if [[ ${PV} == *9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="git://xenbits.xen.org/xen.git"
	SRC_URI=""
else
	KEYWORDS="amd64 x86"
	UPSTREAM_VER=
	SECURITY_VER=
	GENTOO_VER=

	[[ -n ${UPSTREAM_VER} ]] && \
		UPSTREAM_PATCHSET_URI="https://dev.gentoo.org/~dlan/distfiles/${P}-upstream-patches-${UPSTREAM_VER}.tar.xz
		https://github.com/hydrapolic/gentoo-dist/raw/master/xen/${P}-upstream-patches-${UPSTREAM_VER}.tar.xz"
	[[ -n ${SECURITY_VER} ]] && \
		SECURITY_PATCHSET_URI="https://dev.gentoo.org/~dlan/distfiles/${PN}-security-patches-${SECURITY_VER}.tar.xz"
	[[ -n ${GENTOO_VER} ]] && \
		GENTOO_PATCHSET_URI="https://dev.gentoo.org/~dlan/distfiles/${PN}-gentoo-patches-${GENTOO_VER}.tar.xz"

	# Hypervisor ABI
	hv_abi=4.14
	Q_PN=qubes-vmm-xen
	Q_PV=4.14.1
	Q_PR=3
	Q_PVR=${Q_PV}-${Q_PR}
	Q_PF=${Q_PN}-${Q_PVR}
	SRC_URI="http://mirrors.163.com/fedora/updates/34/Everything/SRPMS/Packages/x/${MY_PF}.fc34.src.rpm
	https://github.com/QubesOS/${Q_PN}/archive/refs/tags/v${Q_PVR}.tar.gz -> ${Q_PF}.tar.gz
		${UPSTREAM_PATCHSET_URI}
		${SECURITY_PATCHSET_URI}
		${GENTOO_PATCHSET_URI}"

	QS="${WORKDIR}/${Q_PF}"
fi

DESCRIPTION="The Xen virtual machine monitor"
HOMEPAGE="https://www.xenproject.org"
LICENSE="GPL-2"
SLOT="0"
IUSE="debug efi flask"

DEPEND="${PYTHON_DEPS}
	efi? ( >=sys-devel/binutils-2.22[multitarget] )
	!efi? ( >=sys-devel/binutils-2.22 )"
RDEPEND=""
PDEPEND="~app-emulation/xen-tools-${PV}"

# no tests are available for the hypervisor
# prevent the silliness of /usr/lib/debug/usr/lib/debug files
# prevent stripping of the debug info from the /usr/lib/debug/xen-syms
RESTRICT="test splitdebug strip"

# Approved by QA team in bug #144032
QA_WX_LOAD="boot/xen-syms-${PV}"

REQUIRED_USE=" "

pkg_setup() {
	python-any-r1_pkg_setup
	export XEN_TARGET_ARCH="x86_64"

	if use flask ; then
		export "XSM_ENABLE=y"
		export "FLASK_ENABLE=y"
	fi

	export PYTHONDONTWRITEBYTECODE=
	export KCONFIG_CONFIG=config
	export XEN_CONFIG_EXPERT=y
}

src_unpack() {
	rpm_src_unpack ${A}
	sed -i 's/EFI_VENDOR=fedora/EFI_VENDOR=qubes/g' ${S}/xen/Makefile
	rm $S/xen/.config
	cp -v ${QS}/config $S/xen/
	cp -v ${QS}/config $S/xen/.config
}

src_prepare() {
	# Qubes's patchset
	einfo "Try to apply Qubes specific patch set"
	pattern=".patch"
	for i in `cat ${FILESDIR}/qubes-patches.conf`; do
		if [[ $i =~ $pattern ]]; then
			eapply ${QS}/$i
		fi
	done

	# Upstream's patchset
	[[ -n ${UPSTREAM_VER} ]] && eapply "${WORKDIR}"/patches-upstream

	# Security patchset
	if [[ -n ${SECURITY_VER} ]]; then
	einfo "Try to apply Xen Security patch set"
		# apply main xen patches
		# Two parallel systems, both work side by side
		# Over time they may concdense into one. This will suffice for now
		source "${WORKDIR}"/patches-security/${PV}.conf

		local i
		for i in ${XEN_SECURITY_MAIN}; do
			eapply "${WORKDIR}"/patches-security/xen/$i
		done
	fi

	# Gentoo's patchset
	[[ -n ${GENTOO_VER} ]] && eapply "${WORKDIR}"/patches-gentoo

	# Symlinks do not work on fat32 volumes
	eapply "${FILESDIR}"/${PN}-4.14-efi.patch

	# Workaround new gcc-11 options
	sed -e '/^CFLAGS/s/-Werror//g' -i xen/Makefile || die

	if use efi; then
		export EFI_VENDOR="qubes"
		export EFI_MOUNTPOINT="/boot"
	fi

	default
}

src_configure() {
	filter-flags -fcf-protection -flto=auto
	unset LDFLAGS
	use debug && myopt="${myopt} debug=y"

	tc-ld-disable-gold # Bug 700374
}

src_compile() {
	# Send raw LDFLAGS so that --as-needed works

	emake V=1 CC="$(tc-getCC)" LDFLAGS="$(raw-ldflags)" LD="$(tc-getLD)" -C xen ${myopt} EFI_VENDOR=qubes
}

src_install() {
	local myopt
	use debug && myopt="${myopt} debug=y"

	# The 'make install' doesn't 'mkdir -p' the subdirs
	if use efi; then
		mkdir -p "${D}"${EFI_MOUNTPOINT}/efi/efi/${EFI_VENDOR} || die
		mv "${D}"${EFI_MOUNTPOINT}/efi/efi "${D}"${EFI_MOUNTPOINT}/efi/EFI
		ln -s "${D}"${EFI_MOUNTPOINT}/efi/EFI/${EFI_VENDOR} "${D}"${EFI_MOUNTPOINT}/efi/qubes
	fi
	
	emake LDFLAGS="$(raw-ldflags)" LD="$(tc-getLD)" DESTDIR="${D}" -C xen ${myopt} install

	# make install likes to throw in some extra EFI bits if it built
	use efi || rm -rf "${D}/usr/$(get_libdir)/efi"

	# hypervisor symlinks
	rm -rf ${D}/boot/xen-${hv_abi}.gz
	rm -rf ${D}/boot/xen-4.gz
	rm -rf ${D}/boot/xen.gz
	rm -rf "${D}"${EFI_MOUNTPOINT}/efi/qubes
	# build efi
	XEN_EFI_VERSION=$(echo ${PVR} | sed -e 's/rc./rc/')
	EFI_DIR=$(efibootmgr -v 2>/dev/null | awk '
      		/^BootCurrent:/ { current=$2; }
      		/^Boot....\* / {
          	  if ("Boot" current "*" == $1) {
              	      sub(".*File\\(", "");
              	      sub("\\\\xen.efi\\).*", "");
              	      gsub("\\\\", "/");
             	      print;
          	  }
      	      }')

	# FAT (on ESP) does not support symlinks
	# override the file on purpose
	if [ -n "${EFI_DIR}" -a -d "${D}/boot/boot/efi${EFI_DIR}" ]; then
  	  cp -pf ${D}/boot/efi/EFI/qubes/xen-$XEN_EFI_VERSION.efi ${D}/boot/efi${EFI_DIR}/xen.efi
	else
  	  cp -pf ${D}/boot/efi/EFI/qubes/xen-$XEN_EFI_VERSION.efi ${D}/boot/efi/EFI/qubes/xen.efi
	fi

	if [ -f /sbin/grub2-mkconfig ]; then
		if [ -f /boot/efi/EFI/qubes/grub.cfg ]; then
    		   echo "/boot/efi/EFI/qubes/grub.cfg exist!"
  		else
		  /sbin/grub2-mkconfig -o /boot/efi/EFI/qubes/grub.cfg
		fi
	fi
}

pkg_postinst() {
	if [ -f /etc/default/grub ]; then
    	if ! grep -q smt=off /etc/default/grub; then
        	echo 'GRUB_CMDLINE_XEN_DEFAULT="$GRUB_CMDLINE_XEN_DEFAULT smt=off"' >> /etc/default/grub
        	grub2-mkconfig -o /boot/grub2/grub.cfg
    	fi
    	if ! grep -q gnttab_max_frames /etc/default/grub; then
        	echo 'GRUB_CMDLINE_XEN_DEFAULT="$GRUB_CMDLINE_XEN_DEFAULT gnttab_max_frames=2048 gnttab_max_maptrack_frames=4096"' >> /etc/default/grub
        	grub2-mkconfig -o /boot/grub2/grub.cfg
    	fi
	fi

	if [ -f /boot/efi/EFI/qubes/xen.cfg ]; then
    	if ! grep -q smt=off /boot/efi/EFI/qubes/xen.cfg; then
        	sed -i -e 's:^options=.*:\0 smt=off:' /boot/efi/EFI/qubes/xen.cfg
    	fi
    	if ! grep -q gnttab_max_frames /boot/efi/EFI/qubes/xen.cfg; then
        	sed -i -e 's:^options=.*:\0 gnttab_max_frames=2048 gnttab_max_maptrack_frames=4096:' /boot/efi/EFI/qubes/xen.cfg
    	fi
	fi

	if [ -f /sbin/grub2-mkconfig ]; then
		if [ -f /boot/grub2/grub.cfg ]; then
    		/sbin/grub2-mkconfig -o /boot/grub2/grub.cfg
  		fi
		if [ -f /boot/efi/EFI/qubes/grub.cfg ]; then
    		/sbin/grub2-mkconfig -o /boot/efi/EFI/qubes/grub.cfg
  		fi
	fi

	elog "Official Xen Guide:"
	elog " https://wiki.gentoo.org/wiki/Xen"

	use efi && einfo "The efi executable is installed in /boot/efi/gentoo"

	elog "You can optionally block the installation of /boot/xen-syms by an entry"
	elog "in folder /etc/portage/env using the portage's feature INSTALL_MASK"
	elog "e.g. echo ${msg} > /etc/portage/env/xen.conf"

	ewarn
	ewarn "Xen 4.12+ changed the default scheduler to credit2 which can cause"
	ewarn "domU lockups on multi-cpu systems. The legacy credit scheduler seems"
	ewarn "to work fine."
	ewarn
	ewarn "Add sched=credit to xen command line options to use the legacy scheduler."
	ewarn
	ewarn "https://wiki.gentoo.org/wiki/Xen#Xen_domU_hanging_with_Xen_4.12.2B"
}

pkg_postrm() {
	if [ -f /sbin/grub2-mkconfig ]; then
		if [ -f /boot/grub2/grub.cfg ]; then
    		/sbin/grub2-mkconfig -o /boot/grub2/grub.cfg
  		fi
		if [ -f /boot/efi/EFI/qubes/grub.cfg ]; then
    		/sbin/grub2-mkconfig -o /boot/efi/EFI/qubes/grub.cfg
  		fi
	fi
}
