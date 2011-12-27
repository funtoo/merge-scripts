#!/usr/bin/python2

from merge_utils import *

funtoo_src = Tree("funtoo","funtoo.org", "git://github.com/funtoo/portage-mini-2011.git", pull=True, trylocal="/var/git/portage-mini-2011")

pf = open("stage3.txt","r")
pkgs = []
for line in pf:
	pkgs.append(line[:-1])

steps = [
	CleanTree(),
	SyncDir(funtoo_src.root,"eclass"),
	SyncDir(funtoo_src.root,"profiles"),
	InsertEbuilds(funtoo_src, select=pkgs)
]

sys = UnifiedTree("/var/git/portage-system",steps)
sys.run()

