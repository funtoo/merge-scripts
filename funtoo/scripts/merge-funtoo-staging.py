#!/usr/bin/python3

import os
import sys
from merge_utils import *

xml_out = etree.Element("packages")
funtoo_staging_w = GitTree("funtoo-staging", "master", "repos@localhost:ports/funtoo-staging.git", root="/var/git/dest-trees/funtoo-staging", pull=False, xml_out=xml_out)
#funtoo_staging_w = GitTree("funtoo-staging-unfork", "master", "repos@localhost:ports/funtoo-staging-unfork.git", root="/var/git/dest-trees/funtoo-staging-unfork", pull=False, xml_out=None)
xmlfile="/home/ports/public_html/packages.xml"

nopush=False

funtoo_overlay = GitTree("funtoo-overlay", "master", "repos@localhost:funtoo-overlay.git", pull=True)

# We treat our Gentoo staging overlay specially, so it's listed separately. This overlay contains all Gentoo
# ebuilds, in a git repository. We use a special file in the funtoo-overlay/funtoo/scripts directory (next to
# this file) to provide a SHA1 of the commit of the gentoo-staging overlay that we want to use as a basis
# for our merges. Let's grab the SHA1 hash from that file:
	
p = os.path.join(funtoo_overlay.root,"funtoo/scripts/commit-staged")
if os.path.exists(p):
	a = open(p,"r")
	commit = a.readlines()[0].strip()
	print("Using commit: %s" % commit)
else:
	commit = None
gentoo_staging_r = GitTree("gentoo-staging", "master", "repos@localhost:ports/gentoo-staging.git", commit=commit, pull=True)

# These overlays are monitored for changes -- if there are changes in these overlays, we regenerate the entire
# tree. If there aren't changes in these overlays, we don't.

shards = {
	"perl" : GitTree("gentoo-perl-shard", "7ffec93dd83b76c06a69484f2d9e6d6831790d7f", "repos@localhost:gentoo-perl-shard.git", pull=True),
	"kde" : GitTree("gentoo-kde-shard", "f2a171e0bf202dc847d2b49efe5670428cce1227", "repos@localhost:gentoo-kde-shard.git", pull=True),
	"gnome" : GitTree("gentoo-gnome-shard", "ffabb752f8f4e23a865ffe9caf72f950695e2f26", "repos@localhost:ports/gentoo-gnome-shard.git", pull=True),
	"x11" : GitTree("gentoo-x11-shard", "0d836d2feea59e99a316ef27279b2ccc968e9624", "repos@localhost:ports/gentoo-x11-shard.git", pull=True),
	"office" : GitTree("gentoo-office-shard", "e482bdff839aed9b81cd9c62ce435aa4e78c8cab", "repos@localhost:ports/gentoo-office-shard.git", pull=True),
	"core" : GitTree("gentoo-core-shard", "1e9f42c3cff40b33b447656f47626fbb1c8a5392", "repos@localhost:gentoo-core-shard.git", pull=True)
}

# perl: 7ffec93dd83b76c06a69484f2d9e6d6831790d7f (Updated 12 Jan 2017)
# kde: f2a171e0bf202dc847d2b49efe5670428cce1227 (Updated 02 Feb 2017)
# gnome: ffabb752f8f4e23a865ffe9caf72f950695e2f26 (Updated 20 Sep 2016)
# x11: 0d836d2feea59e99a316ef27279b2ccc968e9624 (Updated 13 Feb 2017)
# office: e482bdff839aed9b81cd9c62ce435aa4e78c8cab (Updated 17 Jan 2017)
# core: 1e9f42c3cff40b33b447656f47626fbb1c8a5392 (Updated 28 Jan 2017)
# funtoo-toolchain: 8dd8a081406ee499cfca0ab17d5999e59575b28 (Updated 09 Feb 2017)

funtoo_overlays = {
	"funtoo_media" : GitTree("funtoo-media", "master", "repos@localhost:funtoo-media.git", pull=True),
	"plex_overlay" : GitTree("funtoo-plex", "master", "https://github.com/Ghent/funtoo-plex.git", pull=True),
	#"gnome_fixups" : GitTree("gnome-3.16-fixups", "master", "repos@localhost:ports/gnome-3.16-fixups.git", pull=True),
	"gnome_fixups" : GitTree("gnome-3.20-fixups", "master", "repos@localhost:ports/gnome-3.20-fixups.git", pull=True),
	"funtoo_toolchain" : GitTree("funtoo-toolchain", "8dd8a081406ee499cfca0ab17d5999e59575b28e", "repos@localhost:funtoo-toolchain-overlay.git", pull=True),
	"ldap_overlay" : GitTree("funtoo-ldap", "master", "repos@localhost:funtoo-ldap-overlay.git", pull=True),
	"deadbeef_overlay" : GitTree("deadbeef-overlay", "master", "https://github.com/damex/deadbeef-overlay.git", pull=True),
	"gambas_overlay" : GitTree("gambas-overlay", "master", "https://github.com/damex/gambas-overlay.git", pull=True),
	"wmfs_overlay" : GitTree("wmfs-overlay", "master", "https://github.com/damex/wmfs-overlay.git", pull=True),
	"flora" : GitTree("flora", "master", "repos@localhost:flora.git", pull=True),
}

