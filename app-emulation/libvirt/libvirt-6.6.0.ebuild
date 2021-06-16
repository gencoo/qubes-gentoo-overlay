
EAPI=7

PYTHON_COMPAT=( python3_{6,7,8,9} )

inherit autotools out-of-source bash-completion-r1 eutils linux-info python-any-r1 readme.gentoo-r1 systemd
Q=qubes-core
if [[ ${PV} = *9999* ]]; then
	inherit qubes
	Q_PN=${Q}-${PN}
	EGIT_COMMIT=HEAD
	EGIT_REPO_URI="https://github.com/QubesOS/${Q_PN}.git"
	S=$WORKDIR/${Q_PN}
	SLOT="0"
else
	inherit rpm
	MY_PR=2
	MY_PF=${P}-${MY_PR}
	SRC_URI="https://mirrors.tuna.tsinghua.edu.cn/qubesos/repo/yum/r4.1/current-testing/dom0/fc32/rpm/${MY_PF}.fc32.src.rpm"
	SLOT="0/${PV}"
fi

KEYWORDS="amd64 x86"
DESCRIPTION="C toolkit to manipulate virtual machines"
HOMEPAGE="https://www.libvirt.org/"
LICENSE="LGPL-2.1"
IUSE="
	apparmor audit +caps dbus dtrace firewalld fuse glusterfs iscsi
	iscsi-direct +libvirtd +lvm libssh lxc macvtap nfs nls numa openvz
	+parted pcap policykit +qemu rbd sasl selinux +udev vepa
	virtualbox virt-network wireshark-plugins xen zfs
"

REQUIRED_USE="
	firewalld? ( virt-network )
	libvirtd? ( || ( lxc openvz qemu virtualbox xen ) )
	lxc? ( caps libvirtd )
	openvz? ( libvirtd )
	policykit? ( dbus )
	qemu? ( libvirtd )
	vepa? ( macvtap )
	virt-network? ( libvirtd )
	virtualbox? ( libvirtd )
	xen? ( libvirtd )"

# gettext.sh command is used by the libvirt command wrappers, and it's
# non-optional, so put it into RDEPEND.
# We can use both libnl:1.1 and libnl:3, but if you have both installed, the
# package will use 3 by default. Since we don't have slot pinning in an API,
# we must go with the most recent
RDEPEND="
	acct-user/qemu
	policykit? ( acct-group/libvirt )
	app-misc/scrub
	>=dev-libs/glib-2.48.0
	dev-libs/libgcrypt:0
	dev-libs/libnl:3
	>=dev-libs/libxml2-2.7.6
	>=net-analyzer/openbsd-netcat-1.105-r1
	>=net-libs/gnutls-1.0.25:0=
	net-libs/libssh2
	net-libs/libtirpc
	net-libs/rpcsvc-proto
	>=net-misc/curl-7.18.0
	sys-apps/dmidecode
	>=sys-apps/util-linux-2.17
	sys-devel/gettext
	sys-libs/ncurses:0=
	sys-libs/readline:=
	apparmor? ( sys-libs/libapparmor )
	audit? ( sys-process/audit )
	caps? ( sys-libs/libcap-ng )
	dbus? ( sys-apps/dbus )
	dtrace? ( dev-util/systemtap )
	firewalld? ( >=net-firewall/firewalld-0.6.3 )
	fuse? ( sys-fs/fuse:0= )
	glusterfs? ( >=sys-cluster/glusterfs-3.4.1 )
	iscsi? ( sys-block/open-iscsi )
	iscsi-direct? ( >=net-libs/libiscsi-1.18.0 )
	libssh? ( net-libs/libssh )
	lvm? ( >=sys-fs/lvm2-2.02.48-r2[-device-mapper-only(-)] )
	nfs? ( net-fs/nfs-utils )
	numa? (
		>sys-process/numactl-2.0.2
		sys-process/numad
	)
	parted? (
		>=sys-block/parted-1.8[device-mapper]
		sys-fs/lvm2[-device-mapper-only(-)]
	)
	pcap? ( >=net-libs/libpcap-1.0.0 )
	policykit? ( >=sys-auth/polkit-0.9 )
	qemu? (
		>=app-emulation/qemu-1.5.0
		dev-libs/yajl
	)
	rbd? ( sys-cluster/ceph )
	sasl? ( dev-libs/cyrus-sasl )
	selinux? ( >=sys-libs/libselinux-2.0.85 )
	virt-network? (
		net-dns/dnsmasq[script]
		net-firewall/ebtables
		>=net-firewall/iptables-1.4.10[ipv6]
		net-misc/radvd
		sys-apps/iproute2[-minimal]
	)
	virtualbox? ( || ( app-emulation/virtualbox >=app-emulation/virtualbox-bin-2.2.0 ) )
	wireshark-plugins? ( net-analyzer/wireshark:= )
	xen? (
		>=app-emulation/xen-4.6.0
		app-emulation/xen-tools:=
	)
	udev? (
		virtual/udev
		>=x11-libs/libpciaccess-0.10.9
	)
	zfs? ( sys-fs/zfs )"

