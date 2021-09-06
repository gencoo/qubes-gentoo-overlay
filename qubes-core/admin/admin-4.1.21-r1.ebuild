
EAPI=7

PYTHON_COMPAT=( python3_{6,8,9} )

inherit eutils multilib distutils-r1 qubes

KEYWORDS="amd64"
HOMEPAGE="http://www.qubes-os.org"
LICENSE="GPLv2"

SLOT="0"
IUSE="stubdom-bin"

DEPEND="dev-python/setuptools[${PYTHON_USEDEP}]
        dev-python/sphinx[${PYTHON_USEDEP}]
	dev-python/lxml[${PYTHON_USEDEP}]
        dev-python/dbus-python[${PYTHON_USEDEP}]
	dev-python/pyyaml[${PYTHON_USEDEP}]
	dev-python/pyinotify[${PYTHON_USEDEP}]
	app-emulation/xen-tools[python(+),system-seabios,sdl,qemu]
	=app-emulation/xen-tools-4.14.2-r2
	media-gfx/imagemagick
        ${PYTHON_DEPS}
        "
RDEPEND="${DEPEND}
	dev-python/docutils[${PYTHON_USEDEP}]
	dev-python/jinja[${PYTHON_USEDEP}]
	app-emulation/libvirt[xen,sasl,parted]
	<app-emulation/libvirt-6.8.0
	acct-group/qubes
	qubes-core/qubesdb
	app-emulation/xen[efi]
	stubdom-bin? (
		app-emulation/xen-hvm-stubdom-bin
	)
        !stubdom-bin? (
		app-emulation/xen-hvm-stubdom-legacy
		app-emulation/xen-hvm-stubdom-linux
        )
	sys-apps/pciutils
	sys-process/cronie
	dev-python/scrypt[${PYTHON_USEDEP}]
	net-misc/socat"

PDEPEND="qubes-core/admin-linux
	qubes-core/qrexec
	"

src_configure() {
	installconf="${installconf} \
		DESTDIR="${D}" \
		BACKEND_VMM=xen \
		UNITDIR=/usr/lib/systemd/system \
		PYTHON_SITEPATH=${sitedir} \
		SYSCONFDIR=/etc"
	
	pyconf="${pyconf} PYTHON=/usr/bin/python3 SPHINXBUILD=sphinx-build"
}

src_compile() {
	export PYTHONDONTWRITEBYTECODE=
	emake all
        emake  -C doc $pyconf man
}

src_install() {
	emake install ${installconf}
	emake -C doc DESTDIR="${D}" $pyconf install

	insinto /usr/share/qubes
	doins -r templates

	QLIBDIR=/var/lib/qubes
	QLOGDIR=/var/log/qubes
	QRUNDIR=/var/run/qubes
	QVMDIR="${QLIBDIR}/{vm-templates,appvms,backup,vm-kernels}"
	QCONFDIR=/etc/qubes
	QPOLICYDIR="${QCONFDIR}/policy.d/*"

	dodir $QCONFDIR/backup

	keepdir $QLOGDIR $QRUNDIR $QVMDIR

	fowners -R root:qubes $QCONFDIR/{backup,qmemman.conf} $QLIBDIR $QLOGDIR $QRUNDIR $QVMDIR ${QPOLICYDIR}

	fperms -R 0770  $QCONFDIR/backup $QRUNDIR

	fperms -R 2770 $QLIBDIR $QLOGDIR $QVMDIR

	fperms -R 0664 $QCONFDIR/qmemman.conf ${QPOLICYDIR}
}

pkg_preinst() {
	/usr/lib/qubes/fix-dir-perms.sh
}

pkg_postinst() {
	systemctl enable qubes-core.service qubes-qmemman.service qubesd.service

	sed '/^autoballoon=/d;/^lockfile=/d' -i /etc/xen/xl.conf
	echo 'autoballoon=0' >> /etc/xen/xl.conf
	echo 'lockfile="/var/run/qubes/xl-lock"' >> /etc/xen/xl.conf

	if [ -e /etc/sysconfig/prelink ]; then
		sed 's/^PRELINKING\s*=.*/PRELINKING=no/' -i /etc/sysconfig/prelink
	fi

	# Conflicts with libxl stack, so disable it
	systemctl --no-reload disable xend.service >/dev/null 2>&1
	systemctl --no-reload disable xendomains.service >/dev/null 2>&1
	systemctl daemon-reload >/dev/null 2>&1 || :

	if ! [ -e /var/lib/qubes/qubes.xml ]; then
		#    echo "Initializing Qubes DB..."
    		umask 007; sg qubes -c 'qubes-create --offline-mode'
	fi
}

pkg_prerm() {
    	systemctl disable qubes-core.service qubes-qmemman.service qubesd.service
	if [ "$1" = 0 ] ; then
		# no more packages left
		service qubes_netvm stop
		service qubes_core stop
	fi
}

