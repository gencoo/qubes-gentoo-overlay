
EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )

inherit eutils multilib distutils-r1
Q=qubes-desktop
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
IUSE="+pandoc-bin"

DEPEND="dev-python/setuptools[${PYTHON_USEDEP}]
	media-gfx/imagemagick
	dev-util/desktop-file-utils
        qubes-core/libvchan
	qubes-app/img-converter
	qubes-core/admin
	dev-python/pyxdg
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

src_prepare() {
	default
}

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
