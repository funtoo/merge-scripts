#!/usr/bin/python3

import os
from merge_utils import *

fo_path = os.path.realpath(os.path.join(__file__,"../../../.."))

init_kits = [
	{ 'name' : 'gnome', 'branch' : 'master', 'source': 'gentoo', 'src_branch' : '44677858bd088805aa59fd56610ea4fb703a2fcd' },
]

# KIT DESIGN AND DEVELOPER DOCS

# The maintainable model for kits is to have a 'fixups' repository that contains our changes. Then, this file is used to
# automatically generate the kits. Rather than commit directly to the kits, we just maintain fix-ups and this file's meta-
# data.

# We record the source sha1 for creating the fixup from Gentoo. Kit generation should be automated. We simply maintain thei
# fix-ups and the source sha1's from gentoo for each branch, and then can have this script regenerate the branches with the
# latest fix-ups. That way, we don't get our changes mixed up with Gentoo's ebuilds.

# A kit is generated from:

# 1. a list of ebuilds, eclasses, licenses to select
# 2. a source repository and SHA1 (we want to map to Gentoo's gentoo-staging repo)
# 3. a collection of fix-ups (from a fix-up repository) that are applied on top (generally, we will replace catpkgs underneath)

# Below, the kits and branches should be defined in a way that includes all this information. It is also possible to
# have a kit that simply is a collection of ebuilds but tracks the latest gentoo-staging. It may or may not have additional
# fix-ups.

# Kits have benefits over shards, in that because they exist on the user's system, they can control which branch they are running
# for each kit. And the goal of the kits is to have a very well-curated selection of relevant packages. At first, we may just
# have a few kits that are carefully selected, and we may have larger collections that we create just to get the curation process
# started. Examples below are text-kit and net-kit, which are very large groups of ebuilds.

# When setting up a kit repository, the 'master' branch is used to store an 'unfrozen' kit that just tracks upstream
# Gentoo. Kits are not required to have a master branch -- we only create one if the kit is designed to offer unfrozen
# ebuilds to Funtoo users.  Examples below are: science-kit, games-kit, text-kit, net-kit.

# If we have a frozen enterprise branch that we are backporting security fixes to only, we want this to be an
# 'x.y-prime' branch. This branch's source sha1 isn't supposed to change and we will just augment it with fix-ups as
# needed.

# THE CODE BELOW CURRENTLY DOESN'T WORK AS DESCRIBED ABOVE! BUT I WANTED TO DOCUMENT THE PLAN FIRST. CODE BELOW NEEDS
# UPDATES TO IMPLEMENT THE DESIGN DEFINED ABOVE.

prime_kits = [
	# true prime kits:
	{ 'prime' : True, 'name' : 'core', 'branch' : '1.0-prime', 'source' : 'funtoo' },
	{ 'prime' : True,  'name' : 'security', 'branch' : '1.0-prime', 'source': 'funtoo' },
	{ 'prime' : True,  'name' : 'perl', 'branch' : '5.24-prime', 'source': 'funtoo' },
	{ 'prime' : True,  'name' : 'python', 'branch' : '3.4-prime', 'source': 'funtoo' },
	# TODO: dev, tcltk, ruby....
	# not necessarily a 'prime' kit -- this could be a master branch only:
	{ 'prime' : True,  'name' : 'editors', 'branch' : '1.0-prime', 'source': 'funtoo' },
	# really prime:
	{ 'prime' : True,  'name' : 'xorg', 'branch' : '1.17-prime', 'source': 'funtoo', 'update' : False },
	{ 'prime' : True, 'name' : 'gnome', 'branch' : '3.20-prime', 'source': 'funtoo', 'update' : False },
	# here because it needs to be:
	{ 'prime' : True, 'name' : 'media', 'branch' : '1.0-prime', 'source': 'funtoo' },
	# these are just groupings right now:
	{ 'prime' : True, 'name' : 'text', 'branch' : 'master', 'source': 'gentoo' },
	{ 'prime' : True, 'name' : 'net', 'branch' : 'master', 'source': 'gentoo' },
	{ 'prime' : True, 'name' : 'science', 'branch' : 'master', 'source': 'gentoo' },
	{ 'prime' : True, 'name' : 'games', 'branch' : 'master', 'source': 'gentoo' },
]