# These are other overlays that we merge into the Funtoo tree. However, we just pull in the most recent versions
# of these when we regenerate our tree.

other_overlays = {
	"foo_overlay" : GitTree("foo-overlay", "master", "https://github.com/slashbeast/foo-overlay.git", pull=True),
	"bar_overlay" : GitTree("bar-overlay", "master", "git://github.com/adessemond/bar-overlay.git", pull=True),
	"squeezebox_overlay" : GitTree("squeezebox", "master", "git://anongit.gentoo.org/user/squeezebox.git", pull=True),
	"pantheon_overlay" : GitTree("pantheon", "master", "https://github.com/pimvullers/elementary.git", pull=True),
	"pinsard_overlay" : GitTree("pinsard", "master", "https://github.com/apinsard/sapher-overlay.git", pull=True),
	"sabayon_for_gentoo" : GitTree("sabayon-for-gentoo", "master", "git://github.com/Sabayon/for-gentoo.git", pull=True),
	"tripsix_overlay" : GitTree("tripsix", "master", "https://github.com/666threesixes666/tripsix.git", pull=True),
	"faustoo_overlay" : GitTree("faustoo", "master", "https://github.com/fmoro/faustoo.git", pull=True),
	"wltjr_overlay" : GitTree("wltjr", "master", "https://github.com/Obsidian-StudiosInc/os-xtoo", pull=True),
	"vmware_overlay" : GitTree("vmware", "master", "git://anongit.gentoo.org/proj/vmware.git", pull=True),
	"lisp_overlay" : GitTree("lisp", "master", "git://anongit.gentoo.org/proj/lisp.git", pull=True),
	"mcelog_overlay" : GitTree("mcelog", "master", "https://github.com/benkohler/iamben-overlay.git", pull=True),
	"atom_overlay" : GitTree("atom", "master", "https://github.com/elprans/atom-overlay.git", pull=True),
}

funtoo_changes = False
if funtoo_overlay.changes:
	funtoo_changes = True
elif gentoo_staging_r.changes:
	funtoo_changes = True
else:
	for fo in funtoo_overlays:
		if funtoo_overlays[fo].changes:
			funtoo_changes = True
			break

# This next code regenerates the contents of the funtoo-staging tree. Funtoo's tree is itself composed of
# many different overlays which are merged in an automated fashion. This code does it all.

pull = True

if nopush:
	push = False
else:
	push = "master"

# base_steps define the initial steps that prepare our destination tree for writing. Checking out the correct
# branch, copying almost the full entirety of Gentoo's portage tree to our destination tree, and copying over
# funtoo overlay licenses, metadata, and also copying over GLSA's.

base_steps = [
	GitCheckout("master"),
	SyncFromTree(gentoo_staging_r, exclude=[ 
		"/metadata/cache/**",
		"ChangeLog",
		"dev-util/metro",
		"skel.ChangeLog",
	]),
]

# Steps related to generating system profiles. These can be quite order-dependent and should be handled carefully.
# Generally, the funtoo_overlay sync should be first, then the gentoo_staging_r SyncFiles, which overwrites some stub
# files in the funtoo overlay.