pkg_postrm() {
	systemctl try-restart qubes-qmemman.service qubesd.service qubes-core.service
	if [ "$1" = 0 ] ; then
		# no more packages left
    	chgrp root /etc/xen
    	chmod 700 /etc/xen
	fi

# Preserve user-modified legacy policy at original location, revert rpm adding
# .rpmsave suffix. This needs to be done in %%posttrans, to be run after
# uninstalling the old package.

# List policy files explicitly, to not touch files from other packages.
SERVICES="
admin.Events
admin.backup.Cancel
admin.backup.Execute
admin.backup.Info
admin.deviceclass.List
admin.label.Create
admin.label.Get
admin.label.Index
admin.label.List
admin.label.Remove
admin.pool.Add
admin.pool.Info
admin.pool.List
admin.pool.ListDrivers
admin.pool.Remove
admin.pool.Set.revisions_to_keep
admin.pool.UsageDetails
admin.pool.volume.List
admin.property.Get
admin.property.GetAll
admin.property.GetDefault
admin.property.Help
admin.property.List
admin.property.Reset
admin.property.Set
admin.vm.Console
admin.vm.Create.AppVM
admin.vm.Create.DispVM
admin.vm.Create.StandaloneVM
admin.vm.Create.TemplateVM
admin.vm.CreateDisposable
admin.vm.CreateInPool.AppVM
admin.vm.CreateInPool.DispVM
admin.vm.CreateInPool.StandaloneVM
admin.vm.CreateInPool.TemplateVM
admin.vm.CurrentState
admin.vm.Kill
admin.vm.List
admin.vm.Pause
admin.vm.Remove
admin.vm.Shutdown
admin.vm.Start
admin.vm.Stats
admin.vm.Unpause
admin.vm.device.block.Attach
admin.vm.device.block.Available
admin.vm.device.block.Detach
admin.vm.device.block.List
admin.vm.device.block.Set.persistent
admin.vm.device.pci.Attach
admin.vm.device.pci.Available
admin.vm.device.pci.Detach
admin.vm.device.pci.List
admin.vm.device.pci.Set.persistent
admin.vm.feature.CheckWithAdminVM
admin.vm.feature.CheckWithNetvm
admin.vm.feature.CheckWithTemplate
admin.vm.feature.CheckWithTemplateAndAdminVM
admin.vm.feature.Get
admin.vm.feature.List
admin.vm.feature.Remove
admin.vm.feature.Set
admin.vm.firewall.Get
admin.vm.firewall.Reload
admin.vm.firewall.Set
admin.vm.property.Get
admin.vm.property.GetAll
admin.vm.property.GetDefault
admin.vm.property.Help
admin.vm.property.List
admin.vm.property.Reset
admin.vm.property.Set
admin.vm.tag.Get
admin.vm.tag.List
admin.vm.tag.Remove
admin.vm.tag.Set
admin.vm.volume.CloneFrom
admin.vm.volume.CloneTo
admin.vm.volume.Import
admin.vm.volume.ImportWithSize
admin.vm.volume.Info
admin.vm.volume.List
admin.vm.volume.ListSnapshots
admin.vm.volume.Resize
admin.vm.volume.Revert
admin.vm.volume.Set.revisions_to_keep
admin.vm.volume.Set.rw
admin.vmclass.List
include/admin-global-ro
include/admin-global-rwx
include/admin-local-ro
include/admin-local-rwx
policy.RegisterArgument
qubes.ConnectTCP
qubes.FeaturesRequest
qubes.Filecopy
qubes.GetDate
qubes.GetImageRGBA
qubes.GetRandomizedTime
qubes.NotifyTools
qubes.NotifyUpdates
qubes.OpenInVM
qubes.OpenURL
qubes.StartApp
qubes.UpdatesProxy
qubes.VMExec
qubes.VMExecGUI
qubes.VMRootShell
qubes.VMShell
"

for service in $SERVICES; do
    if [ -f "/etc/qubes-rpc/policy/$service.rpmsave" ] && \
            ! [ -e "/etc/qubes-rpc/policy/$service" ]; then
        mv -n "/etc/qubes-rpc/policy/$service.rpmsave" \
            "/etc/qubes-rpc/policy/$service"
    fi
done

# Take extra care about policy files in include/ - if any of them is gone
# (because unmodified) but user still reference them anywhere, the policy
# loading will be broken. Check for this case, and avoid the issue by creating
# a symlink to the new policy.

INCLUDES="admin-global-ro admin-global-rwx admin-local-ro admin-local-rwx"

for include in $INCLUDES; do
    if grep -qr "include/$include" /etc/qubes-rpc && \
            ! [ -e "/etc/qubes-rpc/policy/include/$include" ]; then
        ln -s "../../../qubes/policy.d/include/$include" \
            "/etc/qubes-rpc/policy/include/$include"
    fi
done
}
