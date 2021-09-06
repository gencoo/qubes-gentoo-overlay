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

case ${PN} in
	admin* | qrexec | qubesdb | libvirt ) Q=qubes-core; Q_PN=${Q}-${PN} ;;
	linux-common | linux-manager | linux-xfce4 ) Q=qubes-desktop ; Q_PN=${Q}-${PN} ;;
	libvchan ) Q=qubes; Q_PN=${Q}-core-vchan-xen ;;
	gpg-split | img-converter | input-proxy | usb-proxy ) Q=qubes-app-linux; Q_PN=${Q}-${PN} ;;
	manager | gui-* | infrastructure | xen-hvm-stubdom-linux | blivet | libvirt-python \
	| artwork | grub2* | qubes-release | dummy-* ) Q=qubes; Q_PN=${Q}-${PN} ;;
	gbulb | utils) Q=qubes-linux; Q_PN=${Q}-${PN} ;;
	salt* ) Q=qubes-mgmt; Q_PN=${Q}-${PN} ;;
	*)  ;;
esac

if [[ ${PV} == *9999 ]]; then
	inherit git-r3
	EGIT_COMMIT=HEAD
	EGIT_REPO_URI="https://github.com/QubesOS/${Q_PN}.git"
	S="${WORKDIR}/${Q_PN}"
else
	inherit rhel
	if [ -z ${MY_PF} ] ; then
		MY_PR=${PVR##*r}
		case ${PN} in
			admin|admin-linux ) MY_P=${Q}-${P/admin/dom0}; MY_PF=${MY_P}-${MY_PR} ;;
			libvchan ) MY_P=${Q}-${P/-/-xen-}; MY_PF=${MY_P}-${MY_PR} ;;
			qrexec ) MY_P=${Q}-${P/-/-qrexec-}; MY_PF=${MY_P}-${MY_PR} ;;
			qubesdb ) MY_P=${Q}-${P/db/-db}; MY_PF=${MY_P}-${MY_PR} ;;
			gui-common ) MY_P=${Q}-${P/common/common-devel}; MY_PF=${MY_P}-${MY_PR} ;;
			gpg-split|img-converter|input-proxy ) MY_P=${Q/-app-linux}-${P/converter/converter-dom0}; \
			MY_PF=${MY_P/split/split-dom0}-${MY_PR} ;;
			usb-proxy) MY_P=${Q/-app-linux}-${P}; MY_PF=${MY_P/proxy/proxy-dom0}-${MY_PR} ;;
			infrastructure ) MY_P=qubes-mgmt-salt-dom0-${Q}-${P}; MY_PF=${MY_P}-${MY_PR} ;;
			linux-xfce4 ) MY_P=xfce4-settings-qubes-${PV}; MY_PF=${MY_P}-${MY_PR} ;;
			libvirt* | xen-hvm-stubdom-linux | grub2* | dummy-* ) MY_P=${P}; MY_PF=${P}-${MY_PR} ;;
			gbulb | blivet ) MY_P=${P}; MY_PF=python-${P}-${MY_PR} ;;
			qubes-release ) MY_P=${P}; MY_PF=${P}-0.${MY_PR} ;;
			utils ) MY_P=qubes-${P}; MY_PF=${MY_P}-${MY_PR} ;;
			*) MY_P=${Q}-${P}; MY_PF=${MY_P}-${MY_PR} ;;
		esac
	fi

	S=$WORKDIR/${MY_P}
	SRC_URI="${REPO_URI}/${MY_PF}.${DIST:-fc32}.src.rpm"
fi
