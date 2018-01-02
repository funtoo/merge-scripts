#!/usr/bin/python3

import glob
import itertools
import os
import shutil
import subprocess
import sys
import re
from lxml import etree
import portage
from portage.dbapi.porttree import portdbapi
from portage.dep import use_reduce, dep_getkey, flatten
from portage.exception import PortageKeyError
import grp
import pwd
import multiprocessing
from collections import defaultdict

debug = False

class MergeStep(object):
	pass

def get_pkglist(fname):
	if fname[0] == "/":
		cpkg_fn = fname
	else:
		cpkg_fn = os.path.dirname(os.path.abspath(__file__)) + "/" + fname
	if not os.path.isdir(cpkg_fn):
		# single file specified
		files = [ cpkg_fn ]
	else:
		# directory specifed -- we will grab the file contents of the dir:
		fn_list = os.listdir(cpkg_fn)
		fn_list.sort()
		files = []
		for fn in fn_list:
			files.append(cpkg_fn + "/" + fn)
	patterns = []
	for cpkg_fn in files:
		with open(cpkg_fn,"r") as cpkg:
			for line in cpkg:
				line = line.strip()
				if line == "":
					continue
				ls = line.split("#")
				if len(ls) >=2:
					line = ls[0]
				patterns.append(line)
	else:
		return patterns

def filterInCategory(pkgset, fil):
	match = set()
	nomatch = set()
	for pkg in list(pkgset):
		if pkg.startswith(fil):
			match.add(pkg)
		else:
			nomatch.add(pkg)
	return match, nomatch

def do_package_use_line(pkg, def_python, bk_python, imps):
	if def_python not in imps:
		if bk_python in imps:
			return "%s python_single_target_%s" % (pkg, bk_python)
		else:
			return "%s python_single_target_%s python_targets_%s" % (pkg, imps[0], imps[0])
	return None

class GenPythonUse(MergeStep):

	def __init__(self, py_settings, out_subpath):
		self.def_python = py_settings["primary"]
		self.bk_python = py_settings["alternate"]
		self.mask = py_settings["mask"]
		self.out_subpath = out_subpath
	
	def run(self, cur_overlay):
		cur_tree = cur_overlay.root
		try:
			with open(os.path.join(cur_tree, 'profiles/repo_name')) as f:
				cur_name = f.readline().strip()
		except FileNotFoundError:
			cur_name = cur_overlay.name
		env = os.environ.copy()
		env['PORTAGE_DEPCACHEDIR'] = '/var/cache/edb/%s-%s-meta' % ( cur_overlay.name, cur_overlay.branch )
		env['PORTAGE_REPOSITORIES'] = '''
	[DEFAULT]
	main-repo = %s

	[%s]
	location = %s
	''' % (cur_name, cur_name, cur_tree)
		p = portage.portdbapi(mysettings=portage.config(env=env,config_profile_path=''))

		pkg_use = []

		for pkg in p.cp_all():
			
			cp = portage.catsplit(pkg)
			ebs = {}
			for a in p.xmatch("match-all", pkg):
				if len(a) == 0:
					continue
				aux = p.aux_get(a, ["INHERITED"])
				eclasses=aux[0].split()
				if "python-single-r1" not in eclasses:
					continue
				else:
					px = portage.catsplit(a)
					cmd = '( eval $(cat %s/%s/%s/%s.ebuild | grep ^PYTHON_COMPAT); echo "${PYTHON_COMPAT[@]}" )' % ( cur_tree, cp[0], cp[1], px[1] )
					outp = subprocess.getstatusoutput(cmd)
					imps = outp[1].split()
					ebs[a] = imps
			if len(ebs.keys()) == 0:
				continue

			# ebs now is a dict containing catpkg -> PYTHON_COMPAT settings for each ebuild in the catpkg. We want to see if they are identical

			oldval = None

			# if split == False, then we will do one global setting for the catpkg. If split == True, we will do individual settings for each version
			# of the catpkg, since there are differences. This saves space in our python-use file while keeping everything correct.

			split = False
			for key,val in ebs.items():
				if oldval == None:
					oldval = val
				else:
					if oldval != val:
						split = True
						break

			if not split:
				pkg_use += [ do_package_use_line(pkg, self.def_python, self.bk_python, oldval) ]
			else:
				for key,val in ebs.items():
					pkg_use += [ do_package_use_line("=%s" % key, self.def_python, self.bk_python, val) ]
		outpath = cur_tree + '/profiles/' + self.out_subpath + '/package.use'
		if not os.path.exists(outpath):
			os.makedirs(outpath)
		with open(outpath + "/python-use", "w") as f:
			for l in sorted(x for x in pkg_use if x is not None):
				f.write(l + "\n")
		# for core-kit, set good defaults as well.
		if cur_name == "core-kit":
			outpath = cur_tree + '/profiles/' + self.out_subpath + '/make.defaults'
			a = open(outpath, "w")
			a.write('PYTHON_TARGETS="%s %s"\n' % ( self.def_python, self.bk_python ))
			a.write('PYTHON_SINGLE_TARGET="%s"\n' % self.def_python)
			a.close()
			if self.mask:
				outpath = cur_tree + '/profiles/' + self.out_subpath + '/package.mask/funtoo-kit-python'
				if not os.path.exists(os.path.dirname(outpath)):
					os.makedirs(os.path.dirname(outpath))
				a = open(outpath, "w")
				a.write(self.mask + "\n")
				a.close()

def getDependencies(cur_overlay, catpkgs, levels=0, cur_level=0):
	cur_tree = cur_overlay.root
	try:
		with open(os.path.join(cur_tree, 'profiles/repo_name')) as f:
			cur_name = f.readline().strip()
	except FileNotFoundError:
			cur_name = cur_overlay.name
	env = os.environ.copy()
	env['PORTAGE_REPOSITORIES'] = '''
[DEFAULT]
main-repo = %s 

[%s]
location = %s
''' % (cur_name, cur_name, cur_tree)
	p = portage.portdbapi(mysettings=portage.config(env=env,config_profile_path=''))
	mypkgs = set()
	for catpkg in list(catpkgs):
		for pkg in p.cp_list(catpkg):
			if pkg == '':
				print("No match for %s" % catpkg)
				continue
			try:
				aux = p.aux_get(pkg, ["DEPEND", "RDEPEND"])
			except PortageKeyError:
				print("Portage key error for %s" % repr(pkg))
				return mypkgs
			for dep in flatten(use_reduce(aux[0]+" "+aux[1], matchall=True)):
				if len(dep) and dep[0] == "!":
					continue
				try:
					mypkg = dep_getkey(dep)
				except portage.exception.InvalidAtom:
					continue
				if mypkg not in mypkgs:
					mypkgs.add(mypkg)
				if levels != cur_level:
					mypkgs = mypkgs.union(getDependencies(cur_overlay, mypkg, levels=levels, cur_level=cur_level+1))
	return mypkgs

def getPackagesInCatWithMaintainer(cur_overlay, my_cat, my_email):
	cat_root = os.path.join(cur_overlay.root, my_cat)
	if os.path.exists(cat_root):
		for pkgdir in os.listdir(cat_root):
			metafile = os.path.join(cat_root, pkgdir, "metadata.xml")
			if not os.path.exists(metafile):
				continue
			tree = etree.parse(metafile)
			for email in tree.xpath('.//maintainer/email/text()'):
				if my_email == str(email):
					yield my_cat + "/" + pkgdir

def getPackagesMatchingGlob(cur_overlay, my_glob):
	insert_list = []
	for candidate in glob.glob(cur_overlay.root + "/" + my_glob):
		if not os.path.isdir(candidate):
			continue
		strip_len = len(cur_overlay.root)+1
		candy_strip = candidate[strip_len:]
		insert_list.append(candy_strip)
	return insert_list

def getPackagesMatchingRegex(cur_overlay, my_regex):
	insert_list = []
	for candidate in glob.glob(cur_overlay.root + "/*/*"):
		if not os.path.isdir(candidate):
			continue
		strip_len = len(cur_overlay.root)+1
		candy_strip = candidate[strip_len:]
		if my_regex.match(candy_strip):
			insert_list.append(candy_strip)
	return insert_list

