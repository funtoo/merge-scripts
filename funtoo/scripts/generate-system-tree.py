#!/usr/bin/python2

from merge_utils import *

funtoo_src = Tree("funtoo","funtoo.org", "git://github.com/funtoo/portage-mini-2011.git", pull=True, trylocal="/var/git/portage-mini-2011")

steps = [
	CleanTree(),
	SyncDir(funtoo_src.root,"eclass"),
	SyncDir(funtoo_src.root,"profiles"),
	InsertEbuilds(funtoo_src, select=["sys-apps/portage"])
]

sys = UnifiedTree("/var/git/portage-system",steps)
sys.run()

