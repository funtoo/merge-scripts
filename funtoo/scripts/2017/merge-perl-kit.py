#!/usr/bin/python3
print("HIYO")

import os
from merge_utils import *

# first, try to grab ebuilds from gentoo-staging.
# however, gentoo-core-shard will override if catpkg is there.
# and funtoo-toolchain will override if catpkg is there.
# etc.

branch = "5.24-prime"
kname = "perl"
ports_2012 = GitTree("ports-2012", "funtoo.org", "repos@localhost:funtoo-overlay.git", reponame="biggy", root="/var/git/dest-trees/ports-2012", pull=True)
kit = GitTree("%s-kit" % kname, branch, "repos@localhost:kits/%s-kit.git" % kname, root="/var/git/dest-trees/%s-kit" % kname, pull=True)

steps = [
	GitCheckout(branch),
	CleanTree(),
	GenerateRepoMetadata("%s-kit" % kname),
]

kit.run(steps)
import pdb; pdb.set_trace()
steps2 = generateShardSteps("%s-kit" % kname, ports_2012, kit, clean=False, pkgdir="/root/funtoo-overlay/funtoo/scripts", branch=branch)

kit.run(steps2)
import pdb; pdb.set_trace()

a = getAllEclasses(ebuild_repo=kit, super_repo=ports_2012)
l = getAllLicenses(ebuild_repo=kit, super_repo=ports_2012)
# we must ensure all ebuilds are copied ^^^ before we grab all eclasses used:

steps3 = [
	InsertLicenses(ports_2012, select=list(l)),
	InsertEclasses(ports_2012, select=list(a)),
	CreateCategories(ports_2012),
	GenCache(),
	GenUseLocalDesc()
]

kit.run(steps3)

# vim: ts=4 sw=4 noet
