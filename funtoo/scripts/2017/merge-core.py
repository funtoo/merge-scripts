#!/usr/bin/python3
print("HIYO")

import os
from merge_utils import *

# first, try to grab ebuilds from gentoo-staging.
# however, gentoo-core-shard will override if catpkg is there.
# and funtoo-toolchain will override if catpkg is there.
# etc.
ports_2012 = GitTree("ports-2012", "funtoo.org", "repos@localhost:funtoo-overlay.git", reponame="biggy", root="/var/git/dest-trees/ports-2012", pull=True)
core_kit = GitTree("core-kit", "master", "repos@localhost:kits/core-kit.git", root="/var/git/dest-trees/core-kit", pull=True)

steps = [
	GitCheckout("master"),
	CleanTree(),
	GenerateRepoMetadata("core-kit", aliases=["gentoo"]),
	SyncDir(ports_2012.root, "profiles", exclude=["repo_name"]),
	SyncDir(ports_2012.root,"metadata", exclude=["cache","md5-cache","layout.conf"]),
	SyncFiles(ports_2012.root, {
		"COPYRIGHT.txt":"COPYRIGHT.txt",
		"LICENSE.txt":"LICENSE.txt",
		"README.rst":"README.rst",
		"header.txt":"header.txt",
	}),
]

core_kit.run(steps)

steps2 = generateShardSteps("core-kit", ports_2012, core_kit, clean=False, pkgdir="/root/funtoo-overlay/funtoo/scripts")

core_kit.run(steps2)

a = getAllEclasses(ebuild_repo=core_kit, super_repo=ports_2012)
l = getAllLicenses(ebuild_repo=core_kit, super_repo=ports_2012)
# we must ensure all ebuilds are copied ^^^ before we grab all eclasses used:

steps3 = [
	InsertLicenses(ports_2012, select=list(l)),
	InsertEclasses(ports_2012, select=list(a)),
	CreateCategories(ports_2012),
	GenCache(),
	GenUseLocalDesc()
]

core_kit.run(steps3)
core_kit.gitCommit(message="auto-generated updates",branch=False)

# vim: ts=4 sw=4 noet
