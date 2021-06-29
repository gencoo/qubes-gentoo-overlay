inherit estack eutils

MIRROR="https://vault.centos.org"
DIST=".el8"
RELEASE="8-stream"
BASEOS="${MIRROR}/${RELEASE}/BaseOS/Source/SPackages"
APPSTREAM="${MIRROR}/${RELEASE}/AppStream/Source/SPackages"
POWERTOOLS="${MIRROR}/${RELEASE}/PowerTools/Source/SPackages"

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

rpm_build() {
	[[ $# -eq 0 ]] && set -- ${A}
	rpm_unpack "$@"

	# no .src.rpm files, then nothing to do
	[[ "$* " != *".src.rpm " ]] && return 0

	eshopts_push -s nullglob

	rpmbuild -bp $WORKDIR/*.spec --nodeps --noclean --nodebuginfo --buildroot=$D

	eshopts_pop

	return 0
}

rhel_src_unpack() {
	local a
	for a in ${A} ; do
		case ${a} in
		*.rpm) rpm_build "${a}" ;;
		*)     unpack "${a}" ;;
		esac
	done
}

rhel_src_configure() {
	sed -i 's?^.make_build.*$?exit 0?' ${WORKDIR}/*.spec
	rpmbuild --short-circuit -bc $WORKDIR/*.spec --nodeps --noclean --nodebuginfo --buildroot=$D
}

rhel_src_install() {
	sed -i "/%make_install/d" ${WORKDIR}/*.spec
	sed -i "/make install DESTDIR/d" ${WORKDIR}/*.spec
	rpmbuild --short-circuit -bi $WORKDIR/*.spec --nodeps --noclean --nocheck --nodebuginfo --buildroot=$D
}

EXPORT_FUNCTIONS src_unpack src_configure src_install
