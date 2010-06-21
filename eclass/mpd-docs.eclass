mpd-docs() {
	if [[ -n "$@" ]]; then
		dodoc ${@}
		for doc in ${@}; do
			rm -f ${doc}
		done
	fi
}
