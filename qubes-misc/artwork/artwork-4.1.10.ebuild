
EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )

inherit eutils multilib distutils-r1

Q=qubes
if [[ ${PV} == *9999 ]]; then
	inherit qubes
	Q_PN=${Q}-${PN}
	EGIT_REPO_URI="https://github.com/QubesOS/${Q_PN}.git"
	S=$WORKDIR/${Q_PN}
else
	inherit rpm
	MY_PR=1
	MY_P=${Q}-${P}
	SRC_URI="https://mirrors.tuna.tsinghua.edu.cn/qubesos/repo/yum/r4.1/current-testing/dom0/fc32/rpm/${MY_P}-${MY_PR}.fc32.src.rpm"
	S=$WORKDIR/${MY_P}
fi

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
	emake PYTHON=/usr/bin/python
}

src_install() {
	emake install DESTDIR=${D} PYTHON=/usr/bin/python
	# triggerin plymouth -- plymouth
	/usr/sbin/plymouth-set-default-theme qubes-dark || :
	
}

pkg_postinst() {
	/usr/sbin/plymouth-set-default-theme qubes-dark && \
	PATH="/sbin:$PATH" dracut -f || :
	xdg-icon-resource forceupdate --theme hicolor || :
	xdg-icon-resource forceupdate --theme oxygen || :
}