def getPackagesWithEclass(cur_overlay, eclass):
	cur_tree = cur_overlay.root
	try:
		with open(os.path.join(cur_tree, 'profiles/repo_name')) as f:
			cur_name = f.readline().strip()
	except FileNotFoundError:
			cur_name = cur_overlay.name
	env = os.environ.copy()
	env['PORTAGE_REPOSITORIES'] = '''
[DEFAULT]
main-repo = %s

[%s]
location = %s
''' % (cur_name, cur_name, cur_tree)
	p = portage.portdbapi(mysettings=portage.config(env=env, config_profile_path=''))
	p.frozen = False
	mypkgs = set()
	for catpkg in p.cp_all():
		for pkg in p.cp_list(catpkg):
			if pkg == '':
				print("No match for %s" % catpkg)
				continue
			try:
				aux = p.aux_get(pkg, ["INHERITED"])
			except PortageKeyError:
				print("Portage key error for %s" % repr(pkg))
				continue
			if eclass in aux[0].split():
				if eclass not in mypkgs:
					mypkgs.add(catpkg)
	return mypkgs

def getPackagesInCatWithEclass(cur_overlay, cat, eclass):
	cur_tree = cur_overlay.root
	try:
		with open(os.path.join(cur_tree, 'profiles/repo_name')) as f:
			cur_name = f.readline().strip()
	except FileNotFoundError:
			cur_name = cur_overlay.name
	env = os.environ.copy()
	env['PORTAGE_REPOSITORIES'] = '''
[DEFAULT]
main-repo = %s

[%s]
location = %s
''' % (cur_name, cur_name, cur_tree)
	p = portage.portdbapi(mysettings=portage.config(env=env, config_profile_path=''))
	p.frozen = False
	mypkgs = set()
	for catpkg in p.cp_all(categories=[cat]):
		for pkg in p.cp_list(catpkg):
			if pkg == '':
				print("No match for %s" % catpkg)
				continue
			try:
				aux = p.aux_get(pkg, ["INHERITED"])
			except PortageKeyError:
				print("Portage key error for %s" % repr(pkg))
				continue
			if eclass in aux[0].split():
				if eclass not in mypkgs:
					mypkgs.add(catpkg)
	return mypkgs

class CatPkgScan(MergeStep):

	def __init__(self, now, db=None):
		self.now = now
		self.db = db

	def run(self, cur_overlay):
		if self.db == None:
			return
		from db_core import Distfile, MissingManifestFailure
		session = self.db.session
		cur_tree = cur_overlay.root
		try:
			with open(os.path.join(cur_tree, 'profiles/repo_name')) as f:
				cur_name = f.readline().strip()
		except FileNotFoundError:
				cur_name = cur_overlay.name
		env = os.environ.copy()
		env['PORTAGE_REPOSITORIES'] = '''
	[DEFAULT]
	main-repo = %s

	[%s]
	location = %s
	''' % (cur_name, cur_name, cur_tree)
		env['ACCEPT_KEYWORDS'] = "~amd64 amd64"
		p = portage.portdbapi(mysettings=portage.config(env=env, config_profile_path=''))
		for pkg in p.cp_all():
			
			cp = portage.catsplit(pkg)

			src_uri = {}

			# We are scanning SRC_URI in all ebuilds in the catpkg, as well as Manifest.
			# This will give us a complete list of all archives used in the catpkg.

			mirror_restrict_set = set()

			# We want to prioritize SRC_URI for bestmatch-visible ebuilds. We will use bm
			# and prio to tag files that are in bestmatch-visible ebuilds.

			bm = p.xmatch("bestmatch-visible", pkg)

			prio = {}

			def record_src_uri(atom, uri, mirror_restrict):
				#global prev_blob, bm, src_uri, mirror_restrict_set
				if mirror_restrict:
					mirror_restrict_set.add(fn)
					if not fn in src_uri:
						src_uri[fn] = []
					if prev_blob not in src_uri[fn]:
						# avoid dups
						src_uri[fn].append(prev_blob)
				if atom in bm:
					# prioritize bestmatch-visible
					prio[fn] = 1

			for a in p.xmatch("match-all", pkg):
				if len(a) == 0:
					continue
				prev_blob = None
				pos = 0
				aux_info = p.aux_get(a, ["SRC_URI", "RESTRICT" ])
				blobs = aux_info[0].split()
				
				restrict = aux_info[1].split()
				mirror_restrict = False
				for r in restrict:
					if r == "mirror":
						mirror_restrict = True
						break

				while (pos < len(blobs)):
					blob = blobs[pos]
					if blob in [ ")", "(", "||" ] or blob.endswith("?"):
						pos += 1
						continue
					if blob == "->":
						fn = blobs[pos+1]
						record_src_uri(a, prev_blob, mirror_restrict)
						prev_blob = None
						pos += 2
					else:
						if prev_blob:
							fn = prev_blob.split("/")[-1]
							record_src_uri(a, prev_blob, mirror_restrict)
						prev_blob = blob
						pos += 1
				if prev_blob:
					fn = prev_blob.split("/")[-1]
					if mirror_restrict:
						mirror_restrict_set.add(fn)
					if not fn in src_uri:
						src_uri[fn] = []
					if prev_blob not in src_uri[fn]:
						# avoid dups
						src_uri[fn].append(prev_blob)

			# src_uri now has the following format:

			# src_uri["foo.tar.gz"] = [ "https://url1", "https//url2" ... ]
			# entries in SRC_URI from fetch-restricted ebuilds will have SRC_URI prefixed by "NOMIRROR:"

			man_info = {}
			no_sha512 = set()
			man_file = cur_tree + "/" + pkg + "/Manifest"
			if os.path.exists(man_file):
				man_f = open(man_file, "r")
				for line in man_f.readlines():
					ls = line.split()
					if len(ls) <= 3 or ls[0] != "DIST":
						continue
					try:
						sha512_index = ls.index("SHA512")
					except ValueError:
						no_sha512.add(ls[1])
						continue
					man_info[ls[1]] = { "size" : ls[2], "sha512" : ls[sha512_index+1] if sha512_index else None }
				man_f.close()

			# for each catpkg:

			for f, uris in src_uri.items():
				s_out = ""
				for u in uris:
					s_out += u + "\n"
				if f not in man_info:
					fail = MissingManifestFailure()
					fail.filename = f
					fail.catpkg = pkg
					fail.kit = cur_overlay.name
					fail.branch = cur_overlay.branch
					fail.src_uri = s_out
					fail.failtype = "nosha512" if f in no_sha512 else "missing"
					fail.fail_on = self.now
					merged_fail = session.merge(fail)
					print("BAD!!! %s in MANIFEST: " % fail.failtype, pkg, f )
					continue
				assert man_info[f]["sha512"] != None
				d = Distfile()
				d.id = man_info[f]["sha512"]
				d.filename = f 
				if f in prio:
					d.priority = prio[f]
				d.size = man_info[f]["size"]
				d.src_uri = s_out
				d.catpkg = pkg
				d.kit = cur_overlay.name
				d.last_updated_on = self.now
				d.mirror = True if f not in mirror_restrict_set else False
				merged_d = session.merge(d)

			session.commit()

def repoName(cur_overlay):
	cur_tree = cur_overlay.root
	try:
		with open(os.path.join(cur_tree, 'profiles/repo_name')) as f:
			cur_name = f.readline().strip()
	except FileNotFoundError:
			cur_name = cur_overlay.name
	return cur_name

# getAllEclasses() and getAllLicenses() uses the function getAllMeta() below to do all heavy lifting.  What getAllMeta() returns
# is a list of eclasses that are used by our kit, but this list doesn't indicate what repository holds the eclasses. 

# So we don't know if the eclass is in the dest_kit or in the parent_repo and still needs to be copied over.  as an eclass
# 'fixup'. getAllEclasses() is designed to locate the actual eclass that we care about so we know what repo it lives in and what
# steps need to be taken, if any.

# First, we will look in our dest-kit repository. If it exists there, then it was already copied into place by a kit-fixup and
# we do not want to overwrite it with another eclass! Then we will look in the parent_repo (which is designed to be 'gentoo'),
# and see if the eclass is there. We expect to find it there. If we don't, it is a MISSING eclass (or license).

# getAllEclasses and getAllLicenses return a dictionary with the following keys, and with a list of files relative to the
# repo root as the dictionary value:
#
# 'parent_repo' : list of all eclasses that should be copied from parent repo
# 'dest_kit'	: list of all eclasses that were found in our kit and don't need to be copied (they are already in place)
# None			: list of all eclasses that were NOT found. This is an error and indicates we need some kit-fixups or
#				  overlay-specific eclasses.

