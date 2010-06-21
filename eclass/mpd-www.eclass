inherit webapp mpd-docs

if [[ "${PV}" == "9999" ]]; then
	if [[ -n "${ESVN_REPO_URI}" ]]; then
		inherit subversion
	elif [[ -n "${EDARCS_REPOSITORY}" ]]; then
		inherit darcs
	elif [[ -n "${EGIT_REPO_URI}" ]]; then
		inherit git
	else
		die "Could not use $0 for this ebuild"
	fi
fi

mpd-www_src_install() {
	webapp_src_preinst

	mpd-docs "$DOCS"
	cp -r . "${D}${MY_HTDOCSDIR}"

	webapp_src_install
}

EXPORT_FUNCTIONS src_install pkg_postinst
