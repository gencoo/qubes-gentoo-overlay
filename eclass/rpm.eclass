# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: rpm.eclass
# @MAINTAINER:
# base-system@gentoo.org
# @BLURB: convenience class for extracting RPMs

inherit estack eutils

case "${EAPI:-0}" in
	[0-6]) DEPEND=">=app-arch/rpm2targz-9.0.0.3g" ;;
	*) BDEPEND=">=app-arch/rpm2targz-9.0.0.3g" ;;
esac

rpm_clean() {
	# delete everything
	rm -f *.patch
	local a
	for a in *.tar.{gz,bz2,xz} *.t{gz,bz2,xz,pxz} *.zip *.ZIP ; do
		rm -f "${a}"
	done
}

# @FUNCTION: rpm_unpack
# @USAGE: <rpms>
# @DESCRIPTION:
# Unpack the contents of the specified rpms like the unpack() function.
rpm_unpack() {
	[[ $# -eq 0 ]] && set -- ${A}
	local a
	for a in "$@" ; do
		echo ">>> Unpacking ${a} to ${PWD}"
		if [[ ${a} == ./* ]] ; then
			: nothing to do -- path is local
		elif [[ ${a} == ${DISTDIR}/* ]] ; then
			ewarn 'QA: do not use ${DISTDIR} with rpm_unpack -- it is added for you'
		elif [[ ${a} == /* ]] ; then
			ewarn 'QA: do not use full paths with rpm_unpack -- use ./ paths instead'
		else
			a="${DISTDIR}/${a}"
		fi

		if [[ ${a} =~ ".rpm" ]] ; then
		rpm2tar -O "${a}" | tar xf - || die "failure unpacking ${a}"
		fi
	done

	RPMBUILD=$HOME/rpmbuild
	mkdir -p $RPMBUILD
	ln -s $WORKDIR $RPMBUILD/SOURCES
	ln -s $WORKDIR $RPMBUILD/BUILD
}

# @FUNCTION: srcrpm_unpack
# @USAGE: <rpms>
# @DESCRIPTION:
# Unpack the contents of the specified rpms like the unpack() function as well
# as any archives that it might contain.  Note that the secondary archive
# unpack isn't perfect in that it simply unpacks all archives in the working
# directory (with the assumption that there weren't any to start with).
srcrpm_unpack() {
	[[ $# -eq 0 ]] && set -- ${A}
	rpm_unpack "$@"

	# no .src.rpm files, then nothing to do
	[[ "$* " != *".src.rpm " ]] && return 0

	eshopts_push -s nullglob

	rpmbuild -bp $WORKDIR/*.spec --nodeps

	rpm_clean

	eshopts_pop

	return 0
}

# @FUNCTION: rpm_src_unpack
# @DESCRIPTION:
# Automatically unpack all archives in ${A} including rpms.  If one of the
# archives in a source rpm, then the sub archives will be unpacked as well.
rpm_src_unpack() {
	if [[ ${PV} == *9999 ]]; then
		return 0
	fi

	local a
	for a in ${A} ; do
		case ${a} in
		*.rpm) srcrpm_unpack "${a}" ;;
		*)     unpack "${a}" ;;
		esac
	done
}

# @FUNCTION: rpm_spec_epatch
# @USAGE: [spec]
# @DESCRIPTION:
# Read the specified spec (defaults to ${PN}.spec) and attempt to apply
# all the patches listed in it.  If the spec does funky things like moving
# files around, well this won't handle that.
rpm_spec_epatch() {
	local p spec=$1
	local dir

	if [[ -z ${spec} ]] ; then
		# search likely places for the spec file
		for spec in "${PWD}" "${S}" "${WORKDIR}" ; do
			spec+="/${PN}.spec"
			[[ -e ${spec} ]] && break
		done
	fi
	[[ ${spec} == */* ]] \
		&& dir=${spec%/*} \
		|| dir=

	ebegin "Applying patches from ${spec}"

	grep '^%patch' "${spec}" | \
	while read line ; do
		# expand the %patch line
		set -- ${line}
		p=$1
		shift

		# process the %patch arguments
		local arg
		EPATCH_OPTS=
		for arg in "$@" ; do
			case ${arg} in
			-b) EPATCH_OPTS+=" --suffix" ;;
			*)  EPATCH_OPTS+=" ${arg}" ;;
			esac
		done

		# extract the patch name from the Patch# line
		set -- $(grep "^P${p#%p}: " "${spec}")
		shift
		epatch "${dir:+${dir}/}$*"
	done

	eend
}

EXPORT_FUNCTIONS src_unpack
