
EAPI=7

PYTHON_COMPAT=( python3_{6,8,9} )

inherit eutils multilib distutils-r1 flag-o-matic systemd qubes

KEYWORDS="amd64"
DESCRIPTION="The Qubes core files for installation inside a Qubes VM"
HOMEPAGE="http://www.qubes-os.org"
LICENSE="GPLv2"

SLOT="0"
IUSE="+pandoc-bin"

DEPEND="media-gfx/imagemagick
        pandoc-bin? (
            app-text/pandoc-bin
        )
        !pandoc-bin? (
            app-text/pandoc
        )
	dev-python/setuptools[${PYTHON_USEDEP}]
        dev-python/sphinx[${PYTHON_USEDEP}]
	dev-python/lxml[${PYTHON_USEDEP}]
        dev-python/dbus-python[${PYTHON_USEDEP}]
	dev-python/pyyaml[${PYTHON_USEDEP}]
	sys-fs/inotify-tools
	dev-python/xcffib[${PYTHON_USEDEP}]
        ${PYTHON_DEPS}
        "
RDEPEND="${DEPEND}
	qubes-core/admin-client
	qubes-core/qrexec
	qubes-misc/utils[dom0]
	x11-misc/xdotool
	app-arch/createrepo_c"
PDEPEND="qubes-core/admin"

src_prepare() {
	#eapply ${FILESDIR}/delete_system_dialog_cmd.patch
	default
}

src_configure() {
	filter-flags -Werror=unused-result
	export BACKEND_VMM=xen
	export PYTHONDONTWRITEBYTECODE=
}

src_compile() {
	cd ${S}/dom0-updates && emake
	cd ${S}/file-copy-vm && emake
	cd ${S}/doc && emake manpages
}

src_install() {
	keepdir /var/lib/qubes/updates
	## Appmenus
	insinto /etc/qubes-rpc/policy
	newins qubesappmenus/qubes.SyncAppMenus.policy qubes.SyncAppMenus

	# Qrexec services
	dodir /usr/lib/qubes/qubes-rpc /etc/qubes-rpc/policy
	insinto /usr/lib/qubes/qubes-rpc
	doins -r qubes-rpc/* qubes-rpc-policy/*

	for i in qubes-rpc/*; do dosym ../../usr/lib/qubes/$i /etc/qubes-rpc/$(basename $i); done

	### pm-utils
	insinto /usr/lib64/pm-utils/sleep.d
	insinto pm-utils/52qubes-pause-vms

	into /usr/lib/systemd/system
	systemd_dounit pm-utils/qubes-suspend.service

	### Dracut module
	insinto /etc/dracut.conf.d
	cp dracut/dracut.conf.d/* ${D}/etc/dracut.conf.d/

	mkdir -p ${D}/usr/lib/dracut/modules.d
	doins -r dracut/modules.d/*

	### Others
	mkdir -p ${D}/etc/sysconfig
	insinto /etc/security/limits.d
	newins system-config/limits-qubes.conf 99-qubes.conf

	insinto /etc/sysconfig/modules
	doins -r system-config/{cpufreq-xen,qubes-dom0}.modules

	insopts -m0440 && insinto /etc/sudoers.d
	newins system-config/qubes.sudoers qubes

	insinto /etc/polkit-1/rules.d
	newins system-config/polkit-1-qubes-allow-all.rules 00-qubes-allow-all.rules

	insinto /etc/cron.d
	doins system-config/qubes-sync-clock.cron

	insinto /etc/cron.daily
	newins system-config/lvm-cleanup.cron-daily lvm-cleanup

	insinto /etc/udev/rules.d
	doins -r system-config/{00-qubes-ignore-devices,12-qubes-ignore-lvm-devices}.rules

	dosym /etc/udev/rules.d/00-qubes-ignore-devices.rules /lib/udev/rules.d/00-qubes-ignore-devices.rules
	dosym /etc/udev/rules.d/12-qubes-ignore-lvm-devices.rules /lib/udev/rules.d/12-qubes-ignore-lvm-devices.rules

	insinto /etc/profile.d
	newins system-config/disable-lesspipe.sh zz-disable-lesspipe.sh

	insopts -m0755 && insinto /usr/lib/kernel/install.d
	newins system-config/kernel-grub2.install 80-grub2.install
	newins system-config/kernel-xen-efi.install 90-xen-efi.install
	newins system-config/kernel-remove-bls.install 99-remove-bls.install

	insinto /usr/lib/systemd/system-preset
	doins -r system-config/75-qubes-dom0{,-user}.preset system-config/99-qubes-default-disable.preset

	touch ${D}/var/lib/qubes/.qubes-exclude-block-devices

	# file copy to VM
	into /usr/lib/qubes
	dobin file-copy-vm/qfile-dom0-agent

	exeinto /usr/bin/
	doexe -r file-copy-vm/qvm-copy{,-to-vm}

	dosym qvm-copy-to-vm /usr/bin/qvm-move-to-vm
	dosym qvm-copy /usr/bin/qvm-move

	### Documentation
	cd doc && emake DESTDIR=${D} install

	fowners -R root:qubes /etc/qubes-rpc/policy/qubes.repos.{List,Enable,Disable}
	fperms -R 0664 /etc/qubes-rpc/policy/qubes.repos.{List,Enable,Disable} /etc/cron.d/qubes-sync-clock.cron

	fowners root:root /etc/cron.d/qubes-sync-clock.cron
}

pkg_postinst() {
	systemctl enable qubes-suspend.service
}

pkg_config() {
	# dom0 have no network, but still can receive updates (qubes-dom0-update)
	sed -i 's/^UseNetworkHeuristic=.*/UseNetworkHeuristic=false/' /etc/PackageKit/PackageKit.conf

	# Remove unnecessary udev rules that causes problems in dom0 (#605)
	rm -f /lib/udev/rules.d/69-xorg-vmmouse.rules

	chmod -x /etc/grub.d/10_linux
}
