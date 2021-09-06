
EAPI=7

PYTHON_COMPAT=( python3_{6,8,9} )

inherit eutils multilib distutils-r1 qubes

KEYWORDS="amd64"
HOMEPAGE="http://www.qubes-os.org"
LICENSE="GPLv2"

SLOT="0"
IUSE="+pandoc-bin"

DEPEND="dev-python/setuptools[${PYTHON_USEDEP}]
	media-gfx/imagemagick
	dev-util/desktop-file-utils
        qubes-core/libvchan
	qubes-app/img-converter
	qubes-core/admin
	dev-python/pyxdg[${PYTHON_USEDEP}]
        pandoc-bin? (
            app-text/pandoc-bin
        )
        !pandoc-bin? (
            app-text/pandoc
        )
        ${PYTHON_DEPS}
        "
RDEPEND="${DEPEND}
	x11-misc/xdotool"
PDEPEND=""

src_compile() {
	export PYTHONDONTWRITEBYTECODE=
	emake PYTHON=/usr/bin/python
	emake -C doc manpages PYTHON=/usr/bin/python
}

src_install() {
	emake DESTDIR=${D} MANDIR=/usr/share/man PYTHON=/usr/bin/python install
	emake -C doc DESTDIR=${D} MANDIR=/usr/share/man PYTHON=/usr/bin/python install
}

pkg_postinst() {
	for i in /usr/share/qubes/icons/*.png ; do
    		xdg-icon-resource install --noupdate --novendor --size 48 $i
	done
	xdg-icon-resource forceupdate
	#xdg-desktop-menu install /usr/share/qubes-appmenus/qubes-dispvm.directory /usr/share/qubes-appmenus/qubes-dispvm-*.desktop
}

pkg_prerm() {
	# no more packages left

	for i in /usr/share/qubes/icons/*.png ; do
		xdg-icon-resource uninstall --novendor --size 48 $i
	done

	#xdg-desktop-menu uninstall /usr/share/qubes-appmenus/qubes-dispvm.directory /usr/share/qubes-appmenus/qubes-dispvm-*.desktop
}
