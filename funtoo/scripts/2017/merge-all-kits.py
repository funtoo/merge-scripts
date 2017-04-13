#!/usr/bin/python3

import os
from merge_utils import *

fo_path = os.path.realpath(os.path.join(__file__,"../../../.."))

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
#	{ 'name' : 'core', 'branch' : 'master', 'source' : 'gentoo' },
#	{ 'name' : 'editors', 'branch' : 'master', 'source': 'gentoo' },
#	{ 'name' : 'perl', 'branch' : 'master', 'source': 'gentoo' },
#	{ 'name' : 'python', 'branch' : 'master', 'source': 'gentoo' },
	{ 'name' : 'xorg', 'branch' : 'master', 'source': 'gentoo' },
#	{ 'name' : 'security', 'branch' : 'master', 'source': 'gentoo' },
]

def updateKit(kname, branch, source_repo, kitted_catpkgs):
	kit = GitTree("%s-kit" % kname, branch, "repos@localhost:kits/%s-kit.git" % kname, root="/var/git/dest-trees/%s-kit" % kname, pull=True)

	steps = [
		GitCheckout(branch),
		CleanTree(),
	]

	if kname == "core":
		# special extra steps for core-kit:
		steps += [
			GenerateRepoMetadata("core-kit", aliases=["gentoo"]),
			SyncDir(source_repo.root, "profiles", exclude=["repo_name"]),
			SyncDir(source_repo.root, "metadata", exclude=["cache","md5-cache","layout.conf"]),
			# grab from the funtoo_overlay that this script is in:
			SyncFiles(fo_path, {
				"COPYRIGHT.txt":"COPYRIGHT.txt",
				"LICENSE.txt":"LICENSE.txt",
			})
		]
	else:
		# non-core repos have slightly different metadata
		steps += GenerateRepoMetadata("%s-kit" % kname, masters=["core-kit"]),
	
	# from here on in, kit steps should be the same for core-kit and others:

	kit.run(steps)
	steps2 = generateShardSteps("%s-kit" % kname, source_repo, kit, clean=False, pkgdir="/root/funtoo-overlay/funtoo/scripts", branch=branch, catpkg_dict=kitted_catpkgs)

	kit.run(steps2)

	a = getAllEclasses(ebuild_repo=kit, super_repo=source_repo)
	l = getAllLicenses(ebuild_repo=kit, super_repo=source_repo)
	# we must ensure all ebuilds are copied ^^^ before we grab all eclasses used:

	steps3 = [
		InsertLicenses(source_repo, select=list(l)),
		InsertEclasses(source_repo, select=list(a)),
		CreateCategories(source_repo),
		GenUseLocalDesc()
	]
		
	if branch != 'master':
		# only generate metadata cache for prime branches
		steps3 += [ GenCache() ]

	kit.run(steps3)
	kit.gitCommit(message="updates",branch=branch)

if __name__ == "__main__":

	import sys

	if len(sys.argv) != 2 or sys.argv[1] not in [ "init", "update" ]:
		print("Please specify either 'init' for funtoo prime kits, or 'update' for updating master branches using gentoo.")
		sys.exit(1)
	elif sys.argv[1] == "init":
		kits = prime_kits
	elif sys.argv[1] == "update":
		kits = gentoo_kits

	# kitted_catpkgs will store the names of all ebuilds that were moved into kits. We want to remove these from the underlying gentoo repo.
	kitted_catpkgs = {}
	
	for kitdict in kits:
		branch = kitdict['branch']
		kname = kitdict['name']
		source = kitdict['source']

		source_repo = GitTree("ports-2012", "funtoo.org", "repos@localhost:funtoo-overlay.git", reponame="biggy", root="/var/git/dest-trees/ports-2012", pull=True)
		gentoo_staging = GitTree("gentoo-staging", "master", "repos@localhost:ports/gentoo-staging.git", root="/var/git/dest-trees/gentoo-staging", pull=False)

		if source == 'gentoo':
			src_repo = gentoo_staging
		else:
			src_repo = source_repo
		updateKit(kname, branch, src_repo, kitted_catpkgs)

	print(kitted_catpkgs.keys())

# vim: ts=4 sw=4 noet
