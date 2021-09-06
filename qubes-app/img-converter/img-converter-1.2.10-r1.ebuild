
EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )

inherit eutils qubes

KEYWORDS="amd64"
DESCRIPTION="The Qubes service for converting untrusted images into trusted ones"
HOMEPAGE="http://www.qubes-os.org"
LICENSE="GPLv2"

SLOT="0"
IUSE=""

DEPEND="qubes-misc/utils
        ${PYTHON_DEPS}
        "
RDEPEND="${DEPEND}"
PDEPEND=""

src_install() {
#	emake install-vm DESTDIR=${D}
	into /usr/bin/
	dobin qvm-get-image qvm-get-tinted-image
}