def _getAllDriver(metadata, path_prefix, dest_kit, parent_repo):
	# these may be eclasses or licenses -- we use the term 'eclass' here:
	eclasses = getAllMeta(metadata, dest_kit, parent_repo)
	out = { None: [], "dest_kit" : [] }
	if parent_repo != None:
		out["parent_repo"] = []
	for eclass in eclasses:
		ep = os.path.join(dest_kit.root, path_prefix, eclass)
		if os.path.exists(ep):
			out["dest_kit"].append(eclass)
			continue
		if parent_repo != None:
			ep = os.path.join(parent_repo.root, path_prefix, eclass)
			if os.path.exists(ep):
				out["parent_repo"].append(eclass)
				continue
			# not found!
		out[None].append(eclass)
	return out

def getAllEclasses(dest_kit, parent_repo=None):
	return _getAllDriver("INHERITED", "eclass", dest_kit, parent_repo)

def getAllLicenses(dest_kit, parent_repo):
	return _getAllDriver("LICENSE", "licenses", dest_kit, parent_repo)

# getAllMeta uses the Portage API to query metadata out of a set of repositories. It is designed to be used to figure
# out what licenses or eclasses to copy from a parent repository to the current kit so that the current kit contains a
# set of all eclasses (and licenses) it needs within itself, without any external dependencies on other repositories 
# for these items -- this is a key design feature of kits to improve stability.

# It supports being called this way:
#
#  (parent_repo) -- all eclasses/licenses here
#	 |
#	 |
#	 \-------------------------(dest_kit) -- no eclasses/licenses here yet
#											 (though some may exist due to being copied by fixups) 
#
#  getAllMeta() returns a set of actual files (without directories) that are used, so [ 'foo.eclass', 'bar.eclass'] 
#  or [ 'GPL-2', 'bleh' ].
#
def getAllMeta(metadata, dest_kit, parent_repo=None):
	metadict = { "LICENSE" : 0, "INHERITED" : 1 }
	metapos = metadict[metadata]
	
	env = os.environ.copy()
	
	if parent_repo != None:
		parent_name = parent_repo.reponame if parent_repo.reponame else repoName(parent_repo)
	
	env['PORTAGE_DEPCACHEDIR'] = '/var/cache/edb/%s-%s-meta' % ( dest_kit.name, dest_kit.branch )
	if parent_repo != None:
		env['PORTAGE_REPOSITORIES'] = '''
	[DEFAULT]
	main-repo = gentoo

	[gentoo]
	location = %s

	[%s]
	location = %s
	aliases = -gentoo
	masters = gentoo 
		''' % ( parent_repo.root, dest_kit.name, dest_kit.root)
	else:
		# we are testing a stand-alone kit that should have everything it needs included
		env['PORTAGE_REPOSITORIES'] = '''
	[DEFAULT]
	main-repo = gentoo

	[%s]
	location = %s
	eclass-overrides = gentoo 
	aliases = gentoo
		''' % ( dest_kit.name, dest_kit.root )
	p = portdbapi(mysettings=portage.config(env=env,config_profile_path=''))
	myeclasses = set()
	for cp in p.cp_all(trees=[dest_kit.root]):
		for cpv in p.cp_list(cp, mytree=dest_kit.root):
			try:
				aux = p.aux_get(cpv, ["LICENSE","INHERITED"], mytree=dest_kit.root)
			except PortageKeyError:
				print("Portage key error for %s" % repr(cpv))
				continue
			if metadata == "INHERITED":
				for eclass in aux[metapos].split():
					key = eclass + ".eclass"
					if key not in myeclasses:
						myeclasses.add(key)
			elif metadata == "LICENSE":
				for lic in aux[metapos].split():
					if lic in [ ")", "(", "||" ] or lic.endswith("?"):
						continue
					if lic not in myeclasses:
						myeclasses.add(lic)
	return myeclasses

def generateKitSteps(kit_name, from_tree, select_only="all", fixup_repo=None, pkgdir=None,
                     cpm_logger=None, filter_repos=None, force=None, secondary_kit=False):
	if force is None:
		force = set()
	else:
		force = set(force)
	steps = []
	pkglist = []
	pkgf = "package-sets/%s-packages" % kit_name
	pkgf_skip = "package-sets/%s-skip" % kit_name
	if pkgdir is not None:
		pkgf = pkgdir + "/" + pkgf
		pkgf_skip = pkgdir + "/" + pkgf_skip
	skip = []
	master_pkglist = get_pkglist(pkgf)
	if filter_repos is None:
		filter_repos = []
	if fixup_repo:
		master_pkglist += get_extra_catpkgs_from_kit_fixups(fixup_repo, kit_name)
	if os.path.exists(pkgf_skip):
		skip = get_pkglist(pkgf_skip)
	for pattern in master_pkglist:
		if pattern.startswith("@regex@:"):
			pkglist += getPackagesMatchingRegex( from_tree, re.compile(pattern[8:]))
		elif pattern.startswith("@depsincat@:"):
			patsplit = pattern.split(":")
			catpkg = patsplit[1]
			dep_pkglist = getDependencies( from_tree, [ catpkg ] )
			if len(patsplit) == 3:
				dep_pkglist, dep_pkglist_nomatch = filterInCategory(dep_pkglist, patsplit[2])
			pkglist += list(dep_pkglist)
		elif pattern.startswith("@maintainer@:"):
			spiff, my_cat, my_email = pattern.split(":")
			pkglist += list(getPackagesInCatWithMaintainer( from_tree, my_cat, my_email))
		elif pattern.startswith("@has_eclass@:"):
			patsplit = pattern.split(":")
			eclass = patsplit[1]
			eclass_pkglist = getPackagesWithEclass( from_tree, eclass )
			pkglist += list(eclass_pkglist)
		elif pattern.startswith("@cat_has_eclass@:"):
			patsplit = pattern.split(":")
			cat, eclass = patsplit[1:]
			cat_pkglist = getPackagesInCatWithEclass( from_tree, cat, eclass )
			pkglist += list(cat_pkglist)
		elif pattern.endswith("/*"):
			pkglist += getPackagesMatchingGlob( from_tree, pattern)
		else:
			pkglist.append(pattern)

	to_insert = set(pkglist)

	if secondary_kit is True:
		print('Secondary kit is true')
		# add in any catpkgs from previous scans of this same kit that might be missing from this scan:
		to_insert = cpm_logger.update_cached_kit_catpkg_set(to_insert)
	else:
		cpm_logger.update_cached_kit_catpkg_set(to_insert)

	# filter out anything that was not in the select_only argument list, if it was provided:
	if select_only != "all":
		p_set = set(select_only)
		to_insert = to_insert & p_set

	# filter out any catpkgs that exist in any of the filter_repos:
	new_set = set()
	for catpkg in to_insert:
		skip = False
		for filter_repo in filter_repos:
			if filter_repo.catpkg_exists(catpkg):
				if catpkg not in force:
					skip = True
					break
		if skip:
			continue
		else:
			new_set.add(catpkg)
	to_insert = new_set

	print('To-be-inserted catpkgs are', to_insert)
	insert_kwargs = {"select": sorted(list(to_insert))}

	if pkglist:
		steps += [ InsertEbuilds(from_tree, skip=skip, replace=False, cpm_logger=cpm_logger, **insert_kwargs) ]
	return steps