# The non-prime branches can be updated frequently as they will pull in changes from gentoo:
# not sure if I want this....

gentoo_kits = [
	{ 'name' : 'core', 'branch' : 'master', 'source' : 'gentoo' },
	{ 'name' : 'security', 'branch' : 'master', 'source': 'gentoo' },
	{ 'name' : 'perl', 'branch' : 'master', 'source': 'gentoo' },
	{ 'name' : 'python', 'branch' : 'master', 'source': 'gentoo' },
	{ 'name' : 'editors', 'branch' : 'master', 'source': 'gentoo' },
	{ 'name' : 'xorg', 'branch' : 'master', 'source': 'gentoo' },
	{ 'name' : 'media', 'branch' : 'master', 'source': 'gentoo' },
	{ 'name' : 'gnome', 'branch' : 'master', 'source': 'gentoo' },
]

def auditKit(kit_dict, source_repo, kitted_catpkgs):
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

	kit.run(steps)

	actual_catpkgs = set(kit.getAllCatPkgs().keys())
	select_catpkgs = generateAuditSet("%s-kit" % kname, source_repo, pkgdir="/root/funtoo-overlay/funtoo/scripts", branch=branch, catpkg_dict=kitted_catpkgs)

	print("%s : catpkgs selected that are not yet in kit" % kname)
	for catpkg in list(select_catpkgs - actual_catpkgs):
		print(" " + catpkg)
	print()
	print("%s : catpkgs in kit that current do not have a match (possibly because they were pulled in by an earlier kit)" % kname)
	for catpkg in list(actual_catpkgs - select_catpkgs):
		print(" " + catpkg)
	print()


def updateKit(mode, kit_dict, source_repo, kitted_catpkgs):
	kname = kit_dict['name']
	branch = kit_dict['branch']
	prime = kit_dict['prime'] if 'prime' in kit_dict else False
	if 'src_branch' in kit_dict:
		source_repo.run([GitCheckout(kit_dict['src_branch'])])
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

	if len(sys.argv) != 2 or sys.argv[1] not in [ "prime", "update", "audit" ]:
		print("Please specify either 'prime' for funtoo prime kits, or 'update' for updating master branches using gentoo.")
		sys.exit(1)
	elif sys.argv[1] == "prime":
		kits = prime_kits
	elif sys.argv[1] == "update":
		kits = gentoo_kits
	elif sys.argv[1] == "audit":
		kits = prime_kits

	# kitted_catpkgs will store the names of all ebuilds that were moved into kits. We want to remove these from the underlying gentoo repo.
	kitted_catpkgs = {}
	
	for kitdict in kits:
		if not os.path.exists("/var/git/dest-trees/%s-kit" % kitdict['name']):
			print("%s-kit repo not found, skipping..." % kitdict['name'])
			continue
		source_repo = GitTree("ports-2012", "funtoo.org", "repos@localhost:funtoo-overlay.git", reponame="biggy", root="/var/git/dest-trees/ports-2012", pull=True)
		gentoo_staging = GitTree("gentoo-staging", "master", "repos@localhost:ports/gentoo-staging.git", root="/var/git/dest-trees/gentoo-staging", pull=False)

		if kitdict['source'] == 'gentoo':
			src_repo = gentoo_staging
		else:
			src_repo = source_repo
		if sys.argv[1] == "audit":
			auditKit(kitdict, src_repo, kitted_catpkgs)
		else:
			updateKit(sys.argv[1], kitdict, src_repo, kitted_catpkgs)

	if sys.argv[1] == "update":

		updateNokitRepo(source_repo)
		k = sorted(kitted_catpkgs.keys())
		with open("kitted_catpkgs.txt", "w") as a:
			for ki in k:
				a.write(ki+"\n")

# vim: ts=4 sw=4 noet
