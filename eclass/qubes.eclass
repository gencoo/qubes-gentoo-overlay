# Maintainer: Frédéric Pierret <frederic.pierret@qubes-os.org>

# Workaround for verifying git tags
# Feature request: https://bugs.gentoo.org/733430
qubes_verify_sources_git() {
    QUBES_OVERLAY_DIR="$(portageq get_repo_path / qubes)"
    # Import Qubes developers keys
    gpg --import "${QUBES_OVERLAY_DIR}/keys/qubes-developers-keys.asc" 2>/dev/null
    # Trust Qubes Master Signing Key
    echo '427F11FD0FAA4B080123F01CDDFA1A3E36879494:6:' | gpg --import-ownertrust

    VALID_TAG_FOUND=0
    for tag in $(git tag --points-at="$1"); do
        if git verify-tag --raw "$tag" 2>&1 | grep -q '^\[GNUPG:\] TRUST_\(FULLY\|ULTIMATE\)'; then
            VALID_TAG_FOUND=1
        fi
    done

    if [ "$VALID_TAG_FOUND" -eq 0 ]; then
        die 'Signature verification failed!'
    fi
}

if [[ ${PV} == *9999 ]]; then
	inherit git-r3
	QUBES_GIT_REPO_URI="https://github.com/QubesOS"
	EGIT_REPO_URI="${QUBES_GIT_REPO_URI}/${PN}.git"
	S="${WORKDIR}/${PN}"
else
	inherit rpm
	MIRROR="https://mirrors.tuna.tsinghua.edu.cn/qubesos/repo/yum"
	DIST="fc33"
	RELEASE="r4.1"
	REPO_URI="${MIRROR}/${RELEASE}/current-testing/vm/${DIST}/rpm"

	if [ -z ${MY_PF} ] ; then
		MY_PR=1
		case ${PN} in
			qubes-core-agent-linux ) MY_P=${P/-linux}; MY_PF=${MY_P}-${MY_PR}; S=${WORKDIR}/${MY_P} ;;
			qubes-gui-common ) MY_P=${PN}-devel-${PV}; MY_PF=${MY_P}-${MY_PR}; S=${WORKDIR}/${MY_P} ;;
			*) MY_PF=${P}-${MY_PR} ;;
		esac
	fi

	SRC_URI="${REPO_URI}/${MY_PF}.${DIST}.src.rpm"
fi

