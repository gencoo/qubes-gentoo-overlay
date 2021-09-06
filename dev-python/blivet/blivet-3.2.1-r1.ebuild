
EAPI=7

PYTHON_COMPAT=( python3_{6,8,9} )

inherit distutils-r1 qubes

KEYWORDS="amd64"
HOMEPAGE="http://www.qubes-os.org"
LICENSE="GPLv2"

SLOT="0"
IUSE=""

DEPEND="dev-python/setuptools[${PYTHON_USEDEP}]
	sys-devel/gettext
        "
RDEPEND="${DEPEND}
	dev-python/six[${PYTHON_USEDEP}]
	dev-python/pyudev[${PYTHON_USEDEP}]
	sys-block/parted
	dev-python/pyparted[${PYTHON_USEDEP}]
	sys-libs/libselinux
	sys-libs/libblockdev[cryptsetup,device-mapper,dmraid,loop,swap,mpath,kbd,lvm]
	sys-apps/util-linux
	dev-libs/libbytesize[python]
	sys-process/lsof
	dev-python/pygobject[${PYTHON_USEDEP}]
	"
PDEPEND=""
