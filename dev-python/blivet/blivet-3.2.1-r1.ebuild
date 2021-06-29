
EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )

inherit eutils multilib distutils-r1

if [[ ${PV} == *9999 ]]; then
	inherit qubes
	EGIT_COMMIT=HEAD
	EGIT_REPO_URI="https://github.com/QubesOS/qubes-${PN}.git"
	S=$WORKDIR/qubes-${PN}
else
	inherit rpm
	MY_PR=${PVR##*r}
	MY_PF=${P}-${MY_PR}
	SRC_URI="${REPO_URI}/python-${MY_PF}.${DIST}.src.rpm"
fi

KEYWORDS="amd64"
HOMEPAGE="http://www.qubes-os.org"
LICENSE="GPLv2"

SLOT="0"
IUSE=""

DEPEND="dev-python/setuptools[${PYTHON_USEDEP}]
	sys-devel/gettext
        "
RDEPEND="${DEPEND}
	dev-python/six
	dev-python/pyudev
	sys-block/parted
	dev-python/pyparted
	sys-libs/libselinux
	sys-libs/libblockdev[cryptsetup,device-mapper,dmraid,loop,swap,mpath,kbd,lvm]
	sys-apps/util-linux
	dev-libs/libbytesize[python]
	sys-process/lsof
	dev-python/pygobject
	"
PDEPEND=""

src_prepare() {
	default
}

src_compile() {
	export PYTHONDONTWRITEBYTECODE=
	emake  PYTHON=/usr/bin/python
}

src_install() {
	emake PYTHON=/usr/bin/python DESTDIR=${D} install
}
