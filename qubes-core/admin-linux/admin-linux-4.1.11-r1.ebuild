
EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )

inherit eutils multilib distutils-r1 flag-o-matic
Q=qubes-core
if [[ ${PV} == *9999 ]]; then
	inherit qubes
	EGIT_COMMIT=HEAD
	Q_PN=${Q}-${PN}
	EGIT_REPO_URI="https://github.com/QubesOS/${Q_PN}.git"
	S=$WORKDIR/${Q_PN}
else
	inherit rpm
	MY_PR=${PVR##*r}
	MY_P=${Q}-dom0-linux-${PV}
	SRC_URI="${REPO_URI}/${MY_P}-${MY_PR}.${DIST}.src.rpm"
	S=$WORKDIR/${MY_P}
fi

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
	dev-python/lxml
        dev-python/dbus-python[${PYTHON_USEDEP}]
	dev-python/pyyaml
	sys-fs/inotify-tools
	dev-python/xcffib
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
	install -d ${D}/etc/qubes-rpc/policy
	cp qubesappmenus/qubes.SyncAppMenus.policy ${D}/etc/qubes-rpc/policy/qubes.SyncAppMenus

	### Dom0 updates
	install -D dom0-updates/qubes-dom0-updates.cron ${D}/etc/cron.daily/qubes-dom0-updates.cron
	install -D dom0-updates/qubes-dom0-update ${D}/usr/bin/qubes-dom0-update
	install -D dom0-updates/qubes-receive-updates ${D}/usr/libexec/qubes/qubes-receive-updates
	install -D dom0-updates/patch-dnf-yum-config ${D}/usr/lib/qubes/patch-dnf-yum-config
	install -m 0644 -D dom0-updates/qubes-cached.repo ${D}/etc/yum.real.repos.d/qubes-cached.repo
	install -D dom0-updates/qfile-dom0-unpacker ${D}/usr/libexec/qubes/qfile-dom0-unpacker
	ln -s ../../usr/libexec/qubes/qubes-receive-updates ${D}/etc/qubes-rpc/qubes.ReceiveUpdates
	install -m 0664 -D dom0-updates/qubes.ReceiveUpdates.policy ${D}/etc/qubes-rpc/policy/qubes.ReceiveUpdates

	install -d ${D}/var/lib/qubes/updates

	# Qrexec services
	mkdir -p ${D}/usr/lib/qubes/qubes-rpc ${D}/etc/qubes-rpc/policy
	cp qubes-rpc/* ${D}/usr/lib/qubes/qubes-rpc/
	for i in qubes-rpc/*; do ln -s ../../usr/lib/qubes/$i ${D}/etc/qubes-rpc/$(basename $i); done
	cp qubes-rpc-policy/* ${D}/etc/qubes-rpc/policy/

	### pm-utils
	mkdir -p ${D}/usr/lib64/pm-utils/sleep.d
	cp pm-utils/52qubes-pause-vms ${D}/usr/lib64/pm-utils/sleep.d/
	mkdir -p ${D}/usr/lib/systemd/system
	cp pm-utils/qubes-suspend.service ${D}/usr/lib/systemd/system/

	### Dracut module
	mkdir -p ${D}/etc/dracut.conf.d
	cp dracut/dracut.conf.d/* ${D}/etc/dracut.conf.d/

	mkdir -p ${D}/usr/lib/dracut/modules.d
	cp -r dracut/modules.d/* ${D}/usr/lib/dracut/modules.d/

	### Others
	mkdir -p ${D}/etc/sysconfig
	install -m 0644 -D system-config/limits-qubes.conf ${D}/etc/security/limits.d/99-qubes.conf
	install -D system-config/cpufreq-xen.modules ${D}/etc/sysconfig/modules/cpufreq-xen.modules
	install -m 0440 -D system-config/qubes.sudoers ${D}/etc/sudoers.d/qubes
	install -D system-config/polkit-1-qubes-allow-all.rules ${D}/etc/polkit-1/rules.d/00-qubes-allow-all.rules
	install -D system-config/qubes-dom0.modules ${D}/etc/sysconfig/modules/qubes-dom0.modules
	install -D system-config/qubes-sync-clock.cron ${D}/etc/cron.d/qubes-sync-clock.cron
	install -D system-config/lvm-cleanup.cron-daily ${D}/etc/cron.daily/lvm-cleanup
	install -d ${D}/etc/udev/rules.d
	install -m 644 system-config/00-qubes-ignore-devices.rules ${D}/etc/udev/rules.d/
	install -m 644 system-config/12-qubes-ignore-lvm-devices.rules ${D}/etc/udev/rules.d/
	dosym /etc/udev/rules.d/00-qubes-ignore-devices.rules /lib/udev/rules.d/00-qubes-ignore-devices.rules
	dosym /etc/udev/rules.d/12-qubes-ignore-lvm-devices.rules /lib/udev/rules.d/12-qubes-ignore-lvm-devices.rules
	install -m 644 -D system-config/disable-lesspipe.sh ${D}/etc/profile.d/zz-disable-lesspipe.sh
	install -m 755 -D system-config/kernel-grub2.install ${D}/usr/lib/kernel/install.d/80-grub2.install
	install -m 755 -D system-config/kernel-xen-efi.install ${D}/usr/lib/kernel/install.d/90-xen-efi.install
	install -m 755 -D system-config/kernel-remove-bls.install ${D}/usr/lib/kernel/install.d/99-remove-bls.install
	install -m 644 -D system-config/75-qubes-dom0.preset \
		${D}/usr/lib/systemd/system-preset/75-qubes-dom0.preset
	install -m 644 -D system-config/75-qubes-dom0-user.preset \
   		 ${D}/usr/lib/systemd/user-preset/75-qubes-dom0-user.preset
	install -m 644 -D system-config/99-qubes-default-disable.preset \
    		${D}/usr/lib/systemd/system-preset/99-qubes-default-disable.preset
	install -d ${D}/etc/dnf/protected.d
	install -m 0644 system-config/dnf-protected-qubes-core-dom0.conf  \
        	${D}/etc/dnf/protected.d/qubes-core-dom0.conf


	touch ${D}/var/lib/qubes/.qubes-exclude-block-devices

	# file copy to VM
	install -m 755 file-copy-vm/qfile-dom0-agent ${D}/usr/lib/qubes/
	install -m 755 file-copy-vm/qvm-copy-to-vm ${D}/usr/bin/
	install -m 755 file-copy-vm/qvm-copy ${D}/usr/bin/
	ln -s qvm-copy-to-vm ${D}/usr/bin/qvm-move-to-vm
	ln -s qvm-copy ${D}/usr/bin/qvm-move

	### Documentation
	cd doc && emake DESTDIR=${D} install

	# Vaio fixes
	mkdir -p ${D}/usr/lib64/pm-utils/sleep.d
	install -D vaio-fixes/00sony-vaio-audio ${D}/usr/lib64/pm-utils/sleep.d/
	install -D vaio-fixes/99sony-vaio-audio ${D}/usr/lib64/pm-utils/sleep.d/
	mkdir -p ${D}/etc/modprobe.d/
	install -D vaio-fixes/snd-hda-intel-sony-vaio.conf ${D}/etc/modprobe.d/

	chown root:qubes ${D}/etc/qubes-rpc/policy/qubes.repos.{List,Enable,Disable}
	chmod 0664 ${D}/etc/qubes-rpc/policy/qubes.repos.{List,Enable,Disable}

	fowners root:root /etc/cron.d/qubes-sync-clock.cron
	chmod 0644 ${D}/etc/cron.d/qubes-sync-clock.cron
}

pkg_preinst() {
	if ! grep -q ^qubes: /etc/group ; then
		groupadd qubes
	fi
}

pkg_postinst() {
	systemctl enable qubes-suspend.service >/dev/null 2>&1
	# migrate dom0-updates check disable flag
    	if [ -e /var/lib/qubes/updates/disable-updates ]; then
        	qvm-features dom0 service.qubes-update-check ''
        	rm -f /var/lib/qubes/updates/disable-updates
	fi
}

pkg_config() {
	# dom0 have no network, but still can receive updates (qubes-dom0-update)
	sed -i 's/^UseNetworkHeuristic=.*/UseNetworkHeuristic=false/' /etc/PackageKit/PackageKit.conf

	# Remove unnecessary udev rules that causes problems in dom0 (#605)
	rm -f /lib/udev/rules.d/69-xorg-vmmouse.rules

	chmod -x /etc/grub.d/10_linux
}


pkg_prerm() {
	if [ "$1" = 0 ] ; then
		# no more packages left
    		systemctl disable qubes-suspend.service > /dev/null 2>&1
	fi
}
