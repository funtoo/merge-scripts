#!/bin/bash
eval `keychain --noask --eval id_dsa` || exit 1
/root/git/funtoo-overlay/funtoo/scripts/gentoo-compare-json.py /var/cvs/source-trees/gentoo-x86
