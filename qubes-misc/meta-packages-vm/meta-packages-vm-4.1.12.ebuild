
EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )

inherit eutils

KEYWORDS="amd64"
DESCRIPTION="metapackage"
HOMEPAGE="http://www.qubes-os.org"
LICENSE="GPLv2"

SLOT="0"
IUSE=" "

DEPEND=""
RDEPEND="
	app-arch/rpm
	app-emulation/qubes-gui-common
	app-emulation/qubes-libvchan-xen
	app-emulation/qubes-db
	app-emulation/qubes-utils
	app-emulation/qubes-gpg-split
	app-emulation/qubes-input-proxy
	app-emulation/qubes-usb-proxy
	app-emulation/qubes-core-agent-linux
	app-emulation/qubes-gui-agent
	app-emulation/qubes-img-converter
	app-emulation/qubes-core-qrexec
	app-emulation/qubes-pdf-converter
	"
PDEPEND=""
