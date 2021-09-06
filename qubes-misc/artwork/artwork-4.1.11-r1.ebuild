
EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )

inherit eutils multilib distutils-r1 qubes

KEYWORDS="amd64"
HOMEPAGE="http://www.qubes-os.org"
LICENSE="GPLv2"

SLOT="0"
IUSE=" "

DEPEND="media-gfx/inkscape
	media-gfx/imagemagick
	media-libs/netpbm
	qubes-misc/utils
	"
RDEPEND="sys-boot/plymouth
	sys-kernel/dracut
	"
PDEPEND=""

src_prepare() {
	default
}

src_compile() {
	emake PYTHON=${EPYTHON}
}

src_install() {
	emake install DESTDIR=${D} PYTHON=${EPYTHON}
	# triggerin plymouth -- plymouth
	/usr/sbin/plymouth-set-default-theme qubes-dark || :
	
}

pkg_postinst() {
	/usr/sbin/plymouth-set-default-theme qubes-dark && \
	PATH="/sbin:$PATH" dracut -f || :
	xdg-icon-resource forceupdate --theme hicolor || :
	xdg-icon-resource forceupdate --theme oxygen || :
}