def get_extra_catpkgs_from_kit_fixups(fixup_repo, kit):

	"""
	This function will scan the specified kit directory in kit-fixups and look for catpkgs that are specified in some
	but not all non-global directories. This list of catpkgs should be added to the kit's package set. Otherwise, the
	catpkg will exist in some branches (the one with the fixup) but will not exist in the branches without the fixup.
	If we use this function, then we don't need to manually add these catpkgs to the package-set for the kit manually,
	which makes things less error prone for us.

	For example:

	kit-fixups/foo-kit/1.0-prime/foo/bar exists
	kit-fixups/foo-kit/1.1-prime/foo/bar does not exist.

	Without using this function to augment the package-set automatically, and without manually adding foo/bar to the
	package-set list ourselves, foo/bar will exist in 1.0-prime but will not exist in 1.1-prime. But if we scan our
	kit-fixups with this method, we will get a list back [ "foo/bar" ] and can add this to our package-set for foo-kit,
	which will cause both kits to get a copy of foo/bar. 1.0-prime will get the fixup and 1.1-prime will get a copy
	from its source repos.

	:param fixup_repo:
	:param kit:
	:return:
	"""

	root = fixup_repo.root

	def get_catpkg_list(repo_root):
		if not os.path.exists(repo_root):
			return
		for cat in os.listdir(repo_root):
			if cat in [ "profiles", "eclass", "licenses"]:
				continue
			if not os.path.isdir(repo_root + "/" + cat):
				continue
			for pkg in os.listdir(repo_root + "/" + cat):
				yield cat+"/"+pkg

	global_set = set(get_catpkg_list(root+"/"+kit+"/"+"global"))
	out = []

	try:
		non_global_kit_dirs = set(os.listdir(root+"/"+kit))
	except FileNotFoundError:
		return out

	if "global" in non_global_kit_dirs:
		non_global_kit_dirs.remove("global")
	non_global_count = len(list(non_global_kit_dirs))

	non_global_matches = defaultdict(int)

	for non_global_branch in non_global_kit_dirs:
		for catpkg in get_catpkg_list(root+"/"+kit+"/"+non_global_branch):
			non_global_matches[catpkg] += 1

	for catpkg, count in non_global_matches.items():
		if count < non_global_count and catpkg not in global_set:
			out.append(catpkg)

	return out


# CatPkgMatchLogger is an object that is used to keep a running record of catpkgs that were copied to kits via package-set rules.
# As catpkgs are called, a CatPkgMatchLogger() object is called as follows:
#
# logger.record("sys-foo/bar")					# catpkg foo/bar was merged.
# logger.record(regex("sys-bar/*"))				# a "sys-bar/*" was specified in the package set.
#
# Then, prior to copying a catpkg to a kit, we can check to see if maybe this catpkg was already copied to another kit. If so, we
# should not copy it to a new kit which would cause a duplicate catpkg to exist between two kits. The "should we copy this catpkg"
# question is answered by calling the match() method, as follows:
#
# logger.match("sys-foo/bar")	: True --	this matches a previously copied catpkg atom, so don't copy it to the kit.
# logger.match("sys-foo/oni")	: False --	we have no record of this catpkg being copied, so it's safe to copy.
# logger.match("sys-bar/bleh")	: True --	this catpkg matches a wildcard regex that was used previously, so don't copy.
#
# The support for regex matches fixes a kit problem called "kit overflow". Here's an example of kit overflow. Let's say
# we have a snapshot of our python-kit, but since our snapshot, many dev-python catpkgs have been added. Without regex support
# in CatPkgMatchLogger, these new catpkgs will "overflow" to nokit. When we eventually bump our python-kit to a newer snapshot
# and these newer catpkgs start to appear in python-kit instead of our unsnapshotted nokit, this will result in dev-python
# downgrades.
#
# To work around this, when we encounter a pattern or regex like "dev-python/*", we record a regex in CatPkgMatchLogger. If the
# catpkg we are considering copying WOULD have matched a previously-used pattern, we can know that it should NOT be copied to
# nokit. If we were to just track literal catpkgs and not regexes, then the overflow to nokit would occur.

class CatPkgMatchLogger(object):

	def __init__(self, log_xml=False):
		self._copycount = 0
		self._matchcount = 0
		# for string matches
		self._matchdict = {}
		self._current_kit_set = set()

		# for fixups from a non-global directory, we want the match to only apply for a particular branch. This way
		# If xorg-kit/1.17-prime/foo/bar gets copied, we don't also need to have an xorg-kit/1.19-prime/foo/bar --
		# the code will be smart and know that for the 1.19-prime branch, we still want to copy over foo/bar when we
		# encounter it.

		# format: 'catpkg-match' : { 'kit' : [ 'branch1', 'branch2' ] }
		#
		# ^^^ This means that 'catpkg-match' was copied into branch1 and branch2 of kit 'kit'. So we want to ALLOW
		# a copy into branch3 of kit, but NOT ALLOW a copy into any successive kit (since it was already copied.)

		self._fixup_matchdict = defaultdict(dict)
		self._matchdict_curkit = {}
		# for regex matches
		self._regexdict = {}
		self._regexdict_curkit = {}

		if log_xml:
			self.xml_recorder = XMLRecorder()
		else:
			self.xml_recorder = None

		# IMPORTANT:

		# We don't want to match regexes against catpkgs in the CURRENT KIT. Otherwise we will only copy the first match
		# of a regex! Here is why -- the first ebuild that matches the regex will get copied, and we will record the regex.
		# Then the second and successive catpkg matches will also match the regex, so .match() will return True and we will
		# skip them, thinking that they are already copied.

		# We work around this by caching the regexes and only start applying them after the caller calls .nextKit(). Then they
		# become active.

		# NOTE: Since a kit pulls from multiple repos, this does raise the possibility of repo b replacing a catpkg that was
		# already copied. We work around this by always using replace=False with InsertEbuilds -- so that if the catpkg is already
		# on disk, then it isn't copied, even if it matches a regex.

		# NOTE that we now also cache non-regex matches too. This allows us to process two xorg-kits or python-kits in a row.
		# matches will accumulate but not take effect until .nextKit() is called.

	# Another feature of the CatPkgMatchLoggger is that it records how many catpkgs actually were copied -- 1 for each catpkg
	# literal, and a caller-specified number of matches for regexes. This tally is used by merge-all-kits.py to determine the
	# total number of catpkgs copied to each kit.

	def writeXML(self):
		if self.xml_recorder:
			self.xml_recorder.write("/home/ports/packages.xml")

	def recordCopyToXML(self, srctree, kit, catpkg):
		if self.xml_recorder:
			self.xml_recorder.xml_record(srctree, kit, catpkg)

	@property
	def copycount(self):
		return self._copycount

	@property
	def matchcount(self):
		return self._matchcount

	def match(self, catpkg, kit=None, branch=None, is_fixup=False):
		"""
		This method tells us whether we should copy over a catpkg to a particular kit.
		:param catpkg: the catpkg in question.
		:param kit: The kit name being processed.
		:param branch: The branch of the kit being processed..
		:param is_fixup: True if we are performing a fixup, else False.
		:return: Boolean, True if we have already copied and should not copy again, and False if we have not seen and
		         should copy..
		"""

		if catpkg in self._matchdict:
			# Yes, we've seen it, just as a regular package copied before (non-fixup), so don't copy
			return True

		for pat, regex in self._regexdict.items():
			if regex.match(catpkg):
				# Seen and likely copied before, don't copy
				return True
		# We've passed all tests -- copy this sucker!
		return False

	def update_cached_kit_catpkg_set(self, myset):
		# this is used by the intra-kit logic that identifies catpkgs selected from prior runs of the same kit that
		# don't exist in the current kit selection. We want to grab these stragglers.

		self._current_kit_set |= myset
		return self._current_kit_set

	def record(self, match, kit=None, branch=None, is_fixup=False):
		"""
		This method records catpkgs that we are copying over, so we can determine whether or not the catpkg should be
		copied again into later kits. In general, we only want to copy a catpkg once -- but there are exceptions, like
		if we have different branches of the same kit, or if we have fixups. So the logic is nuanced.

		:param match: Either a catpkg string or regex match.
		:param kit:  The kit that we are processing.
		:param branch: This is the kit branch name we are processing.
		:param is_fixup: True if we are applying a fixup; else False.
		:return: None
		"""
		if isinstance(match, regextype):
			if is_fixup:
				raise IndexError("Can't use regex with fixup")
			self._regexdict_curkit[match.pattern] = match
		else:
			# otherwise, record in our regular matchdict
			self._matchdict_curkit[match] = True
		self._copycount += 1

	def nextKit(self):
		self._regexdict.update(self._regexdict_curkit)
		self._regexdict_curkit = {}
		self._matchdict.update(self._matchdict_curkit)
		self._matchdict_curkit = {}
		self._current_kit_set = set()

def headSHA1(tree):
	retval, out = subprocess.getstatusoutput("(cd %s && git rev-parse HEAD)" % tree)
	if retval == 0:
		return out.strip()
	return None

def runShell(string,abortOnFail=True):
	if debug:
		print("running: %r" % string)
	out = subprocess.getstatusoutput(string)
	if out[0] != 0:
		print("Error executing %r" % string)
		print()
		print("output:")
		print(out[1])
		if abortOnFail:
			sys.exit(1)
		else:
			return False
	return True

