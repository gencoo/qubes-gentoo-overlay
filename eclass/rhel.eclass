# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: rhel.eclass
# @MAINTAINER:
# base-system@gentoo.org
# @SUPPORTED_EAPIS: 5 6 7 8
# @BLURB: convenience class for extracting Red Hat Enterprise Linux Series RPMs

EXPORT_FUNCTIONS src_unpack

if [[ -z ${_RHEL_ECLASS} ]] ; then
_RHEL_ECLASS=1

inherit macros rpm

if [ -z ${MIRROR} ] ; then MIRROR="https://mirrors.tuna.tsinghua.edu.cn"; fi
RELEASE="r4.1"
REPO_URI="${MIRROR}/qubesos/repo/yum/${RELEASE}/current/${REPO:-vm}/${DIST:-fc36}/rpm"

rpm_clean() {
	# delete everything
	rm -f *.patch
	local a
	for a in *.tar.{gz,bz2,xz} *.t{gz,bz2,xz,pxz} *.zip *.ZIP ; do
		rm -f "${a}"
	done
}

# @FUNCTION: rhel_unpack
# @USAGE: <rpms>
# @DESCRIPTION:
# Unpack the contents of the specified Red Hat Enterprise Linux Series rpms like the unpack() function.
rhel_unpack() {
	[[ $# -eq 0 ]] && set -- ${A}

	rpm_unpack "$@"

	RPMBUILD=$HOME/rpmbuild
	mkdir -p $RPMBUILD
	ln -s $WORKDIR $RPMBUILD/SOURCES
	ln -s $WORKDIR $RPMBUILD/BUILD
}

# @FUNCTION: srcrhel_unpack
# @USAGE: <rpms>
# @DESCRIPTION:
# Unpack the contents of the specified rpms like the unpack() function as well
# as any archives that it might contain.  Note that the secondary archive
# unpack isn't perfect in that it simply unpacks all archives in the working
# directory (with the assumption that there weren't any to start with).
srcrhel_unpack() {
	[[ $# -eq 0 ]] && set -- ${A}
	rhel_unpack "$@"

	# no .src.rpm files, then nothing to do
	[[ "$* " != *".src.rpm " ]] && return 0

	FIND_FILE="${WORKDIR}/*.spec"
	FIND_STR="pypi_source"
	if [ `grep -c "$FIND_STR" $FIND_FILE` -ne '0' ] ;then
		echo -e "The spec File Has\c"
		echo -e "\033[33m $FIND_STR \033[0m\c"
		echo "Skipp rpm build through %prep..."
		unpack ${WORKDIR}/*.tar.*
		return 0
	fi

	eshopts_push -s nullglob

	sed -i -e "/%{__python3}/d" \
		${WORKDIR}/*.spec
	
	rpmbuild -bp $WORKDIR/*.spec --nodeps

	eshopts_pop

	return 0
}

# @FUNCTION: rhel_src_unpack
# @DESCRIPTION:
# Automatically unpack all archives in ${A} including rpms.  If one of the
# archives in a source rpm, then the sub archives will be unpacked as well.
rhel_src_unpack() {
	if [[ ${PV} == *9999 ]]; then
		git-r3_src_unpack
		return
	fi

	local a
	for a in ${A} ; do
		case ${a} in
		*.src.rpm) [[ ${a} =~ ".src.rpm" ]] && srcrhel_unpack "${a}" ;;
		*.rpm) [[ ${a} =~ ".rpm" ]] && rpm_unpack "${a}" && mkdir -p $S ;;
		*)     unpack "${a}" ;;
		esac
	done
}

# @FUNCTION: rhel_src_compile
# @DESCRIPTION:
rhel_src_compile() {
	rpmbuild  -bc $WORKDIR/*.spec --nodeps --nodebuginfo
}

# @FUNCTION: rhel_src_install
# @DESCRIPTION:
rhel_src_install() {
	sed -i  -e '/rm -rf $RPM_BUILD_ROOT/d' \
		-e '/meson_install/d' \
		${WORKDIR}/*.spec

	rpmbuild --short-circuit -bi $WORKDIR/*.spec --nodeps --rmsource --nocheck --nodebuginfo --buildroot=$D
}

# @FUNCTION: rhel_bin_install
# @DESCRIPTION:
rhel_bin_install() {
	if use binary; then
		rm -rf $D $S ${S_BASE} "${WORKDIR}/usr/lib/.build-id"
		ln -s "${WORKDIR}" "${PORTAGE_BUILDDIR}/image"
		tree "${ED}"
	fi
}

fi
