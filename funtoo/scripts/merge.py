#!/usr/bin/python3

from merge_utils import *

# Progress overlay merge
if not os.path.exists("/usr/bin/svn"):
	print("svn binary not found at /usr/bin/svn. Exiting.")
	sys.exit(1)

gentoo_use_rsync = False
if gentoo_use_rsync:
	gentoo_src = RsyncTree("gentoo")
else:
	gentoo_src = CvsTree("gentoo-x86",":pserver:anonymous@anoncvs.gentoo.org:/var/cvsroot")
	gentoo_glsa = CvsTree("gentoo-glsa",":pserver:anonymous@anoncvs.gentoo.org:/var/cvsroot", path="gentoo/xml/htdocs/security")
funtoo_overlay = Tree("funtoo-overlay", branch, "repos@git.funtoo.org:funtoo-overlay.git", pull=True)
foo_overlay = Tree("foo-overlay", "master", "https://github.com/slashbeast/foo-overlay.git", pull=True)
bar_overlay = Tree("bar-overlay", "master", "git://github.com/adessemond/bar-overlay.git", pull=True)
bliss_overlay = Tree("bliss-overlay", "master", "https://github.com/fearedbliss/bliss-overlay.git", pull=True)
squeezebox_overlay = Tree("squeezebox", "master", "git://git.overlays.gentoo.org/user/squeezebox.git", pull=True)
progress_overlay = SvnTree("progress", "https://gentoo-progress.googlecode.com/svn/overlays/progress")
plex_overlay = Tree("funtoo-plex", "master", "https://github.com/Ghent/funtoo-plex.git", pull=True)
sabayon_for_gentoo = Tree("sabayon-for-gentoo", "master", "git://github.com/Sabayon/for-gentoo.git", pull=True)
#funtoo_gnome_overlay = Tree("funtoo-gnome", "experimental" if experimental else "master", "repos@git.funtoo.org:funtoo-gnome-overlay.git", pull=True)
funtoo_gnome_overlay = Tree("funtoo-gnome", "master", "repos@git.funtoo.org:funtoo-gnome-overlay.git", pull=True)
funtoo_toolchain_overlay = Tree("funtoo-toolchain", "master", "repos@git.funtoo.org:funtoo-toolchain-overlay.git", pull=True)
mysql_overlay = Tree("funtoo-mysql", "master", "repos@git.funtoo.org:funtoo-mysql.git", pull=True)
ldap_overlay = Tree("funtoo-ldap", "master", "repos@git.funtoo.org:funtoo-ldap-overlay.git", pull=True)
funtoo_deadbeef = Tree("funtoo-deadbeef", "master", "https://github.com/damex/funtoo-deadbeef.git", pull=True)
funtoo_redhat = Tree("funtoo-redhat", "master", "https://github.com/damex/funtoo-redhat.git", pull=True)
funtoo_wmfs = Tree("funtoo-wmfs", "master", "https://github.com/damex/funtoo-wmfs.git", pull=True)
faustoo_overlay = Tree("faustoo", "master", "https://github.com/fmoro/faustoo.git", pull=True)