def run_command(args, *, abort_on_failure=True, **kwargs):
	if debug:
		print("running: %r" % args)
	stdout = kwargs.pop("stdout", subprocess.PIPE)
	stderr = kwargs.pop("stderr", subprocess.PIPE)
	try:
		with subprocess.Popen(args, stdout=stdout, stderr=stderr, **kwargs) as process:
			status = process.wait()
			stdout_content = process.stdout.read().decode()
			stderr_content = process.stderr.read().decode()
	except OSError as e:
		status = -1
		stdout_content = ""
		stderr_content = e.strerror
	if status != 0:
		print("Error executing %r" % args)
		print()
		print("stdout: %s" % stdout_content)
		print("stderr: %s" % stderr_content)
		if abort_on_failure:
			sys.exit(1)
		else:
			return False
	return True

class AutoGlobMask(MergeStep):

	"""
	AutoGlobMask will automatically create a package.mask file that matches particular
	ebuilds that it finds in the tree.

	catpkg: The catpkg to process. AutoGlobMask will look into the destination tree in
	this catpkg directory.

	glob: the wildcard pattern of an ebuild files to match in the catpkg directory.

	maskdest: The filename of the mask file to create in profiles/packages.mask.

	All ebuilds matching glob in the catpkg dir will have mask entries created and
	written to profiles/package.mask/maskdest.

	"""

	def __init__(self,catpkg,glob,maskdest):
		self.glob = glob
		self.catpkg = catpkg
		self.maskdest = maskdest

	def run(self,tree):
		if not os.path.exists(tree.root + "/profiles/package.mask"):
			os.makedirs(tree.root + "/profiles/package.mask")
		f = open(os.path.join(tree.root,"profiles/package.mask", self.maskdest), "w")
		#os.chdir(os.path.join(tree.root,self.catpkg))
		cat = self.catpkg.split("/")[0]
		for item in glob.glob(os.path.join(tree.root,self.catpkg) + "/" + self.glob+".ebuild"):
			s_split = item.split("/")
			f.write("=%s/%s\n" % (cat,"/".join(s_split[-2:])[:-7]))
		f.close()

class ThirdPartyMirrors(MergeStep):
	"Add funtoo's distfiles mirror, and add funtoo's mirrors as gentoo back-ups."

	def run(self,tree):
		orig = "%s/profiles/thirdpartymirrors" % tree.root
		new = "%s/profiles/thirdpartymirrors.new" % tree.root
		mirrors = "http://build.funtoo.org/distfiles http://ftp.osuosl.org/pub/funtoo/distfiles"
		a = open(orig, "r")
		b = open(new, "w")
		for line in a:
			ls = line.split()
			if len(ls) and ls[0] == "gentoo":

				# Add funtoo mirrors as second and third Gentoo mirrors. So, try the main gentoo mirror first.
				# If not there, maybe we forked it and the sources are removed from Gentoo's mirrors, so try
				# ours. This allows us to easily fix mirroring issues for users.

				b.write("gentoo\t"+ls[1]+" "+mirrors+" "+" ".join(ls[2:])+"\n")
			else:
				b.write(line)
		b.write("funtoo %s\n" % mirrors)
		a.close()
		b.close()
		os.unlink(orig)
		os.link(new, orig)
		os.unlink(new)

class ApplyPatchSeries(MergeStep):
	def __init__(self,path):
		self.path = path

	def run(self,tree):
		a = open(os.path.join(self.path,"series"),"r")
		for line in a:
			if line[0:1] == "#":
				continue
			if line[0:4] == "EXEC":
				ls = line.split()
				runShell( "( cd %s && %s/%s )" % ( tree.root, self.path, ls[1] ))
			else:
				runShell( "( cd %s && git apply %s/%s )" % ( tree.root, self.path, line[:-1] ))

class GenerateRepoMetadata(MergeStep):
	def __init__(self, name, masters=[], aliases=[], priority=None):
		self.name = name
		self.aliases = aliases
		self.masters = masters
		self.priority = priority

	def run(self,tree):
		meta_path = os.path.join(tree.root, "metadata")
		if not os.path.exists(meta_path):
			os.makedirs(meta_path)
		a = open(meta_path + '/layout.conf','w')
		out = '''repo-name = %s
thin-manifests = true
sign-manifests = false
profile-formats = portage-2
cache-formats = md5-dict
''' % self.name
		if self.aliases:
			out += "aliases = %s\n" % " ".join(self.aliases)
		if self.masters:
			out += "masters = %s\n" % " ".join(self.masters)
		a.write(out)
		a.close()
		rn_path = os.path.join(tree.root, "profiles")
		if not os.path.exists(rn_path):
			os.makedirs(rn_path)
		a = open(rn_path + '/repo_name', 'w')
		a.write(self.name + "\n")
		a.close() 

class RemoveFiles(MergeStep):
	def __init__(self,globs=[]):
		self.globs = globs
	
	def run(self,tree):
		for glob in self.globs:
			cmd = "rm -rf %s/%s" % ( tree.root, glob )
			runShell(cmd)

class SyncDir(MergeStep):
	def __init__(self,srcroot,srcdir=None,destdir=None,exclude=[],delete=False):
		self.srcroot = srcroot
		self.srcdir = srcdir
		self.destdir = destdir
		self.exclude = exclude
		self.delete = delete

	def run(self,tree):
		if self.srcdir:
			src = os.path.join(self.srcroot,self.srcdir)+"/"
		else:
			src = os.path.normpath(self.srcroot)+"/"
		if self.destdir:
			dest = os.path.join(tree.root,self.destdir)+"/"
		else:
			if self.srcdir:
				dest = os.path.join(tree.root,self.srcdir)+"/"
			else:
				dest = os.path.normpath(tree.root)+"/"
		if not os.path.exists(dest):
			os.makedirs(dest)
		cmd = "rsync -a --exclude CVS --exclude .svn --filter=\"hide /.git\" --filter=\"protect /.git\" "
		for e in self.exclude:
			cmd += "--exclude %s " % e
		if self.delete:
			cmd += "--delete --delete-excluded "
		cmd += "%s %s" % ( src, dest )
		runShell(cmd)

class CopyAndRename(MergeStep):
	def __init__(self, src, dest, ren_fun):
		self.src = src
		self.dest = dest
		#renaming function ... accepts source file path, and returns destination filename
		self.ren_fun = ren_fun

	def run(self, tree):
		srcpath = os.path.join(tree.root,self.src)
		for f in os.listdir(srcpath):
			destfile = os.path.join(tree.root,self.dest)
			destfile = os.path.join(destfile,self.ren_fun(f))
			runShell("( cp -a %s/%s %s )" % ( srcpath, f, destfile ))

class SyncFiles(MergeStep):
	def __init__(self, srcroot, files):
		self.srcroot = srcroot
		self.files = files
		if not isinstance(files, dict):
			raise TypeError("'files' argument should be a dict of source:destination items")

	def run(self, tree):
		for src, dest in self.files.items():
			if dest is not None:
				dest = os.path.join(tree.root, dest)
			else:
				dest = os.path.join(tree.root, src)
			src = os.path.join(self.srcroot, src)
			if os.path.exists(dest):
				print("%s exists, attempting to unlink..." % dest)
				try:
					os.unlink(dest)
				except:
					pass
			dest_dir = os.path.dirname(dest)
			if os.path.exists(dest_dir) and os.path.isfile(dest_dir):
				os.unlink(dest_dir)
			if not os.path.exists(dest_dir):
				os.makedirs(dest_dir)
			print("copying %s to final location %s" % (src, dest))
			shutil.copyfile(src, dest)

class ELTSymlinkWorkaround(MergeStep):

	def run(self, tree):
		dest = os.path.join(tree.root + "/eclass/ELT-patches")
		if not os.path.lexists(dest):
			os.makedirs(dest)

class MergeUpdates(MergeStep):
	def __init__(self, srcroot):
		self.srcroot = srcroot

	def run(self, tree):
		for src in sorted(glob.glob(os.path.join(self.srcroot, "profiles/updates/?Q-????")), key=lambda x: (x[-4:], x[-7])):
			dest = os.path.join(tree.root, "profiles/updates", src[-7:])
			if os.path.exists(dest):
				src_file = open(src)
				dest_file = open(dest)
				src_lines = src_file.readlines()
				dest_lines = dest_file.readlines()
				src_file.close()
				dest_file.close()
				dest_lines.extend(src_lines)
				dest_file = open(dest, "w")
				dest_file.writelines(dest_lines)
				dest_file.close()
			else:
				shutil.copyfile(src, dest)

