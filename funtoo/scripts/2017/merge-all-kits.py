#!/usr/bin/python3
print("HIYO")

import os
from merge_utils import *

# This script will update all kits listed below and ensure that proper sets of licenses and eclasses are included in the kit.
# It will also ensure the use.local.desc and profiles/categories are generated properly.

# In theory, we should generate the prime kits only once, to initialize them:

prime_kits = [
	{ 'name' : 'core', 'branch' : '1.0-prime', 'source' : 'funtoo' },
	{ 'name' : 'editors', 'branch' : '1.0-prime', 'source': 'funtoo' },
	{ 'name' : 'perl', 'branch' : '5.24-prime', 'source': 'funtoo' },
	{ 'name' : 'python', 'branch' : '3.4-prime', 'source': 'funtoo' },
	{ 'name' : 'security', 'branch' : '1.0-prime', 'source': 'funtoo' },
]

# The non-prime branches can be updated frequently as they will pull in changes from gentoo:

gentoo_kits = [
	{ 'name' : 'core', 'branch' : 'master', 'source' : 'gentoo' },
	{ 'name' : 'editors', 'branch' : 'master', 'source': 'gentoo' },
	{ 'name' : 'perl', 'branch' : 'master', 'source': 'gentoo' },
	{ 'name' : 'python', 'branch' : 'master', 'source': 'gentoo' },
	{ 'name' : 'xorg', 'branch' : 'master', 'source': 'gentoo' },
	{ 'name' : 'security', 'branch' : 'master', 'source': 'gentoo' },
]

def updateKit(name, branch, source_repo):
	kit = GitTree("%s-kit" % kname, branch, "repos@localhost:kits/%s-kit.git" % kname, root="/var/git/dest-trees/%s-kit" % kname, pull=True)

	steps = [
		GitCheckout(branch),
		CleanTree(),
	]

	if name == "core":
		# special extra steps for core-kit:
		steps += [
			GenerateRepoMetadata("core-kit", aliases=["gentoo"]),
			SyncDir(source_repo.root, "profiles", exclude=["repo_name"]),
			SyncDir(source_repo.root,"metadata", exclude=["cache","md5-cache","layout.conf"]),
			SyncFiles(source_repo.root, {
				"COPYRIGHT.txt":"COPYRIGHT.txt",
				"LICENSE.txt":"LICENSE.txt",
				"README.rst":"README.rst",
				"header.txt":"header.txt",
			})
		]
	else:
		# non-core repos have slightly different metadata
		steps += GenerateRepoMetadata("%s-kit" % kname, masters=["core-kit"]),
	
	# from here on in, kit steps should be the same for core-kit and others:

	kit.run(steps)
	steps2 = generateShardSteps("%s-kit" % kname, source_repo, kit, clean=False, pkgdir="/root/funtoo-overlay/funtoo/scripts", branch=branch)

	kit.run(steps2)

	a = getAllEclasses(ebuild_repo=kit, super_repo=source_repo)
	l = getAllLicenses(ebuild_repo=kit, super_repo=source_repo)
	# we must ensure all ebuilds are copied ^^^ before we grab all eclasses used:

	steps3 = [
		InsertLicenses(source_repo, select=list(l)),
		InsertEclasses(source_repo, select=list(a)),
		CreateCategories(source_repo),
		GenCache(),
		GenUseLocalDesc()
	]

	kit.run(steps3)
	kit.gitCommit(message="updates",branch=branch)

if __name__ == "__main__":

	import sys

	if len(sys.argv) != 2 or sys.argv[1] not in [ "prime", "gentoo" ]:
		print("Please specify either 'prime' for funtoo prime kits, or 'gentoo' for updating master branches using gentoo.")
		sys.exit(1)
	elif sys.argv[1] == "prime":
		kits = prime_kits
	elif sys.argv[2] == "gentoo"
		kits = gentoo_kits
	
	for kitdict in kits:
		branch = kitdict['branch']
		name = kitdict['name']
		source = kitdict['source']

		source_repo = GitTree("ports-2012", "funtoo.org", "repos@localhost:funtoo-overlay.git", reponame="biggy", root="/var/git/dest-trees/ports-2012", pull=True)
		gentoo_staging = GitTree("gentoo-staging", "master", "repos@localhost:ports/gentoo-staging.git", root="/var/git/dest-trees/gentoo-staging", pull=False)

		if source == 'gentoo':
			src_repo = gentoo_staging
		else:
			src_repo = source_repo
		updateKit(name, branch, src_repo)

# vim: ts=4 sw=4 noet
