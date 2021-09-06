# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: macros.eclass

_fixperms="/bin/chmod -Rf a+rX,u+w,g-w,o-w"

_rpmconfigdir=/usr/lib/rpm
rpmmacrodir=${_rpmconfigdir}/macros.d
rpmluadir=${_rpmconfigdir}/lua
rpm_macros_dir=$(d=${_rpmconfigdir}/macros.d; [ -d $d ] || d=${_sysconfdir}/rpm; echo $d)

_usr=/usr
_var=/var
buildroot="${ED}"
RPM_BUILD_ROOT="${ED}"

_prefix=/usr
_exec_prefix=${_prefix}
_bindir=${_exec_prefix}/bin
_sbindir=${_exec_prefix}/sbin
_libexecdir=${_exec_prefix}/libexec
_datarootdir=${_prefix}/share
_datadir=${_datarootdir}
_docdir=${_datadir}/doc
_pkgdocdir=${_docdir}/${PN}
_sysconfdir=/etc
_sharedstatedir=/var/lib
_localstatedir=/var
_lib=lib64
_libdir=${_prefix}/lib64
_includedir=${_prefix}/include
_infodir=${_datarootdir}/info
_mandir=${_datarootdir}/man
_initddir=${_sysconfdir}/rc.d/init.d

_systemd_util_dir=${_prefix}/lib/systemd
_unitdir=${_prefix}/lib/systemd/system
_userunitdir=${_prefix}/lib/systemd/user
_presetdir=/lib/systemd/system-preset

rubygems_dir=${_datadir}/rubygems

systemd_post(){
	# Initial installation 
	[[ $# -eq 0 ]] && set -- ${A}
	systemctl enable "$@"
}

systemd_preun(){
	# Package removal, not upgrade 
	[[ $# -eq 0 ]] && set -- ${A}
	systemctl disable "$@"
}

systemd_postun_with_restart(){
	# Package upgrade, not uninstall
	[[ $# -eq 0 ]] && set -- ${A} 
	systemctl restart "$@"
}

systemd_user_post(){
	# Initial installation 
	[[ $# -eq 0 ]] && set -- ${A}
	systemctl --user enable "$@"
}