profile_steps = [
	SyncDir(funtoo_overlay.root, "profiles", "profiles", exclude=["categories", "updates"]),
	CopyAndRename("profiles/funtoo/1.0/linux-gnu/arch/x86-64bit/subarch", "profiles/funtoo/1.0/linux-gnu/arch/pure64/subarch", lambda x: os.path.basename(x) + "-pure64"),
	SyncFiles(gentoo_staging_r.root, {
		"profiles/package.mask":"profiles/package.mask/00-gentoo",
		"profiles/arch/amd64/package.use.mask":"profiles/funtoo/1.0/linux-gnu/arch/x86-64bit/package.use.mask/01-gentoo",
		"profiles/arch/amd64/use.mask":"profiles/funtoo/1.0/linux-gnu/arch/x86-64bit/use.mask/01-gentoo",
		"profiles/arch/x86/package.use.mask":"profiles/funtoo/1.0/linux-gnu/arch/x86-32bit/package.use.mask/01-gentoo",
		"profiles/arch/x86/use.mask":"profiles/funtoo/1.0/linux-gnu/arch/x86-32bit/use.mask/01-gentoo",
		"profiles/default/linux/package.use.mask":"profiles/funtoo/1.0/linux-gnu/package.use.mask/01-gentoo",
		"profiles/default/linux/use.mask":"profiles/funtoo/1.0/linux-gnu/use.mask/01-gentoo",
		"profiles/arch/amd64/no-multilib/package.use.mask":"profiles/funtoo/1.0/linux-gnu/arch/pure64/package.use.mask/01-gentoo",
		"profiles/arch/amd64/no-multilib/package.mask":"profiles/funtoo/1.0/linux-gnu/arch/pure64/package.mask/01-gentoo",
		"profiles/arch/amd64/no-multilib/use.mask":"profiles/funtoo/1.0/linux-gnu/arch/pure64/use.mask/01-gentoo"
	}),
	SyncFiles(funtoo_overlays["deadbeef_overlay"].root, {
		"profiles/package.mask":"profiles/package.mask/deadbeef-mask"
	}),
	SyncFiles(funtoo_overlays["wmfs_overlay"].root, {
		"profiles/package.mask":"profiles/package.mask/wmfs-mask"
	}) ]

profile_steps += [
	SyncFiles(funtoo_overlays["funtoo_toolchain"].root, {
		"profiles/package.mask/funtoo-toolchain":"profiles/funtoo/1.0/linux-gnu/build/current/package.mask/funtoo-toolchain",
	}),
	SyncFiles(funtoo_overlays["funtoo_toolchain"].root, {
		"profiles/package.mask/funtoo-toolchain":"profiles/funtoo/1.0/linux-gnu/build/stable/package.mask/funtoo-toolchain",
		"profiles/package.mask/funtoo-toolchain-experimental":"profiles/funtoo/1.0/linux-gnu/build/experimental/package.mask/funtoo-toolchain",
	}),
	RunSed(["profiles/base/make.defaults"], ["/^PYTHON_TARGETS=/d", "/^PYTHON_SINGLE_TARGET=/d"]),
]

# Steps related to copying ebuilds. Note that order can make a difference here when multiple overlays are
# providing identical catpkgs.

# Ebuild additions -- these are less-risky changes because ebuilds are only added, and not replaced.

ebuild_additions = [
	InsertEbuilds(other_overlays["bar_overlay"], select="all", skip=["app-emulation/qemu"], replace=False),
	InsertEbuilds(other_overlays["squeezebox_overlay"], select="all", skip=None, replace=False),
	InsertEbuilds(funtoo_overlays["deadbeef_overlay"], select="all", skip=None, replace=False),
	InsertEbuilds(funtoo_overlays["gambas_overlay"], select="all", skip=None, replace=False),
	InsertEbuilds(funtoo_overlays["wmfs_overlay"], select="all", skip=None, replace=False),
	InsertEbuilds(funtoo_overlays["flora"], select="all", skip=None, replace=True, merge=True),
	]

# Ebuild modifications -- these changes need to be treated more carefully as ordering can be important
# for wholesale replacing as well as merging.


ebuild_modifications = [
	InsertEbuilds(other_overlays["vmware_overlay"], select=[ "app-emulation/vmware-modules" ], skip=None, replace=True, merge=True),
	InsertEbuilds(other_overlays["pantheon_overlay"], select=[ "x11-libs/granite", "x11-libs/bamf", "x11-themes/plank-theme-pantheon", "pantheon-base/plank", "x11-wm/gala"], skip=None, replace=True, merge=True),
	InsertEbuilds(other_overlays["faustoo_overlay"], select="all", skip=None, replace=True, merge=True),
	InsertEbuilds(other_overlays["foo_overlay"], select="all", skip=["sys-fs/mdev-bb", "sys-fs/mdev-like-a-boss", "media-sound/deadbeef", "media-video/handbrake"], replace=["app-shells/rssh"]),
	InsertEbuilds(funtoo_overlays["plex_overlay"], select=[ "media-tv/plex-media-server" ], skip=None, replace=True),
	InsertEbuilds(other_overlays["sabayon_for_gentoo"], select=["app-admin/equo", "app-admin/matter", "sys-apps/entropy", "sys-apps/entropy-server", "sys-apps/entropy-client-services","app-admin/rigo", "sys-apps/rigo-daemon", "sys-apps/magneto-core", "x11-misc/magneto-gtk", "x11-misc/magneto-gtk3", "x11-themes/numix-icon-theme", "kde-misc/magneto-kde", "app-misc/magneto-loader", "media-video/kazam" ], replace=True),
	InsertEbuilds(other_overlays["tripsix_overlay"], select=["media-sound/rakarrack"], skip=None, replace=True, merge=False),
	InsertEbuilds(other_overlays["pinsard_overlay"], select=["app-portage/chuse", "app-text/zerobinpaste", "dev-python/appi", "dev-python/iwlib", "dev-python/python-sipsimple", "media-sound/pytify", "www-client/brave-bin", "x11-misc/lemonbar", "x11-wm/qtile"], skip=None, replace=True, merge=True),
	InsertEbuilds(other_overlays["wltjr_overlay"], select=["mail-filter/assp", "mail-mta/netqmail"], skip=None, replace=True, merge=False),
	InsertEbuilds(other_overlays["lisp_overlay"], select=["dev-lisp/ltk"], skip=None, replace=True, merge=False),
	InsertEbuilds(other_overlays["mcelog_overlay"], select=["app-admin/mcelog"], skip=None, replace=True, merge=True),
	InsertEbuilds(other_overlays["atom_overlay"], select=["app-editors/atom", "dev-util/electron"], skip=None, replace=True, merge=True),
]

