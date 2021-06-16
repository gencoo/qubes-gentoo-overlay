# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit xdg-utils

Q_PN=qubes-desktop-linux-xfce4-xfwm4
Q_PV=4.14.2
Q_PR=1
Q_PVR=${Q_PV}-${Q_PR}
Q_PF=${Q_PN}-${Q_PVR}

DESCRIPTION="Window manager for the Xfce desktop environment"
HOMEPAGE="https://www.xfce.org/projects/"
SRC_URI="https://archive.xfce.org/src/xfce/${PN}/${PV%.*}/${P}.tar.bz2
	https://github.com/QubesOS/${Q_PN}/archive/refs/tags/v${Q_PVR}.tar.gz -> ${Q_PF}.tar.gz"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~ia64 ~mips ppc ppc64 ~sparc x86 ~amd64-linux ~x86-linux ~x86-solaris"
IUSE="opengl startup-notification +xcomposite +xpresent"

RDEPEND=">=dev-libs/glib-2.20
	>=x11-libs/gtk+-3.22:3
	x11-libs/libX11
	x11-libs/libXext
	x11-libs/libXi
	x11-libs/libXinerama
	x11-libs/libXrandr
	x11-libs/libXrender
	x11-libs/libXres
	x11-libs/pango
	>=x11-libs/libwnck-3.14:3
	>=xfce-base/libxfce4util-4.10:=
	>=xfce-base/libxfce4ui-4.12:=
	>=xfce-base/xfconf-4.13:=
	opengl? ( media-libs/libepoxy:=[X(+)] )
	startup-notification? ( x11-libs/startup-notification )
	xcomposite? (
		x11-libs/libXcomposite
		x11-libs/libXdamage
		x11-libs/libXfixes
	)
	xpresent? ( x11-libs/libXpresent )"
# libICE/libSM: not really used anywhere but checked by configure
#   https://bugzilla.xfce.org/show_bug.cgi?id=11914
DEPEND="${RDEPEND}
	x11-libs/libICE
	x11-libs/libSM"
BDEPEND="
	dev-util/intltool
	sys-devel/gettext
	virtual/pkgconfig"

src_prepare() {
	eapply "${FILESDIR}"/0001-Qubes-decoration.patch
	rm "${WORKDIR}"/${Q_PF}/0001-Qubes-decoration.patch
	eapply "${WORKDIR}"/${Q_PF}
	default
}

src_configure() {
	local myconf=(
		$(use_enable opengl epoxy)
		$(use_enable startup-notification)
		$(use_enable xcomposite compositor)
		$(use_enable xpresent)
		--enable-randr
		--enable-render
		--enable-xi2
		--enable-xsync
	)

	econf "${myconf[@]}"
}

pkg_postinst() {
	xdg_icon_cache_update
}

pkg_postrm() {
	xdg_icon_cache_update
}