steps = [
	SyncTree(gentoo_src, exclude=["/metadata/cache/**", "ChangeLog", "dev-util/metro", "profiles/base/package.use.stable.mask"]),
	# Only include 2012 and up GLSA's:
	SyncDir(gentoo_glsa.root, "en/glsa", "metadata/glsa", exclude=["glsa-200*.xml","glsa-2010*.xml", "glsa-2011*.xml"]) if not gentoo_use_rsync else None,
	ApplyPatchSeries("%s/funtoo/patches" % funtoo_overlay.root ),
	ThirdPartyMirrors(),
	SyncDir(funtoo_overlay.root, "profiles", "profiles", exclude=["categories", "repo_name", "updates"]),
	MergeUpdates(funtoo_overlay.root),
	ProfileDepFix(),
	SyncDir(funtoo_overlay.root,"licenses"),
	SyncDir(funtoo_gnome_overlay.root,"eclass"),
	SyncDir(funtoo_overlay.root,"metadata"),
	SyncFiles(gentoo_src.root, {
		"profiles/package.mask":"profiles/package.mask/00-gentoo",
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
	SyncFiles(funtoo_overlay.root, {
		"COPYRIGHT.txt":"COPYRIGHT.txt",
		"LICENSE.txt":"LICENSE.txt",
		"README.rst":"README.rst"
	}),
	InsertEbuilds(funtoo_overlay, select="all", skip=None, replace=True),
        InsertEbuilds(funtoo_toolchain_overlay, select="all", skip=None, replace=True) if experimental else None,
        InsertEbuilds(mysql_overlay, select="all", skip=None, replace=True),
        InsertEbuilds(ldap_overlay, select="all", skip=None, replace=True),
        InsertEbuilds(faustoo_overlay, select=[ "app-office/projectlibre-bin" ], skip=None, replace=True),
	InsertEbuilds(foo_overlay, select="all", skip=["sys-fs/mdev-bb", "sys-fs/mdev-like-a-boss", "media-sound/deadbeef", "media-video/handbrake"], replace=["app-shells/rssh","net-misc/unison"]),
	InsertEbuilds(bar_overlay, select="all", skip=["app-emulation/qemu"], replace=False),
        InsertEbuilds(bliss_overlay, select="all", skip=None, replace=False),
        InsertEbuilds(plex_overlay, select = [ "media-tv/plex-media-server" ], skip=None, replace=True),
        SyncDir(plex_overlay.root,"licenses"),
	InsertEbuilds(squeezebox_overlay, select="all", skip=None, replace=False),
	InsertEbuilds(funtoo_gnome_overlay, select="all", skip=None, replace=True, merge=False),
        InsertEbuilds(funtoo_deadbeef, select="all", skip=None, replace=False),
        SyncFiles(funtoo_deadbeef.root, {
                "profiles/package.mask":"profiles/package.mask/deadbeef-mask"
        }),
        SyncDir(funtoo_deadbeef.root,"eclass"),
        InsertEbuilds(funtoo_redhat, select="all", skip=None, replace=False),
        InsertEbuilds(funtoo_wmfs, select="all", skip=None, replace=False),
        SyncFiles(funtoo_wmfs.root, {
                "profiles/package.mask":"profiles/package.mask/wmfs-mask"
        }),
	SyncFiles(funtoo_gnome_overlay.root, {
		"profiles/package.mask":"profiles/funtoo/1.0/linux-gnu/mix-ins/gnome/package.mask"
	}),
        SyncFiles(mysql_overlay.root, {
                "profiles/package.mask":"profiles/package.mask/mysql",
                "profiles/package.use.mask":"profiles/package.use.mask/mysql"
        }),
        SyncDir(mysql_overlay.root, "eclass"),
	InsertEbuilds(sabayon_for_gentoo, select=["app-admin/equo", "app-admin/matter", "sys-apps/entropy", "sys-apps/entropy-server", "sys-apps/entropy-client-services","app-admin/rigo", "sys-apps/rigo-daemon", "sys-apps/magneto-core", "x11-misc/magneto-gtk", "x11-misc/magneto-gtk3", "kde-misc/magneto-kde", "app-misc/magneto-loader"], replace=True),
	SyncDir(progress_overlay.root, "eclass"),
	SyncDir(progress_overlay.root, "profiles/unpack_dependencies"),
	SyncFiles(progress_overlay.root, {
		"profiles/package.mask":"profiles/package.mask/progress",
		"profiles/use.aliases":"profiles/use.aliases/progress",
		"profiles/use.mask":"profiles/use.mask/progress"
	}),
	InsertEbuilds(progress_overlay, select="all", skip=None, replace=True, merge=["dev-python/psycopg", "dev-python/python-docs", "dev-python/simpletal", "dev-python/wxpython", "x11-libs/vte"]),
	MergeUpdates(progress_overlay.root),
	AutoGlobMask("dev-lang/python", "python*_pre*", "funtoo-python"),
	Minify(),
	GenCache(),
	GenUseLocalDesc()
]

steps = [step for step in steps if step is not None]

# work tree is a non-git tree in tmpfs for enhanced performance - we do all the heavy lifting there:
xml_out = etree.Element("packages")
work = UnifiedTree("/var/work/merge-%s" % os.path.basename(dest[0]),steps, xml_out=xml_out)
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

if experimental:
    a=open("/home/ports/public_html/experimental-packages.xml","wb")
else:
    a=open("/home/ports/public_html/packages.xml","wb")
etree.ElementTree(xml_out).write(a, encoding='utf-8', xml_declaration=True, pretty_print=True)
a.close()