ebuild_modifications += [
	InsertEbuilds(funtoo_overlays["funtoo_media"], select="all", skip=None, replace=True),
	InsertEbuilds(funtoo_overlays["ldap_overlay"], select="all", skip=["net-nds/openldap"], replace=True),
]

# Steps related to eclass copying:

eclass_steps = [
		SyncDir(funtoo_overlays["deadbeef_overlay"].root,"eclass"),

]

# General tree preparation steps -- finishing touches. This is where you should put steps that require all ebuilds
# from all trees to all be inserted (like AutoGlobMask calls) as well as misc. copying of files like licenses and
# updates files. It also contains misc. tweaks like mirror fixups and Portage tree minification.

treeprep_steps = [
	SyncDir(funtoo_overlays["plex_overlay"].root,"licenses"),
]

master_steps = [
	InsertEbuilds(shards["perl"], select="all", skip=None, replace=True),
	InsertEclasses(shards["perl"], select=re.compile(".*\.eclass")),
	InsertEbuilds(shards["x11"], select="all", skip=None, replace=True),
	InsertEbuilds(shards["office"], select="all", skip=None, replace=True),
	InsertEbuilds(shards["kde"], select="all", skip=None, replace=True),
	InsertEclasses(shards["kde"], select=re.compile(".*\.eclass")),
	InsertEbuilds(shards["gnome"], select="all", skip=None, replace=True),
	InsertEbuilds(funtoo_overlays["gnome_fixups"], select="all", skip=None, replace=True),
	InsertEbuilds(shards["core"], select="all", skip=None, replace=True),
	InsertEclasses(shards["core"], select=re.compile(".*\.eclass")),
	InsertEbuilds(funtoo_overlays["funtoo_toolchain"], select="all", skip=None, replace=True, merge=False),
	InsertEbuilds(funtoo_overlay, select="all", skip=None, replace=True),
	SyncDir(funtoo_overlay.root, "eclass"),
	SyncDir(funtoo_overlay.root,"licenses"),
	SyncDir(funtoo_overlay.root,"metadata"),
	SyncFiles(funtoo_overlay.root, {
		"COPYRIGHT.txt":"COPYRIGHT.txt",
		"LICENSE.txt":"LICENSE.txt",
		"README.rst":"README.rst",
		"header.txt":"header.txt",
	}),
]

treeprep_steps += [
	MergeUpdates(funtoo_overlay.root),
	AutoGlobMask("dev-lang/python", "python*_pre*", "funtoo-python_pre"),
	AutoGlobMask("media-libs/mesa", "mesa*_rc*", "funtoo-mesa_rc"),
	ThirdPartyMirrors(),
	ProfileDepFix(),
	Minify(),
	# Set name of repository as "gentoo". Unset masters.
	RunSed(["metadata/layout.conf"], ["s/^repo-name = .*/repo-name = gentoo/", "/^masters =/d"]),
	RunSed(["profiles/repo_name"], ["s/.*/gentoo/"])
]

all_steps = [ base_steps, profile_steps, ebuild_additions, eclass_steps, master_steps, ebuild_modifications, treeprep_steps ]

for step in all_steps:
	funtoo_staging_w.run(step)
funtoo_staging_w.gitCommit(message="glorious funtoo updates",branch=push)
if xmlfile:
	a=open(xmlfile,"wb")
	etree.ElementTree(xml_out).write(a, encoding='utf-8', xml_declaration=True, pretty_print=True)
	a.close()
print("merge-funtoo-staging.py completed successfully.")
sys.exit(0)

# vim: ts=4 sw=4 noet
