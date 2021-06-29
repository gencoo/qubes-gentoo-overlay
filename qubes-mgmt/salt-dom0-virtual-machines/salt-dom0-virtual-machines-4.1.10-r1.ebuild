
EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )

inherit eutils multilib python-single-r1

Q=qubes-mgmt
if [[ ${PV} == *9999 ]]; then
	inherit qubes
	Q_PN=${Q}-${PN}
	EGIT_REPO_URI="https://github.com/QubesOS/${Q_PN}.git"
	S=$WORKDIR/${Q_PN}
else
	inherit rpm
	MY_PR=${PVR##*r}
	MY_P=${Q}-${P}
	SRC_URI="${REPO_URI}/${MY_P}-${MY_PR}.${DIST}.src.rpm"
	S=$WORKDIR/${MY_P}
fi

KEYWORDS="amd64"
HOMEPAGE="http://www.qubes-os.org"
LICENSE="GPLv2"

SLOT="0"
IUSE=""

DEPEND=""
RDEPEND="qubes-core/admin-client
	qubes-mgmt/salt
	"
PDEPEND=""


src_compile() {
	export PYTHONDONTWRITEBYTECODE=
	emake DESTDIR="${D}" LIBDIR=/usr/$(get_libdir) BINDIR=/usr/bin SBINDIR=/usr/sbin SYSCONFDIR=/etc PYTHON="/usr/bin/python3"
}

src_install() {
	emake install DESTDIR="${D}" LIBDIR=/usr/$(get_libdir) BINDIR=/usr/bin SBINDIR=/usr/sbin SYSCONFDIR=/etc PYTHON="/usr/bin/python3"
}

pkg_preinst() {
	if [ $1 -ge 2 ] && ! [ -e /srv/formulas/base/virtual-machines-formula/qvm/default-mgmt-dvm.sls ]; then
   	 	touch /var/run/%{name}-default-mgmt-dvm-firstinstall
	fi
}

pkg_postinst() {
	# Enable Pillar States
	qubesctl top.enable qvm pillar=true -l quiet --out quiet > /dev/null || true

	# Migrate enabled tops from dom0 to base environment
	for top in sys-net sys-firewall sys-whonix anon-whonix personal work untrusted vault sys-usb sys-net-with-usb; do
    	if [ -h /srv/salt/_tops/dom0/qvm.$top.top ]; then
        	rm -f /srv/salt/_tops/dom0/qvm.$top.top
        	qubesctl top.enable qvm.$top -l quiet --out quiet > /dev/null || true
    	fi
	done

	if [ -r /srv/pillar/_tops/dom0/qvm.top ]; then
    		rm -f /srv/pillar/_tops/dom0/qvm.top
	fi
	
	if [ -e /var/run/${PN}-default-mgmt-dvm-firstinstall ]; then
    		# create default-mgmt-dvm on update, see QSB#45
    		qubesctl state.sls qvm.default-mgmt-dvm
    		rm /var/run/${PN}-default-mgmt-dvm-firstinstall
	fi
}