class CleanTree(MergeStep):
	# remove all files from tree, except dotfiles/dirs.

	def __init__(self,exclude=[]):
		self.exclude = exclude
	def run(self,tree):
		for fn in os.listdir(tree.root):
			if fn[:1] == ".":
				continue
			if fn in self.exclude:
				continue
			runShell("rm -rf %s/%s" % (tree.root, fn))

class SyncFromTree(SyncDir):
	# sync a full portage tree, deleting any excess files in the target dir:
	def __init__(self,srctree,exclude=[]):
		self.srctree = srctree
		SyncDir.__init__(self,srctree.root,srcdir=None,destdir=None,exclude=exclude,delete=True)

	def run(self,desttree):
		SyncDir.run(self,desttree)
		desttree.logTree(self.srctree)

class Tree(object):
	def __init__(self,name,root):
		self.name = name
		self.root = root
	def head(self):
		return "None"

class XMLRecorder(object):

	def __init__(self):
		self.xml_out = etree.Element("packages")

	def write(self, fn):
		if os.path.exists(os.path.dirname(fn)):
			a = open(fn, "wb")
			etree.ElementTree(self.xml_out).write(a, encoding='utf-8', xml_declaration=True, pretty_print=True)
			a.close()

	def xml_record(self, repo, kit, catpkg):
		cat, pkg = catpkg.split("/")
		exp = "category[@name='%s']" % cat
		catxml = self.xml_out.find(exp)
		if catxml == None:
			catxml = etree.Element("category", name=cat)
			self.xml_out.append(catxml)
		pkgxml = self.xml_out.find("category[@name='%s']/package/[@name='%s']" % (cat, pkg))

		# remove existing
		if pkgxml != None:
			pkgxml.getparent().remove(pkgxml)
		pkgxml = etree.Element("package", name=pkg, repository=repo.name, kit=kit.name)
		doMeta = True
		try:
			tpkgmeta = open("%s/%s/metadata.xml" % (repo.root, catpkg), 'rb')
			try:
				metatree = etree.parse(tpkgmeta)
			except UnicodeDecodeError:
				doMeta = False
			tpkgmeta.close()
			if doMeta:
				use_vars = []
				usexml = etree.Element("use")
				for el in metatree.iterfind('.//flag'):
					name = el.get("name")
					if name != None:
						flag = etree.Element("flag")
						flag.attrib["name"] = name
						flag.text = etree.tostring(el, encoding='unicode', method="text").strip()
						usexml.append(flag)
				pkgxml.attrib["use"] = ",".join(use_vars)
				pkgxml.append(usexml)
		except IOError:
			pass
		catxml.append(pkgxml)

class GitTree(Tree):

	"A Tree (git) that we can use as a source for work jobs, and/or a target for running jobs."

	def __init__(self, name: object, branch: object = "master", url: object = None, commit_sha1: object = None,
	             pull: object = True,
	             root: object = None,
				 create: object = False,
				 reponame: object = None) -> object:

		# note that if create=True, we are in a special 'local create' mode which is good for testing. We create the repo locally from
		# scratch if it doesn't exist, as well as any branches. And we don't push.

		self.name = name
		self.root = root
		self.url = url
		self.merged = []
		self.pull = True
		self.reponame = reponame
		self.create = create

		self.initializeTree(branch, commit_sha1)


		# if we don't specify root destination tree, assume we are source only:
	
	def initializeTree(self, branch, commit_sha1=None):
		self.branch = branch
		self.commit_sha1 = commit_sha1
		if self.root == None:
			base = "/var/git/source-trees"
			self.root = "%s/%s" % ( base, self.name )
		if not os.path.isdir("%s/.git" % self.root):
			# repo does not exist? - needs to be cloned or created
			if os.path.exists(self.root):
				print("%s exists but does not appear to be a valid git repository. Exiting." % self.root)
				sys.exit(1)
				# dir exists but not a git repo, so exit
			
			base = os.path.dirname(self.root)
			if self.create:
				# we have been told to create this repo. This works even if we have a remote clone URL specified
				os.makedirs(self.root)
				runShell("( cd %s && git init )" % self.root )
				runShell("echo 'created by merge.py' > %s/README" % self.root )
				runShell("( cd %s &&  git add README; git commit -a -m 'initial commit by merge.py' )" % self.root )
				runShell("( cd %s && git remote add origin %s )" % ( self.root, self.url ))
			elif self.url:
				if not os.path.exists(base):
					os.makedirs(base)
				# we aren't supposed to create it from scratch -- can we clone it?
				runShell("(cd %s && git clone %s %s)" % ( base, self.url, os.path.basename(self.root) ))
			else:
				# we've run out of options
				print("Error: tree %s does not exist, but no clone URL specified. Exiting." % self.root)
				sys.exit(1)
		
		# if we've gotten here, we can assume that the repo exists at self.root. 

		# first, we will clean up any messes:
		runShell("(cd %s &&  git reset --hard && git clean -fd )" % self.root )

		# Now we need to make sure it's on the correct branch and commit sha1, if specified.

		# Let's make sure we have a local branch first:
		if not self.localBranchExists(self.branch):
			if not self.create:
				# branch does not exist, so get it from remote and create it:
				runShell("( cd %s &&  git fetch && git checkout -b %s --track origin/%s || git checkout -b %s)" % ( self.root, self.branch, self.branch, self.branch ))
			else:
				# in create mode, we take responsibility for creating branches ourselves, and we are not concerned with fetching:
				runShell("(cd %s &&  git checkout -b %s)" % ( self.root, self.branch ))
		
		# the local branch exists:
		
		if self.create:
			# we are done in this special case
			return

		# we are not in create mode, the branch exists and is active, but we want to make sure we are pointing to the exact
		# set of files that we want:

		if self.commit_sha1:
			# if a commit_sha1 is specified, then we also want to make sure we go to a detached state pointing to this commit:
			runShell("(cd %s && git fetch && git checkout %s )" % (self.root, self.commit_sha1 ))
		elif self.currentLocalBranch != self.branch:
			# we aren't on the right branch. Let's change that after we make sure we have the latest updates
			# git pull -f may fail for new branch that has not yet been pushed remote...
			runShell("(cd %s && git fetch && git checkout %s && git reset --hard && git pull -f || true)" % (self.root, self.branch ))
		elif self.pull:
			# we are on the right branch, but we want to make sure we have the latest updates 
			runShell("(cd %s && git reset --hard && git pull -f || true)" % self.root )

	@property
	def currentLocalBranch(self):
		s, branch = subprocess.getstatusoutput("( cd %s && git symbolic-ref --short -q HEAD )" % self.root)
		if s:
			return None
		else:
			return branch

	def localBranchExists(self, branch):
		s, branch = subprocess.getstatusoutput("( cd %s && git show-ref --verify --quiet refs/heads/%s )" % ( self.root, branch))
		if s:
			return False
		else:
			return True

	def gitSubmoduleAddOrUpdate(self, tree, path, url=None, sha1=None):
		if url == None:
			url = tree.url
		if sha1 == None:
			s, sha1 = subprocess.getstatusoutput("( cd %s && git rev-parse HEAD )" % tree.root)
			sha1 = sha1.strip()
		destpath = os.path.join(self.root, path)
		if not os.path.exists(destpath):
			runShell("( cd %s && git submodule add %s %s )" % ( os.path.dirname(destpath), url, tree.name ))
		runShell("( cd %s && git fetch && git checkout %s )" % ( destpath, sha1 ))
		runShell("( cd %s && git config -f .gitmodules submodule.kits/%s.branch %s )" % ( self.root, tree.name, tree.branch ))

	def getAllCatPkgs(self):
		self.gitCheckout()
		with open(self.root + "/profiles/categories","r") as a:
			cats = a.read().split()
		catpkgs = {} 
		for cat in cats:
			if not os.path.exists(self.root + "/" + cat):
				continue
			pkgs = os.listdir(self.root + "/" + cat)
			for pkg in pkgs:
				if not os.path.isdir(self.root + "/" + cat + "/" + pkg):
					continue
				catpkgs[cat + "/" + pkg] = self.name
		return catpkgs

	def catpkg_exists(self, catpkg):
		return os.path.exists(self.root + "/" + catpkg)

	def gitCheckout(self,branch="master"):
		runShell("(cd %s && git checkout %s)" % ( self.root, self.branch ))

	def gitCommit(self,message="",upstream="origin",branch=None,push=True):
		if branch == None:
			branch = self.branch
		runShell("( cd %s && git add . )" % self.root )
		cmd = "( cd %s && [ -n \"$(git status --porcelain)\" ] && git commit -a -F - << EOF || exit 0\n" % self.root
		if message != "":
			cmd += "%s\n\n" % message
		names = []
		if len(self.merged):
			cmd += "merged: \n\n"
			for name, sha1 in self.merged:
				if name in names:
					# don't print dups
					continue
				names.append(name)
				if sha1 != None:
					cmd += "  %s: %s\n" % ( name, sha1 )
		cmd += "EOF\n"
		cmd += ")\n"
		print("running: %s" % cmd)
		# we use os.system because this multi-line command breaks runShell() - really, breaks commands.getstatusoutput().
		retval = os.system(cmd)
		if retval != 0:
			print("Commit failed.")
			sys.exit(1)
		if push == True and self.create == False:
			runShell("(cd %s && git push --mirror)" % self.root )
		else:	 
			print("Pushing disabled.")


	def run(self,steps):
		print("Starting run")
		for step in steps:
			if step != None:
				print("Running step", step.__class__.__name__, step)
				step.run(self)

	def head(self):
		return headSHA1(self.root)

	def logTree(self,srctree):
		# record name and SHA of src tree in dest tree, used for git commit message/auditing:
		if srctree.name == None:
			# this tree doesn't have a name, so just copy any existing history from that tree
			self.merged.extend(srctree.merged)
		else:
			# this tree has a name, so record the name of the tree and its SHA1 for reference
			if hasattr(srctree, "origroot"):
				self.merged.append([srctree.name, headSHA1(srctree.origroot)])
				return

			self.merged.append([srctree.name, srctree.head()])

