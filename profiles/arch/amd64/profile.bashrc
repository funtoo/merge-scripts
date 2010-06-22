BAD_FLAGS=( "-fvisibility=hidden" "-fvisibility-hidden" "-fvisibility-inlines-hidden" "-fPIC" "-fpic" "-m32" "-m64" "-g3" "-ggdb3" "-ffast-math" )

getPROG() {
	local var=$1 prog=$2

	if [[ -n ${!var} ]] ; then
		echo "${!var}"
		return 0
	fi

	local search=
	[[ -n $3 ]] && search=$(type -p "$3-${prog}")
	[[ -z ${search} && -n ${CHOST} ]] && search=$(type -p "${CHOST}-${prog}")
	[[ -n ${search} ]] && prog=${search##*/}

	export ${var}=${prog}
	echo "${!var}"
}

get_broken_flags() {
	local myprog="${1}" lang="${2}"
	shift 2

	# this finds general broken flags, such as -02 or bogus -f flags
	echo 'main(){}' | LC_ALL=C ${myprog} ${@} -x ${lang} -o /dev/null - 2>&1 | \
		egrep "unrecognized .*option" | \
		egrep -o -- '('\''|\"|`)-.*' | \
		sed -r 's/('\''|`|")//g; s/^/"/; s/$/"/'
	
	# this will find bogus debug output types, such as -gfoobar
	echo 'main(){}' | LC_ALL=C ${myprog} ${@} -x ${lang} -o /dev/null - 2>&1 | \
		egrep "unrecognised debug output" | \
		egrep -o -- '('\''|\"|`).*' | \
		sed -r 's/('\''|`|")//g; s/^/"-g/; s/$/"/'
}

remove_flag() {
	local remove="${1}"
	shift

	while [[ "${1}" ]]; do
		[[ "${1}" != "${remove}" ]] && echo -n "${1} "
		shift
	done
}

filter_invalid_flags() {
	local flag broken_flags

	eval broken_flags=( $(get_broken_flags $(getPROG CC gcc) c ${CFLAGS}) )
	for flag in "${broken_flags[@]}"; do
		ewarn "Filtering out invalid CFLAG \"${flag}\""
		CFLAGS="$(remove_flag "${flag}" ${CFLAGS})"
	done

	eval broken_flags=( $(get_broken_flags $(getPROG CXX g++) c++ ${CXXFLAGS}) )
	for flag in "${broken_flags[@]}"; do
		ewarn "Filtering out invalid CXXFLAG \"${flag}\""
		CXXFLAGS="$(remove_flag "${flag}" ${CXXFLAGS})"
	done
}

bashrc_has() {
	[[ " ${*:2} " == *" $1 "* ]]
}

if [[ ${EBUILD_PHASE} == "setup" ]]; then

	filter_invalid_flags
	
	unset trigger

	for flag in "${BAD_FLAGS[@]}"; do
		if bashrc_has ${flag} ${CFLAGS}; then
			trigger=1
			eerror "Your CFLAGS contains \"${flag}\" which can break packages."
		fi
		if bashrc_has ${flag} ${CXXFLAGS}; then
			trigger=1
			eerror "Your CXXFLAGS contains \"${flag}\" which can break packages."
		fi
	done
	if [[ ${trigger} ]]; then
		eerror ""
		eerror "Before you file a bug, please remove these flags and "
		eerror "re-compile the package in question as well as all its dependencies"
		sleep 5
	fi

	unset flag trigger
fi

unset BAD_FLAGS
