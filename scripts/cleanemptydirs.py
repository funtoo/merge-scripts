#!/usr/bin/env python

"""find empty dirs and check for obsolete package.mask entries"""

from os.path import join, getsize, isfile, isdir
from sys import stderr
from portage.versions import pkgsplit
import portage.env.config
import os

# find empty directories
for root, dirs, files in os.walk('.'):
    for ignoredir in ('CVS','.svn','.git','eclass'):
        if ignoredir in dirs:
            dirs.remove(ignoredir)
    if len(dirs)+len(files) == 0:
        print root, "seems to be empty"


# find obsolete package.mask entries
PACKAGE_MASK = join(os.getcwd(), "profiles/package.mask")
TOCHECK = []

if not isfile(PACKAGE_MASK):
	print >> stderr, "can't find package.mask, you must be in the overlay root!"
	exit(1)

PMASK = portage.env.config.PackageMaskFile(PACKAGE_MASK)
PMASK.load()

for key in PMASK.keys():
	# remove =, >=, ~ etc.
	while not key[0].isalpha():
		key = key[1:]
	# remove trailing * or . like in: ...-1.4.* or so
	while key[-1] == "*" or key[-1] == ".":
		key = key[:-1]
	
	if pkgsplit(key):
		TOCHECK.append(pkgsplit(key)[0])
	else:
		TOCHECK.append(key)

for item in TOCHECK:
	if not isdir(item):
		print item, "is obsolete"
