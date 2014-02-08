#!/usr/bin/python2

from merge_utils import *

# Progress overlay merge
if not os.path.exists("/usr/bin/svn"):
	print("svn binary not found at /usr/bin/svn. Exiting.")
	sys.exit(1)

gentoo_src = CvsTree("gentoo-x86",":pserver:anonymous@anoncvs.gentoo.org:/var/cvsroot")
funtoo_overlay = Tree("funtoo-overlay", branch, "repos@git.funtoo.org:funtoo-overlay.git", pull=True)
foo_overlay = Tree("foo-overlay", "master", "https://github.com/slashbeast/foo-overlay.git", pull=True)
bar_overlay = Tree("bar-overlay", "master", "git://github.com/adessemond/bar-overlay.git", pull=True)
squeezebox_overlay = Tree("squeezebox", "master", "git://git.overlays.gentoo.org/user/squeezebox.git", pull=True)
progress_overlay = SvnTree("progress", "https://gentoo-progress.googlecode.com/svn/overlays/progress")
sabayon_for_gentoo = Tree("sabayon-for-gentoo", "master", "git://github.com/Sabayon/for-gentoo.git", pull=True)
mate_overlay = Tree("mate", "master", "git://github.com/Sabayon/mate-overlay.git", pull=True)
funtoo_gnome_overlay = Tree("funtoo-gnome", "master", "repos@git.funtoo.org:funtoo-gnome-overlay.git", pull=True)
steps = [
	SyncTree(gentoo_src,exclude=["/metadata/cache/**","CVS", "ChangeLog", "dev-util/metro"]),
	ApplyPatchSeries("%s/funtoo/patches" % funtoo_overlay.root ),
	ThirdPartyMirrors(),
	SyncDir(funtoo_overlay.root, "profiles", "profiles", exclude=["categories", "repo_name", "updates"]),
	MergeUpdates(funtoo_overlay.root),
	ProfileDepFix(),
	SyncDir(funtoo_overlay.root,"licenses"),
	##SyncDir(funtoo_overlay.root,"eclass"),
	SyncDir(funtoo_overlay.root,"metadata"),
	SyncFiles(gentoo_src.root, {
		"profiles/package.mask":"profiles/package.mask/gentoo",
		"profiles/arch/amd64/package.use.mask":"profiles/funtoo/1.0/linux-gnu/arch/x86-64bit/package.use.mask/01-gentoo",
		"profiles/features/multilib/package.use.mask":"profiles/funtoo/1.0/linux-gnu/arch/x86-64bit/package.use.mask/02-gentoo",
		"profiles/arch/amd64/use.mask":"profiles/funtoo/1.0/linux-gnu/arch/x86-64bit/use.mask/01-gentoo",
		"profiles/arch/x86/package.use.mask":"profiles/funtoo/1.0/linux-gnu/arch/x86-32bit/package.use.mask/01-gentoo",
		"profiles/arch/x86/use.mask":"profiles/funtoo/1.0/linux-gnu/arch/x86-32bit/use.mask/01-gentoo",
		"profiles/default/linux/package.use.mask":"profiles/funtoo/1.0/linux-gnu/package.use.mask/01-gentoo",
		"profiles/default/linux/use.mask":"profiles/funtoo/1.0/linux-gnu/use.mask/01-gentoo",
		"profiles/arch/amd64/no-multilib/package.use.mask":"profiles/funtoo/1.0/linux-gnu/arch/pure64/package.use.mask/01-gentoo",
		"profiles/arch/amd64/no-multilib/package.mask":"profiles/funtoo/1.0/linux-gnu/arch/pure64/package.mask/01-gentoo",
		"profiles/arch/amd64/no-multilib/use.mask":"profiles/funtoo/1.0/linux-gnu/arch/pure64/use.mask/01-gentoo"
	}),
	InsertEbuilds(funtoo_overlay, select="all", skip=None, replace=True),
	InsertEbuilds(foo_overlay, select="all", skip=["sys-fs/mdev-bb", "sys-fs/mdev-like-a-boss", "media-video/handbrake"], replace=["app-shells/rssh","net-misc/unison"]),
	InsertEbuilds(bar_overlay, select="all", skip=["app-emulation/qemu"], replace=False),
	InsertEbuilds(mate_overlay, select="all", skip=None, replace=False),
	InsertEbuilds(squeezebox_overlay, select="all", skip=None, replace=False),
	InsertEbuilds(funtoo_gnome_overlay, select="all", skip=None, replace=True),
	SyncFiles(funtoo_gnome_overlay.root, {
		"profiles/packages.mask/funtoo-gnome3.8":"profiles/funtoo/1.0/linux-gnu/mix-ins/gnome/package.mask/01-gnome"
	}),
	SyncDir(mate_overlay.root, "eclass"),
	SyncDir(mate_overlay.root, "sets"),
	SyncFiles(mate_overlay.root, { 
		"profiles/package.mask":"profiles/funtoo/1.0/linux-gnu/mix-ins/mate/package.mask/01-mate",
		"profiles/package.use.mask":"profiles/funtoo/1.0/linux-gnu/mix-ins/mate/package.use.mask/01-mate"
	}),
	InsertEbuilds(sabayon_for_gentoo, select=["app-admin/equo", "app-admin/matter", "sys-apps/entropy", "sys-apps/entropy-server", "sys-apps/entropy-client-services","app-admin/rigo", "sys-apps/rigo-daemon", "sys-apps/magneto-core", "x11-misc/magneto-gtk", "x11-misc/magneto-gtk3", "kde-misc/magneto-kde", "app-misc/magneto-loader"], replace=True),
	SyncDir(progress_overlay.root, "eclass"),
	SyncDir(progress_overlay.root, "profiles/unpack_dependencies"),
	SyncFiles(progress_overlay.root, {
		"profiles/package.mask":"profiles/package.mask/progress",
		"profiles/use.aliases":"profiles/use.aliases/progress",
		"profiles/use.mask":"profiles/use.mask/progress"
	}),
	InsertEbuilds(progress_overlay, select="all", skip=["dev-python/pysqlite"], replace=True, merge=["dev-java/guava", "dev-lang/python", "dev-python/psycopg", "dev-python/python-docs", "dev-python/simpletal", "dev-python/wxpython", "dev-util/gdbus-codegen", "x11-libs/vte"]),
	MergeUpdates(progress_overlay.root),
	AutoGlobMask("dev-lang/python", "python*_pre*", "funtoo-python"),
	Minify(),
	GenCache(),
	GenUseLocalDesc()
]

# work tree is a non-git tree in tmpfs for enhanced performance - we do all the heavy lifting there:

work = UnifiedTree("/var/work/merge-%s" % os.path.basename(dest[0]),steps)
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