DEPEND="${RDEPEND}
	${PYTHON_DEPS}
	app-text/xhtml1
	dev-lang/perl
	dev-libs/libxslt
	dev-perl/XML-XPath
	dev-python/docutils
	virtual/pkgconfig
	net-firewall/iptables
	net-firewall/ebtables"

PATCHES=(
	"${FILESDIR}"/${PN}-6.0.0-fix_paths_in_libvirt-guests_sh.patch
)

pkg_setup() {
	# Check kernel configuration:
	CONFIG_CHECK=""
	use fuse && CONFIG_CHECK+="
		~FUSE_FS"

	use lvm && CONFIG_CHECK+="
		~BLK_DEV_DM
		~DM_MULTIPATH
		~DM_SNAPSHOT"

	use lxc && CONFIG_CHECK+="
		~BLK_CGROUP
		~CGROUP_CPUACCT
		~CGROUP_DEVICE
		~CGROUP_FREEZER
		~CGROUP_NET_PRIO
		~CGROUP_PERF
		~CGROUPS
		~CGROUP_SCHED
		~CPUSETS
		~IPC_NS
		~MACVLAN
		~NAMESPACES
		~NET_CLS_CGROUP
		~NET_NS
		~PID_NS
		~POSIX_MQUEUE
		~SECURITYFS
		~USER_NS
		~UTS_NS
		~VETH
		~!GRKERNSEC_CHROOT_MOUNT
		~!GRKERNSEC_CHROOT_DOUBLE
		~!GRKERNSEC_CHROOT_PIVOT
		~!GRKERNSEC_CHROOT_CHMOD
		~!GRKERNSEC_CHROOT_CAPS"

	kernel_is lt 4 7 && use lxc && CONFIG_CHECK+="
		~DEVPTS_MULTIPLE_INSTANCES"

	use macvtap && CONFIG_CHECK+="
		~MACVTAP"

	use virt-network && CONFIG_CHECK+="
		~BRIDGE_EBT_MARK_T
		~BRIDGE_NF_EBTABLES
		~NETFILTER_ADVANCED
		~NETFILTER_XT_CONNMARK
		~NETFILTER_XT_MARK
		~NETFILTER_XT_TARGET_CHECKSUM
		~IP_NF_FILTER
		~IP_NF_MANGLE
		~IP_NF_NAT
		~IP_NF_TARGET_MASQUERADE
		~IP6_NF_FILTER
		~IP6_NF_MANGLE
		~IP6_NF_NAT"
	# Bandwidth Limiting Support
	use virt-network && CONFIG_CHECK+="
		~BRIDGE_EBT_T_NAT
		~IP_NF_TARGET_REJECT
		~NET_ACT_POLICE
		~NET_CLS_FW
		~NET_CLS_U32
		~NET_SCH_HTB
		~NET_SCH_INGRESS
		~NET_SCH_SFQ"

	# Handle specific kernel versions for different features
	kernel_is lt 3 6 && CONFIG_CHECK+=" ~CGROUP_MEM_RES_CTLR"
	if kernel_is ge 3 6; then
		CONFIG_CHECK+=" ~MEMCG ~MEMCG_SWAP "
		kernel_is lt 4 5 && CONFIG_CHECK+=" ~MEMCG_KMEM "
	fi

	ERROR_USER_NS="Optional depending on LXC configuration."

	if [[ -n ${CONFIG_CHECK} ]]; then
		linux-info_pkg_setup
	fi
}

src_unpack() {
	if [[ ${PV} != *9999* ]]; then
		rpm_src_unpack ${A}
	fi
}

