#!/usr/bin/python3

# TODO:
#
# recreate: unkit, core, editors, perl, python, security kits
# create: media-kit, master + 1.0-prime branch (from funtoo)
# create: core-kit, master + 1.0-prime branch (from funtoo)
# create: editors-kit, master + 1.0-prime branch (from funtoo)
# create: security-kit, master + 1.0-prime branch (from funtoo)
# create: nokit: master branch only (from funtoo)
# perl and python kits are ok. editors kit could be ok.
# mirror to github
# create master repo with github mirrors as submodules


import os
from merge_utils import *

fo_path = os.path.realpath(os.path.join(__file__,"../../../.."))

# This script will update all kits listed below and ensure that proper sets of licenses and eclasses are included in the kit.
# It will also ensure the use.local.desc and profiles/categories are generated properly.

# In theory, we should generate the prime kits only once, to initialize them:

# CONCERN: since the nokit is generated from matching catpkgs in non-prime branches (coming from Gentoo), is it possible
# that nokit could be a tiny bit out of sync from the prime repos? Ideally, should we have nokit be a copy of funtoo but
# remove all catpkgs that are in the prime kits?


prime_kits = [
	{ 'prime' : True, 'name' : 'core', 'branch' : '1.0-prime', 'source' : 'funtoo' },
	{ 'prime' : True,  'name' : 'security', 'branch' : '1.0-prime', 'source': 'funtoo' },
	{ 'prime' : True,  'name' : 'perl', 'branch' : '5.24-prime', 'source': 'funtoo' },
	{ 'prime' : True,  'name' : 'python', 'branch' : '3.4-prime', 'source': 'funtoo' },
	{ 'prime' : True,  'name' : 'editors', 'branch' : '1.0-prime', 'source': 'funtoo' },
	{ 'prime' : True,  'name' : 'xorg', 'branch' : '1.17-prime', 'source': 'funtoo', 'update' : False },
	{ 'prime' : True, 'name' : 'media', 'branch' : '1.0-prime', 'source': 'funtoo' },
]

# The non-prime branches can be updated frequently as they will pull in changes from gentoo:

gentoo_kits = [
	{ 'name' : 'core', 'branch' : 'master', 'source' : 'gentoo' },
	{ 'name' : 'security', 'branch' : 'master', 'source': 'gentoo' },
	{ 'name' : 'perl', 'branch' : 'master', 'source': 'gentoo' },
	{ 'name' : 'python', 'branch' : 'master', 'source': 'gentoo' },
	{ 'name' : 'editors', 'branch' : 'master', 'source': 'gentoo' },
	{ 'name' : 'xorg', 'branch' : 'master', 'source': 'gentoo' },
	{ 'name' : 'media', 'branch' : 'master', 'source': 'gentoo' },
]

def updateKit(mode, kit_dict, source_repo, kitted_catpkgs):
	kname = kit_dict['name']
	branch = kit_dict['branch']
	prime = kit_dict['prime'] if 'prime' in kit_dict else False
	if not prime:
		update = True
	else:
		update = kit_dict['update'] if 'update' in kit_dict else True
	kit = GitTree("%s-kit" % kname, branch, "repos@localhost:kits/%s-kit.git" % kname, root="/var/git/dest-trees/%s-kit" % kname, pull=True)

	steps = [
		GitCheckout(branch),
	]

	if update:
		steps += [ CleanTree() ]

	if kname == "core":
		# special extra steps for core-kit:
		steps += [
			GenerateRepoMetadata("core-kit", aliases=["gentoo"], priority=1000),
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
		steps += GenerateRepoMetadata("%s-kit" % kname, masters=["core-kit"], priority=500),
	
	# from here on in, kit steps should be the same for core-kit and others:

	kit.run(steps)
	if update:
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
		
	if mode == 'prime':
		# only generate metadata cache for prime branches
		steps3 += [ GenCache( cache_dir="/var/cache/git/edb-prime" ) ]

	kit.run(steps3)

	kitted_catpkgs.update(kit.getAllCatPkgs())

	kit.gitCommit(message="updates",branch=branch)

def updateNokitRepo(source_repo):

	# will copy ports-2012 but remove unkitted ebuilds

	nokit = GitTree('nokit', 'master', 'repos@localhost:kits/nokit.git', root="/var/git/dest-trees/nokit", pull=True)

	catpkgs = {} 

	for kit_dict in prime_kits:
		kname = kit_dict['name']
		branch = kit_dict['branch']
		kit = GitTree("%s-kit" % kname, branch, "repos@localhost:kits/%s-kit.git" % kname, root="/var/git/dest-trees/%s-kit" % kname, pull=True)
		catpkgs.update(kit.getAllCatPkgs())
		
	steps = [
		SyncDir(source_repo.root),
		GenerateRepoMetadata("nokit", masters=["core-kit"], priority=-2000),
		RemoveFiles(list(catpkgs.keys())),
		CreateCategories(source_repo),
		GenUseLocalDesc(),
		GenCache( cache_dir="/var/cache/git/edb-prime" )
	]

	nokit.run(steps)
	nokit.gitCommit(message="updates",branch="master")

if __name__ == "__main__":

	import sys

	if len(sys.argv) != 2 or sys.argv[1] not in [ "prime", "update" ]:
		print("Please specify either 'prime' for funtoo prime kits, or 'update' for updating master branches using gentoo.")
		sys.exit(1)
	elif sys.argv[1] == "prime":
		kits = prime_kits
	elif sys.argv[1] == "update":
		kits = gentoo_kits

	# kitted_catpkgs will store the names of all ebuilds that were moved into kits. We want to remove these from the underlying gentoo repo.
	kitted_catpkgs = {}
	
	for kitdict in kits:
		source_repo = GitTree("ports-2012", "funtoo.org", "repos@localhost:funtoo-overlay.git", reponame="biggy", root="/var/git/dest-trees/ports-2012", pull=True)
		gentoo_staging = GitTree("gentoo-staging", "master", "repos@localhost:ports/gentoo-staging.git", root="/var/git/dest-trees/gentoo-staging", pull=False)

		if kitdict['source'] == 'gentoo':
			src_repo = gentoo_staging
		else:
			src_repo = source_repo
		updateKit(sys.argv[1], kitdict, src_repo, kitted_catpkgs)

	if sys.argv[1] == "update":

		updateNokitRepo(source_repo)
		k = sorted(kitted_catpkgs.keys())
		with open("kitted_catpkgs.txt", "w") as a:
			for ki in k:
				a.write(ki+"\n")

# vim: ts=4 sw=4 noet