class RsyncTree(Tree):
	def __init__(self,name,url="rsync://rsync.us.gentoo.org/gentoo-portage/"):
		self.name = name
		self.url = url 
		base = "/var/rsync/source-trees"
		self.root = "%s/%s" % (base, self.name)
		if not os.path.exists(base):
			os.makedirs(base)
		runShell("rsync --recursive --delete-excluded --links --safe-links --perms --times --compress --force --whole-file --delete --timeout=180 --exclude=/.git --exclude=/metadata/cache/ --exclude=/metadata/glsa/glsa-200*.xml --exclude=/metadata/glsa/glsa-2010*.xml --exclude=/metadata/glsa/glsa-2011*.xml --exclude=/metadata/md5-cache/	--exclude=/distfiles --exclude=/local --exclude=/packages %s %s/" % (self.url, self.root))

class SvnTree(Tree):
	def __init__(self, name, url=None):
		self.name = name
		self.url = url
		base = "/var/svn/source-trees"
		self.root = "%s/%s" % (base, self.name)
		if not os.path.exists(base):
			os.makedirs(base)
		if os.path.exists(self.root):
			runShell("(cd %s && svn up)" % self.root, abortOnFail=False)
		else:
			runShell("(cd %s && svn co %s %s)" % (base, self.url, self.name))

class CvsTree(Tree):
	def __init__(self, name, url=None, path=None):
		self.name = name
		self.url = url
		if path is None:
			path = self.name
		base = "/var/cvs/source-trees"
		self.root = "%s/%s" % (base, path)
		if not os.path.exists(base):
			os.makedirs(base)
		if os.path.exists(self.root):
			runShell("(cd %s && cvs update -dP)" % self.root, abortOnFail=False)
		else:
			runShell("(cd %s && cvs -d %s co %s)" % (base, self.url, path))

regextype = type(re.compile('hello, world'))

class InsertFilesFromSubdir(MergeStep):

	def __init__(self,srctree,subdir,suffixfilter=None,select="all",skip=None, src_offset=None):
		self.subdir = subdir
		self.suffixfilter = suffixfilter
		self.select = select
		self.srctree = srctree
		self.skip = skip 
		self.src_offset = src_offset

	def run(self,desttree):
		desttree.logTree(self.srctree)
		src = self.srctree.root
		if self.src_offset:
			src = os.path.join(src, self.src_offset)
		if self.subdir:
			src = os.path.join(src, self.subdir)
		if not os.path.exists(src):
			return
		dst = desttree.root
		if self.subdir:
			dst = os.path.join(dst, self.subdir)
		if not os.path.exists(dst):
			os.makedirs(dst)
		for e in os.listdir(src):
			if self.suffixfilter and not e.endswith(self.suffixfilter):
				continue
			if isinstance(self.select, list):
				if e not in self.select:
					continue
			elif isinstance(self.select, regextype):
				if not self.select.match(e):
					continue
			if isinstance(self.skip, list):
				if e in self.skip:
					continue
			elif isinstance(self.skip, regextype):
				if self.skip.match(e):
					continue
			real_dst = os.path.basename(os.path.join(dst, e))
			runShell("cp -a %s/%s %s" % ( src, e, dst))

class InsertEclasses(InsertFilesFromSubdir):

	def __init__(self,srctree,select="all",skip=None):
		InsertFilesFromSubdir.__init__(self,srctree,"eclass",".eclass",select=select,skip=skip)

class InsertLicenses(InsertFilesFromSubdir):

	def __init__(self,srctree,select="all",skip=None):
		InsertFilesFromSubdir.__init__(self,srctree,"licenses",select=select,skip=skip)

class CreateCategories(MergeStep):

	def __init__(self,srctree):
		self.srctree = srctree

	def run(self,desttree):
		catset = set()
		with open(self.srctree.root + "/profiles/categories", "r") as f:
			cats = f.read().split()
			for cat in cats:
				if os.path.isdir(desttree.root + "/" + cat):
					catset.add(cat)
			if not os.path.exists(desttree.root + "/profiles"):
				os.makedirs(desttree.root + "/profiles")
			with open(desttree.root + "/profiles/categories", "w") as g:
				for cat in sorted(list(catset)):
					g.write(cat+"\n")

class ZapMatchingEbuilds(MergeStep):
	def __init__(self,srctree,select="all",branch=None):
		self.select = select
		self.srctree = srctree
		if branch != None:
			# Allow dynamic switching to different branches/commits to grab things we want:
			self.srctree.gitCheckout(branch)

	def run(self,desttree):
		# Figure out what categories to process:
		dest_cat_path = os.path.join(desttree.root, "profiles/categories")
		if os.path.exists(dest_cat_path):
			with open(dest_cat_path, "r") as f:
				dest_cat_set = set(f.read().splitlines())
		else:
			dest_cat_set = set()

		# Our main loop:
		print( "# Zapping builds from %s" % desttree.root )
		for cat in os.listdir(desttree.root):
			if cat not in dest_cat_set:
				continue
			src_catdir = os.path.join(self.srctree.root,cat)
			if not os.path.isdir(src_catdir):
				continue
			for src_pkg in os.listdir(src_catdir):
				dest_pkgdir = os.path.join(desttree.root,cat,src_pkg)
				if not os.path.exists(dest_pkgdir):
					# don't need to zap as it doesn't exist
					continue
				runShell("rm -rf %s" % dest_pkgdir)

