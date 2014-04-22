#!/bin/bash
cd /root/funtoo-overlay
# get latest merge.py and friends
git pull || exit 1
/root/funtoo-overlay/funtoo/scripts/merge.py --branch master /var/git/ports-2012 || exit 1
