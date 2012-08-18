#!/usr/bin/python2

from merge_utils import *

# Progress overlay merge
if not os.path.exists("/usr/bin/svn"):
	print("svn binary not found at /usr/bin/svn. Exiting.")
	sys.exit(1)

gentoo_src = Tree("gentoo","gentoo.org", "repos@git.funtoo.org:portage.git", pull=True, trylocal="/var/git/portage-gentoo")
funtoo_overlay = Tree("funtoo-overlay", branch, "repos@git.funtoo.org:funtoo-overlay.git", pull=True)
foo_overlay = Tree("foo-overlay", "master", "https://github.com/slashbeast/foo-overlay.git", pull=True)
bar_overlay = Tree("bar-overlay", "master", "git://github.com/adessemond/bar-overlay.git", pull=True)
flora_overlay = Tree("flora", "master", "repos@git.funtoo.org:flora.git", pull=True)
progress_overlay = SvnTree("progress", "https://gentoo-progress.googlecode.com/svn/overlays/progress")
lcdfiltering_overlay = Tree("lcd-filtering", "master", "git://gitorious.org/lcd-filtering/lcd-filtering.git", pull=True)
mythtv_overlay = VarLocTree("mythtv", "master", "git://github.com/MythTV/packaging.git", pull=True)

steps = [
	SyncTree(gentoo_src,exclude=["/metadata/cache/**","ChangeLog", "dev-util/metro"]),
	ApplyPatchSeries("%s/funtoo/patches" % funtoo_overlay.root ),
	ThirdPartyMirrors(),
	SyncDir(funtoo_overlay.root,"profiles","profiles", exclude=["repo_name","categories"]),
	ProfileDepFix(),
	SyncDir(funtoo_overlay.root,"licenses"),
	SyncDir(funtoo_overlay.root,"eclass"),
	SyncDir(funtoo_overlay.root,"metadata"),
	SyncFiles(gentoo_src.root, {
		"profiles/arch/amd64/package.use.mask":"profiles/funtoo/1.0/linux-gnu/arch/x86-64bit/package.use.mask/01-gentoo",
		"profiles/arch/amd64/use.mask":"profiles/funtoo/1.0/linux-gnu/arch/x86-64bit/use.mask/01-gentoo",
		"profiles/arch/x86/package.use.mask":"profiles/funtoo/1.0/linux-gnu/arch/x86-32bit/package.use.mask/01-gentoo",
		"profiles/arch/x86/use.mask":"profiles/funtoo/1.0/linux-gnu/arch/x86-32bit/use.mask/01-gentoo",
		"profiles/default/linux/package.use.mask":"profiles/funtoo/1.0/linux-gnu/package.use.mask/01-gentoo"
	}),
	InsertEbuilds(funtoo_overlay, select="all", skip=None, replace=True),
	InsertEbuilds(foo_overlay, select="all", skip=None, replace=["app-shells/rssh","net-misc/unison"]),
	InsertEbuilds(bar_overlay, select="all", skip=None, replace=True),
	InsertEbuilds(flora_overlay, select="all", skip=None, replace=False),
	InsertEbuilds(lcdfiltering_overlay, select="all", skip=["app-text/poppler"], replace=True),
	InsertEbuilds(mythtv_overlay, select='all', skip=["media-tv/miro"], replace=True, ebuildloc="Gentoo"),
	SyncDir(mythtv_overlay.root, "eclass"),
	SyncDir(progress_overlay.root, "eclass"),
	SyncFiles(progress_overlay.root, {
		"profiles/package.mask":"profiles/package.mask/progress",
		"profiles/use.mask":"profiles/use.mask/progress"
	}),
	InsertEbuilds(progress_overlay, select="all", skip=None, replace=True, merge=["dev-java/guava", "dev-lang/python", "dev-libs/boost", "dev-python/psycopg", "dev-python/pysqlite", "dev-python/python-docs", "dev-python/simpletal", "dev-python/wxpython", "dev-util/gdbus-codegen", "x11-libs/vte"]),
	MergeUpdates(progress_overlay.root),
	AutoGlobMask("dev-lang/python", "python*_pre*", "funtoo-python"),
	Minify(),
	GenCache()
]

# work tree is a non-git tree in tmpfs for enhanced performance - we do all the heavy lifting there:

work = UnifiedTree("/var/src/merge-%s" % os.path.basename(dest[0]),steps)
work.run()

steps = [
	GitPrep("funtoo.org"),
	SyncTree(work)
]

# then for the production tree, we rsync all changes on top of our prod git tree and commit:

for d in dest:
	if not os.path.isdir(d):
		os.makedirs(d)
	if not os.path.isdir("%s/.git" % d):
		runShell("( cd %s; git init )" % d )
		runShell("echo 'created by merge.py' > %s/README" % d )
		runShell("( cd %s; git add README; git commit -a -m 'initial commit by merge.py' )" % d )
		runShell("( cd %s; git checkout -b funtoo.org; git rm -f README; git commit -a -m 'initial funtoo.org commit' )" % ( d ) )
		print("Pushing disabled automatically because repository created from scratch.")
		push = False
	prod = UnifiedTree(d,steps)
	prod.run()
	prod.gitCommit(message="glorious funtoo updates",push=push)