class InsertEbuilds(MergeStep):

	"""
	Insert ebuilds in source tre into destination tree.

	select: Ebuilds to copy over.
		By default, all ebuilds will be selected. This can be modified by setting select to a
		list of ebuilds to merge (specify by catpkg, as in "x11-apps/foo"). It is also possible
		to specify "x11-apps/*" to refer to all source ebuilds in a particular category.

	skip: Ebuilds to skip.
		By default, no ebuilds will be skipped. If you want to skip copying certain ebuilds,
		you can specify a list of ebuilds to skip. Skipping will remove additional ebuilds from
		the set of selected ebuilds. Specify ebuilds to skip using catpkg syntax, ie.
		"x11-apps/foo". It is also possible to specify "x11-apps/*" to skip all ebuilds in
		a particular category.

	replace: Ebuilds to replace.
		By default, if an catpkg dir already exists in the destination tree, it will not be overwritten.
		However, it is possible to change this behavior by setting replace to True, which means that
		all catpkgs should be overwritten. It is also possible to set replace to a list containing
		catpkgs that should be overwritten. Wildcards such as "x11-libs/*" will be respected as well.

	categories: Categories to process. 
		categories to process for inserting ebuilds. Defaults to all categories in tree, using
		profiles/categories and all dirs with "-" in them and "virtuals" as sources.
	
	
	"""
	def __init__(self, srctree,select="all", select_only="all", skip=None, replace=False, categories=None,
	             ebuildloc=None, branch=None, cpm_logger=None, is_fixup=False):
		self.select = select
		self.skip = skip
		self.srctree = srctree
		self.replace = replace
		self.categories = categories
		self.cpm_logger = cpm_logger
		self.is_fixup = is_fixup
		if select_only == None:
			self.select_only = []
		else:
			self.select_only = select_only

		if branch != None:
			# Allow dynamic switching to different branches/commits to grab things we want:
			self.srctree.gitCheckout(branch)

		self.ebuildloc = ebuildloc

	def __repr__(self):
		return "<InsertEbuilds: %s>" % self.srctree.root

	def run(self,desttree):

		# Just for clarification, I'm breaking these out to separate variables:
		branch = desttree.branch
		kit = desttree.name

		if self.ebuildloc:
			srctree_root = self.srctree.root + "/" + self.ebuildloc
		else:
			srctree_root = self.srctree.root
		desttree.logTree(self.srctree)
		# Figure out what categories to process:
		src_cat_path = os.path.join(srctree_root, "profiles/categories")
		dest_cat_path = os.path.join(desttree.root, "profiles/categories")
		if self.categories != None:
			# categories specified in __init__:
			src_cat_set = set(self.categories)
		else:
			src_cat_set = set()
			if os.path.exists(src_cat_path):
				# categories defined in profile:
				with open(src_cat_path, "r") as f:
					src_cat_set.update(f.read().splitlines())
			# auto-detect additional categories:
			cats = os.listdir(srctree_root)
			for cat in cats:
				# All categories have a "-" in them and are directories:
				if os.path.isdir(os.path.join(srctree_root,cat)):
					if "-" in cat or cat == "virtual":
						src_cat_set.add(cat)
		if os.path.exists(dest_cat_path):
			with open(dest_cat_path, "r") as f:
				dest_cat_set = set(f.read().splitlines())
		else:
			dest_cat_set = set()
		# Our main loop:
		print( "# Merging in ebuilds from %s" % srctree_root )
		for cat in src_cat_set:
			catdir = os.path.join(srctree_root, cat)
			if not os.path.isdir(catdir):
				# not a valid category in source overlay, so skip it
				continue
			#runShell("install -d %s" % catdir)
			for pkg in os.listdir(catdir):
				catpkg = "%s/%s" % (cat,pkg)
				pkgdir = os.path.join(catdir, pkg)
				if self.cpm_logger and self.cpm_logger.match(catpkg, kit=kit, branch=branch, is_fixup=self.is_fixup):
					#already copied
					continue
				if self.select_only != "all" and catpkg not in self.select_only:
					# we don't want this catpkg
					continue
				if not os.path.isdir(pkgdir):
					# not a valid package dir in source overlay, so skip it
					continue
				if isinstance(self.select, list):
					if catpkg not in self.select:
						# we have a list of pkgs to merge, and this isn't on the list, so skip:
						continue
				elif isinstance(self.select, regextype):
					if not self.select.match(catpkg):
						# no regex match:
						continue
				if isinstance(self.skip, list):
					if catpkg in self.skip:
						# we have a list of pkgs to skip, and this catpkg is on the list, so skip:
						continue
				elif isinstance(self.skip, regextype):
					if self.select.match(catpkg):
						# regex skip match, continue
						continue
				dest_cat_set.add(cat)
				tcatdir = os.path.join(desttree.root,cat)
				tpkgdir = os.path.join(tcatdir,pkg)
				copied = False
				if self.replace == True or (isinstance(self.replace, list) and (catpkg in self.replace)):
					if not os.path.exists(tcatdir):
						os.makedirs(tcatdir)
					runShell("rm -rf %s; cp -a %s %s" % (tpkgdir, pkgdir, tpkgdir ))
					copied = True
				else:
					if not os.path.exists(tpkgdir):
						copied = True
					if not os.path.exists(tcatdir):
						os.makedirs(tcatdir)
					runShell("[ ! -e %s ] && cp -a %s %s || echo \"# skipping %s/%s\"" % (tpkgdir, pkgdir, tpkgdir, cat, pkg ))
				if copied:
					# log XML here.
					if self.cpm_logger:
						self.cpm_logger.recordCopyToXML(self.srctree, desttree, catpkg)
						if isinstance(self.select, regextype):
							# If a regex was used to match the copied catpkg, record the regex.
							self.cpm_logger.record(self.select, kit=kit, branch=branch, is_fixup=self.is_fixup)
						else:
							# otherwise, record the literal catpkg matched.
							self.cpm_logger.record(catpkg, kit=kit, branch=branch, is_fixup=self.is_fixup)
		if os.path.isdir(os.path.dirname(dest_cat_path)):
			# only write out if profiles/ dir exists -- it doesn't with shards.
			with open(dest_cat_path, "w") as f:
				f.write("\n".join(sorted(dest_cat_set)))

class ProfileDepFix(MergeStep):

	"ProfileDepFix undeprecates profiles marked as deprecated."

	def run(self,tree):
		fpath = os.path.join(tree.root,"profiles/profiles.desc")
		if os.path.exists(fpath):
			a = open(fpath,"r")
			for line in a:
				if line[0:1] == "#":
					continue
				sp = line.split()
				if len(sp) >= 2:
					prof_path = sp[1]
					runShell("rm -f %s/profiles/%s/deprecated" % ( tree.root, prof_path ))

class RunSed(MergeStep):

	"""
	Run sed commands on specified files.

	files: List of files.

	commands: List of commands.
	"""

	def __init__(self, files, commands):
		self.files = files
		self.commands = commands

	def run(self, tree):
		commands = list(itertools.chain.from_iterable(("-e", command) for command in self.commands))
		files = [os.path.join(tree.root, file) for file in self.files]
		run_command(["sed"] + commands + ["-i"] + files)

class GenCache(MergeStep):

	def __init__(self,cache_dir=None):
		self.cache_dir = cache_dir

	"GenCache runs egencache --update to update metadata."

	def run(self,tree):
		cmd = ["egencache", "--update", "--repo", tree.reponame if tree.reponame else tree.name,
		       "--repositories-configuration",
		       "[%s]\nlocation = %s" % (tree.reponame if tree.reponame else tree.name, tree.root),
		       "--jobs", repr(multiprocessing.cpu_count()+1)]
		if self.cache_dir:
			cmd += [ "--cache-dir", self.cache_dir ]
			if not os.path.exists(self.cache_dir):
				os.makedirs(self.cache_dir)
				os.chown(self.cache_dir, pwd.getpwnam('portage').pw_uid, grp.getgrnam('portage').gr_gid)
		run_command(cmd, abort_on_failure=True)

class GenUseLocalDesc(MergeStep):

	"GenUseLocalDesc runs egencache to update use.local.desc"

	def run(self,tree):
		run_command(["egencache", "--update-use-local-desc", "--repo", tree.reponame if tree.reponame else tree.name, "--repositories-configuration", "[%s]\nlocation = %s" % (tree.reponame if tree.reponame else tree.name, tree.root)], abort_on_failure=False)

class GitCheckout(MergeStep):

	def __init__(self,branch):
		self.branch = branch

	def run(self,tree):
		runShell("(cd %s && git checkout %s || git checkout -b %s --track origin/%s || git checkout -b %s)" % ( tree.root, self.branch, self.branch, self.branch, self.branch ))

class CreateBranch(MergeStep):

	def __init__(self,branch):
		self.branch = branch

	def run(self,tree):
		runShell("( cd %s && git checkout -b %s --track origin/%s )" % ( tree.root, self.branch, self.branch ))


class Minify(MergeStep):

	"Minify removes ChangeLogs and shrinks Manifests."

	def run(self,tree):
		runShell("( cd %s && find -iname ChangeLog -exec rm -f {} \; )" % tree.root )
		runShell("( cd %s && find -iname Manifest -exec sed -n -i -e \"/DIST/p\" {} \; )" % tree.root )

def getMySQLDatabase():
	from db_core import AppDatabase, getConfig
	return AppDatabase(getConfig())
# vim: ts=4 sw=4 noet