src_prepare() {
	touch "${S}/.mailmap"

	default

	# Tweak the init script:
	cp "${FILESDIR}/libvirtd.init-r19" "${S}/libvirtd.init" || die
	sed -e "s/USE_FLAG_FIREWALLD/$(usex firewalld 'need firewalld' '')/" \
		-i "${S}/libvirtd.init" || die "sed failed"

	eautoreconf
	rm ${S}/src/remote/libvirt.conf
	cp ${FILESDIR}/libvirt.conf ${S}/src/remote/
}

my_src_configure() {
	unset CFLAGS
	local myeconfargs=(
		$(use_with apparmor)
		$(use_with apparmor apparmor-profiles)
		$(use_with audit)
		$(use_with caps capng)
		$(use_with dtrace)
		$(use_with firewalld)
		$(use_with fuse)
		$(use_with glusterfs)
		$(use_with glusterfs storage-gluster)
		$(use_with iscsi storage-iscsi)
		$(use_with iscsi-direct storage-iscsi-direct)
		$(use_with libvirtd)
		$(use_with libssh)
		$(use_with lvm storage-lvm)
		$(use_with lvm storage-mpath)
		$(use_with lxc)
		$(use_with macvtap)
		$(use_enable nls)
		$(use_with numa numactl)
		$(use_with numa numad)
		$(use_with openvz)
		$(use_with parted storage-disk)
		$(use_with pcap libpcap)
		$(use_with policykit polkit)
		$(use_with qemu)
		$(use_with qemu yajl)
		$(use_with rbd storage-rbd)
		$(use_with sasl)
		$(use_with selinux)
		$(use_with udev)
		$(use_with vepa virtualport)
		$(use_with virt-network network)
		$(use_with wireshark-plugins wireshark-dissector)
		$(use_with xen libxl)
		$(use_with zfs storage-zfs)

		--without-hal
		--without-netcf
		--without-sanlock
		--without-storage-fs
		--without-vmware
		--without-bhyve
		--without-vz
		--without-esx
		--without-pm-utils
		--without-nss-plugin
		--without-storage-vstorage

		--with-init-script=systemd
		--with-qemu-group=$(usex caps qemu)
		--with-qemu-user=$(usex caps qemu)
		--with-remote
		--with-storage-disk
		--with-tls-priority="@LIBVIRT,SYSTEM"
		--with-driver-modules
		--with-interface
		--with-storage-scsi
		--with-yajl
		--disable-static
		--disable-werror
		--with-remote-default-mode=legacy
		--localstatedir=/var
		--with-runstatedir=/run
		--enable-dependency-tracking
	)

	if use virtualbox && has_version app-emulation/virtualbox-ose; then
		myeconfargs+=( --with-vbox=/usr/lib/virtualbox-ose/ )
	else
		myeconfargs+=( $(use_with virtualbox vbox) )
	fi

	econf "${myeconfargs[@]}"
}

my_src_test() {
	# remove problematic tests, bug #591416, bug #591418
	sed -i -e 's#commandtest$(EXEEXT) # #' \
		-e 's#virfirewalltest$(EXEEXT) # #' \
		-e 's#nwfilterebiptablestest$(EXEEXT) # #' \
		-e 's#nwfilterxml2firewalltest$(EXEEXT)$##' \
		tests/Makefile

	export VIR_TEST_DEBUG=1
	HOME="${T}" emake check
}

my_src_install() {
	emake DESTDIR="${D}" \
		SYSTEMD_UNIT_DIR="$(systemd_get_systemunitdir)" install

	find "${D}" -name '*.la' -delete || die

	# Remove bogus, empty directories. They are either not used, or
	# libvirtd is able to create them on demand
	rm -rf "${D}"/etc/sysconfig
	rm -rf "${D}"/var
	rm -rf "${D}"/run

	newbashcomp "${S}/tools/bash-completion/vsh" virsh
	bashcomp_alias virsh virt-admin
}

pkg_preinst() {
	# we only ever want to generate this once
	if [[ -e "${ROOT}"/etc/libvirt/qemu/networks/default.xml ]]; then
		rm -rf "${D}"/etc/libvirt/qemu/networks/default.xml
	fi
}

pkg_postinst() {
	if [[ -e "${ROOT}"/etc/libvirt/qemu/networks/default.xml ]]; then
		touch "${ROOT}"/etc/libvirt/qemu/networks/default.xml
	fi
	systemctl enable virtlockd.socket virtlockd-admin.socket virtlogd.socket virtlogd-admin.socket
	systemctl enable libvirtd.socket libvirtd-ro.socket libvirtd-admin.socket
	systemctl enable libvirtd.service
}
