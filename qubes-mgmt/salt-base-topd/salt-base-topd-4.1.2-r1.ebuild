
EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )

inherit eutils multilib python-single-r1 qubes

KEYWORDS="amd64"
HOMEPAGE="http://www.qubes-os.org"
LICENSE="GPLv2"

SLOT="0"
IUSE=""

DEPEND=""
RDEPEND="qubes-mgmt/salt"
PDEPEND=""

#S=$WORKDIR/

src_compile() {
	export PYTHONDONTWRITEBYTECODE=
	emake DESTDIR="${D}" LIBDIR=/usr/$(get_libdir) BINDIR=/usr/bin SBINDIR=/usr/sbin SYSCONFDIR=/etc PYTHON="/usr/bin/python3"
}

src_install() {
	emake install DESTDIR="${D}" LIBDIR=/usr/$(get_libdir) BINDIR=/usr/bin SBINDIR=/usr/sbin SYSCONFDIR=/etc PYTHON="/usr/bin/python3"
	fowners root:root /srv/salt/topd && fperms 750 /srv/salt/topd	
}

pkg_postinst() {
	# Update Salt Configuration
	salt-call --local saltutil.clear_cache -l quiet --out quiet > /dev/null || true
	salt-call --local saltutil.sync_all refresh=true -l quiet --out quiet > /dev/null || true

	# Enable States
	/usr/bin/salt-call --local top.enable topd saltenv=base -l quiet --out quiet > /dev/null || true

	# Enable Pillars
	/usr/bin/salt-call --local top.enable topd.config saltenv=base pillar=true -l quiet --out quiet > /dev/null || true
}
