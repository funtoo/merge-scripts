#!/usr/bin/python2

from merge_utils import *

gentoo_src = Tree("gentoo","gentoo.org", "git://github.com/funtoo/portage.git", pull=True, trylocal="/var/git/portage-gentoo")
funtoo_overlay = Tree("funtoo-overlay", branch, "git://github.com/funtoo/funtoo-overlay.git", pull=True)
foo_overlay = Tree("foo-overlay", "master", "https://github.com/slashbeast/foo-overlay.git", pull=True)
bar_overlay = Tree("bar-overlay", "master", "git://github.com/adessemond/bar-overlay.git", pull=True)
flora_overlay = Tree("flora", "master", "https://github.com/funtoo/flora.git", pull=True)

for test in [ dest ]:
	if not os.path.isdir(test):
		os.makedirs(test)
	if not os.path.isdir("%s/.git" % test):
		runShell("( cd %s; git init )" % test )
		runShell("echo 'created by merge.py' > %s/README" % test )
		runShell("( cd %s; git add README; git commit -a -m 'initial commit by merge.py' )" % test )
		runShell("( cd %s; git checkout -b funtoo.org; git rm -f README; git commit -a -m 'initial funtoo.org commit' )" % ( test ) )
		print("Pushing disabled automatically because repository created from scratch.")
		push = False

steps = [
	SyncTree(gentoo_src,exclude=["/metadata/cache/**","ChangeLog", "dev-util/metro"]),
	ApplyPatchSeries("%s/funtoo/patches" % funtoo_overlay.root ),
	ThirdPartyMirrors(),
	SyncDir(funtoo_overlay.root,"profiles","profiles", exclude=["repo_name","categories"]),
	ProfileDepFix(),
	SyncDir(funtoo_overlay.root,"licenses"),
	SyncDir(funtoo_overlay.root,"eclass"),
	SyncDir(funtoo_overlay.root,"metadata"),
	InsertEbuilds(funtoo_overlay, select="all", skip=None, replace=True),
	InsertEbuilds(foo_overlay, select="all", skip=None, replace=["app-shells/rssh","net-misc/unison"]),
	InsertEbuilds(bar_overlay, select="all", skip=None, replace=True),
	InsertEbuilds(flora_overlay, select="all", skip=None, replace=False),
	Minify(),
	GenCache()
]

# work tree is a non-git tree in tmpfs for enhanced performance - we do all the heavy lifting there:

work = UnifiedTree("/var/src/merge-%s" % os.path.basename(dest),steps)
work.run()

steps = [
	GitPrep("funtoo.org"),
	SyncTree(work)
]

# then for the production tree, we rsync all changes on top of our prod git tree and commit:

prod = UnifiedTree(dest,steps)
prod.run()
prod.gitCommit(message="glorious funtoo updates",push=push)
