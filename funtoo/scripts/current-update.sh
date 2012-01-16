#!/bin/bash
eval `keychain --noask --eval id_dsa`  || exit 1

/root/git/funtoo-overlay/funtoo/scripts/merge.py --branch master /var/git/portage-mini-2011 || exit 1
