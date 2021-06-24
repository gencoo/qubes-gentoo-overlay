
EAPI=7

PYTHON_COMPAT=( python3_{7,8,9} )

inherit eutils multilib

if [[ ${PV} == *9999 ]]; then
	inherit qubes
	EGIT_COMMIT=HEAD
	EGIT_REPO_URI="https://github.com/QubesOS/qubes-qubes-release.git"
else
	inherit rpm
	MY_PR=0.27
	MY_PF=${P}-${MY_PR}
	SRC_URI="https://mirrors.tuna.tsinghua.edu.cn/qubesos/repo/yum/r4.1/current-testing/dom0/fc32/rpm/${MY_PF}.src.rpm"
fi

KEYWORDS="amd64"
DESCRIPTION="Qubes R4.1 release notes"
HOMEPAGE="http://www.qubes-os.org"
LICENSE="GPLv2"

SLOT="0"
IUSE=""

DEPEND="app-arch/rpm[lua,python]"
RDEPEND="app-arch/rpm-macros"
PDEPEND=""

src_install() {
	install -d ${D}/etc
	echo "Qubes release 4.1 (R4.1)" > ${D}/etc/qubes-release
	echo "cpe:/o:ITL:qubes:4.1" > ${D}/etc/system-release-cpe
	cp -p ${D}/etc/qubes-release ${D}/etc/issue
	echo "Kernel \r on an \m (\l)" >> ${D}/etc/issue
	cp -p ${D}/etc/issue ${D}/etc/issue.net
	echo >> ${D}/etc/issue
	ln -s qubes-release ${D}/etc/fedora-release
	ln -s qubes-release ${D}/etc/redhat-release

	cp ${FILESDIR}/os-release ${D}/etc/os-release

	install -d -m 755 ${D}/etc/pki/rpm-gpg
	install -m 644 RPM-GPG-KEY* ${D}/etc/pki/rpm-gpg/

	install -d -m 755 ${D}/etc/yum.repos.d
	sed -e "s/%%DIST%%/fc%{fedora_base_version}/" qubes-dom0.repo.in > ${D}/etc/yum.repos.d/qubes-dom0.repo
	sed -e "s/%%FCREL%%/%{fedora_base_version}/" fedora.repo.in > ${D}/etc/yum.repos.d/fedora.repo
	sed -e "s/%%FCREL%%/%{fedora_base_version}/" fedora-updates.repo.in > ${D}/etc/yum.repos.d/fedora-updates.repo
	install -m 644 qubes-templates.repo ${D}/etc/yum.repos.d
	install -d -m 755 ${D}/etc/rpm
}
