#!/bin/sh
# Copyright (c) 2010 by Piotr Karbowski <piotr@funtoo.org>

if [ "$#" -lt 3 ] ; then
	echo 'This script should by running only by metalog'; exit 1
fi

# Newly created files should have permissions 600.
umask 077

# Set lowest possible priority.
renice -n 19 -p $$ > /dev/null
ionice -c 3 -p $$ > /dev/null

logfile="$3"

if [ -s "${logfile}" ] && [ ! -f "${logfile}.bz2" ]; then
	bzip2 -9 "${logfile}"
else
	echo "metalog-postrotate-compress failed on '${logfile}'"; exit 1
fi
