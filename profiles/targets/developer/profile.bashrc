#!/bin/bash

# We change around a few variables, since we've enabled splitdebug.
debug=0
for flag in ${CFLAGS}
do
	case ${flag} in
		-g*) debug=1 ;;
	esac
done

if [ ${debug} -eq 0 ]
then
	if [[ "${EBUILD_PHASE}" == "setup" ]]
	then
		echo "You should enable -g (or higher) for debugging!"
	fi
fi
