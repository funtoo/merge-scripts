#!/usr/bin/python3

from merge_utils import *

gentoo_use_rsync = False
if gentoo_use_rsync:
	gentoo_src = RsyncTree("gentoo")
else:
	gentoo_src = CvsTree("gentoo-x86",":pserver:anonymous@anoncvs.gentoo.org:/var/cvsroot")
	gentoo_glsa = CvsTree("gentoo-glsa",":pserver:anonymous@anoncvs.gentoo.org:/var/cvsroot", path="gentoo/xml/htdocs/security")

gentoo_dest = GitTree("gentoo-staging", "master", "repos@git.funtoo.org:ports/gentoo-staging.git", root="/var/git/dest-trees/gentoo-staging", pull=False)

all_steps = [
	GitCheckout("master"),
	SyncFromTree(gentoo_src, exclude=["/metadata/cache/**", "ChangeLog", "dev-util/metro"]),
	# Only include 2012 and up GLSA's:
	SyncDir(gentoo_glsa.root, "en/glsa", "metadata/glsa", exclude=["glsa-200*.xml","glsa-2010*.xml", "glsa-2011*.xml"]) if not gentoo_use_rsync else None,
]

gentoo_dest.run(all_steps)
gentoo_dest.gitCommit(message="gentoo updates", branch="master")
