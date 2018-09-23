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
portage._internal_caller = True
from portage.dep import use_reduce, dep_getkey, flatten
from portage.exception import PortageKeyError
import grp
import pwd
import multiprocessing
from collections import defaultdict
from portage.util.futures.iter_completed import async_iter_completed
from merge.config import config
from merge.async_engine import AsyncEngine
from merge.async_portage import async_xmatch

debug = False


class MergeStep(object):
	
	async def run(self):
		pass


def get_move_maps(move_map_path, kit_name):
	"""Grabs a move map list, returning a dictionary"""
	move_maps = {}
	for kit in ["global", kit_name]:
		fname = move_map_path + "/" + kit
		if os.path.exists(fname):
			with open(fname, "r") as move_file:
				for line in move_file:
					line = line.strip()
					if line.startswith("#"):
						continue
					elif len(line) == 0:
						continue
					move_split = line.split("->")
					if len(move_split) != 2:
						print("WARNING: invalid package move line in %s: %s" % ( fname, line))
						continue
					else:
						pkg1 = move_split[0].strip()
						pkg2 = move_split[1].strip()
						move_maps[pkg1] = pkg2
	return move_maps


def get_pkglist(fname):

	"""Grabs a package set list, returning a list of lines."""
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


def get_package_set_and_skips_for_kit(fixup_root, release, kit_name):

	pkgf = "package-sets/%s/%s-packages"
	pkgf_skip = "package-sets/%s/%s-skip"
	
	specific_pkgf = os.path.join(fixup_root, pkgf % (release, kit_name))
	if os.path.exists(specific_pkgf):
		specific_skips = os.path.join(fixup_root, pkgf_skip % (release, kit_name))
		if os.path.exists(specific_skips):
			return get_pkglist(specific_pkgf), get_pkglist(specific_skips)
		else:
			return get_pkglist(specific_pkgf), []
	else:
		global_pkgf = os.path.join(fixup_root, pkgf % ("global", kit_name))
		global_skips = os.path.join(fixup_root, pkgf_skip % ("global", kit_name))
		if os.path.exists(global_skips):
			return get_pkglist(global_pkgf), get_pkglist(global_skips)
		else:
			return get_pkglist(global_pkgf), []
		

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
	
	async def run(self, cur_overlay):
		cur_tree = cur_overlay.root
		try:
			with open(os.path.join(cur_tree, 'profiles/repo_name')) as f:
				cur_name = f.readline().strip()
		except FileNotFoundError:
			cur_name = cur_overlay.name
		env = os.environ.copy()
		env['PORTAGE_DEPCACHEDIR'] = '/var/cache/edb/%s-%s-meta' % ( cur_overlay.name, cur_overlay.branch )
		if cur_name != "core-kit":
			env['PORTAGE_REPOSITORIES'] = '''
[DEFAULT]
main-repo = core-kit

[core-kit]
location = %s/core-kit
aliases = gentoo

[%s]
location = %s
''' % (config.dest_trees, cur_name, cur_tree)
		else:
			env['PORTAGE_REPOSITORIES'] = '''
[DEFAULT]
main-repo = core-kit

[core-kit]
location = %s/core-kit
aliases = gentoo
''' % config.dest_trees
		p = portage.portdbapi(mysettings=portage.config(env=env,config_profile_path=''))

		pkg_use = []

		for pkg in p.cp_all():
			
			cp = portage.catsplit(pkg)
			if not os.path.exists(cur_tree + "/" + pkg):
				# catpkg is from core-kit, but we are not processing core kit, so skip:
				continue
			ebs = {}
			for a in await async_xmatch(p, "match-all", pkg):
				if len(a) == 0:
					continue
				aux = await p.async_aux_get(a, ["INHERITED"])
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
				if oldval is None:
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

async def getDependencies(cur_overlay, catpkgs, levels=0, cur_level=0):
	cur_tree = cur_overlay.root
	try:
		with open(os.path.join(cur_tree, 'profiles/repo_name')) as f:
			cur_name = f.readline().strip()
	except FileNotFoundError:
			cur_name = cur_overlay.name
	env = os.environ.copy()
	if cur_overlay.name != "core-kit":
		env['PORTAGE_REPOSITORIES'] = '''
	[DEFAULT]
	main-repo = core-kit

	[core-kit]
	location = %s/core-kit
	aliases = gentoo

	[%s]
	location = %s
	''' % (config.dest_trees, cur_name, cur_tree)
	else:
		env['PORTAGE_REPOSITORIES'] = '''
	[DEFAULT]
	main-repo = core-kit

	[core-kit]
	location = %s/core-kit
	aliases = gentoo
	''' % config.dest_trees
	p = portage.portdbapi(mysettings=portage.config(env=env,config_profile_path=''))
	mypkgs = set()

	future_aux = {}

	def future_generator():
		for catpkg in list(catpkgs):
			for my_cpv in p.cp_list(catpkg):
				if my_cpv == '':
					print("No match for %s" % catpkg)
					continue
				my_future = p.async_aux_get(my_cpv, [ "DEPEND", "RDEPEND"])
				future_aux[id(my_future)] = my_cpv
				yield my_future

	for fu_fu in  async_iter_completed(future_generator()):
		future_set = await fu_fu
		for future in future_set:
			cpv = future_aux.pop(id(future))
			try:
				result = future.result()
			except KeyError as e:
				print("aux_get fail", cpv, e)
			else:
				for dep in flatten(use_reduce(result[0]+" "+result[1], matchall=True)):
					if len(dep) and dep[0] == "!":
						continue
					try:
						mypkg = dep_getkey(dep)
					except portage.exception.InvalidAtom:
						continue
					if mypkg not in mypkgs:
						mypkgs.add(mypkg)
					if levels != cur_level:
						mypkgs = mypkgs.union(await getDependencies(cur_overlay, mypkg, levels=levels, cur_level=cur_level+1))
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

def getPackagesMatchingGlob(cur_overlay, my_glob, exclusions=None):
	insert_list = []
	if exclusions is None:
		exclusions = []
	for candidate in glob.glob(cur_overlay.root + "/" + my_glob):
		if not os.path.isdir(candidate):
			continue
		strip_len = len(cur_overlay.root)+1
		candy_strip = candidate[strip_len:]
		if candy_strip not in exclusions:
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

async def getPackagesWithEclass(cur_overlay, eclass):
	cur_tree = cur_overlay.root
	try:
		with open(os.path.join(cur_tree, 'profiles/repo_name')) as f:
			cur_name = f.readline().strip()
	except FileNotFoundError:
			cur_name = cur_overlay.name
	env = os.environ.copy()
	if cur_name != "core-kit":
		env['PORTAGE_REPOSITORIES'] = '''
	[DEFAULT]
	main-repo = core-kit

	[core-kit]
	location = %s/core-kit
	aliases = gentoo

	[%s]
	location = %s
	''' % (config.dest_trees, cur_name, cur_tree)
	else:
		env['PORTAGE_REPOSITORIES'] = '''
	[DEFAULT]
	main-repo = core-kit

	[core-kit]
	location = /%s/core-kit
	aliases = gentoo
	''' % config.dest_trees
	p = portage.portdbapi(mysettings=portage.config(env=env, config_profile_path=''))
	mypkgs = set()

	future_aux = {}
	cpv_map = {}

	def future_generator():
		for catpkg in p.cp_all():
			for my_cpv in p.cp_list(catpkg):
				if my_cpv == '':
					print("No match for %s" % catpkg)
					continue
				cpv_map[my_cpv] = catpkg
				my_future = p.async_aux_get(my_cpv, [ "INHERITED"])
				future_aux[id(my_future)] = my_cpv
				yield my_future

	for fu_fu in  async_iter_completed(future_generator()):
		future_set = await fu_fu
		for future in future_set:
			cpv = future_aux.pop(id(future))
			try:
				result = future.result()
			except KeyError as e:
				print("aux_get fail", cpv, e)
			else:
				if eclass in result[0].split():
					cp = cpv_map[cpv]
					if cp not in mypkgs:
						mypkgs.add(cp)
	return mypkgs

async def getPackagesInCatWithEclass(cur_overlay, cat, eclass):
	cur_tree = cur_overlay.root
	try:
		with open(os.path.join(cur_tree, 'profiles/repo_name')) as f:
			cur_name = f.readline().strip()
	except FileNotFoundError:
			cur_name = cur_overlay.name
	env = os.environ.copy()
	if cur_name != "core-kit":
		env['PORTAGE_REPOSITORIES'] = '''
	[DEFAULT]
	main-repo = core-kit

	[core-kit]
	location = %s/core-kit
	aliases = gentoo

	[%s]
	location = %s
	''' % (config.dest_trees, cur_name, cur_tree)
	else:
		env['PORTAGE_REPOSITORIES'] = '''
	[DEFAULT]
	main-repo = core-kit

	[core-kit]
	location = %s/core-kit
	aliases = gentoo
	''' % config.dest_trees
	p = portage.portdbapi(mysettings=portage.config(env=env, config_profile_path=''))
	mypkgs = set()

	future_aux = {}
	cpv_map = {}

	def future_generator():
		for catpkg in p.cp_all(categories=[cat]):
			for my_cpv in p.cp_list(catpkg):
				if my_cpv == '':
					print("No match for %s" % catpkg)
					continue
				cpv_map[my_cpv] = catpkg
				my_future = p.async_aux_get(my_cpv, [ "INHERITED"])
				future_aux[id(my_future)] = my_cpv
				yield my_future

	for fu_fu in async_iter_completed(future_generator()):
		future_set = await fu_fu
		for future in future_set:
			cpv = future_aux.pop(id(future))
			try:
				result = future.result()
			except KeyError as e:
				print("aux_get fail", cpv, e)
			else:
				if eclass in result[0].split():
					cp = cpv_map[cpv]
					if cp not in mypkgs:
						mypkgs.add(cp)
	return mypkgs

def extract_uris(src_uri):
	
	fn_urls = defaultdict(list)

	def record_fn_url(my_fn, p_blob):
		if p_blob not in fn_urls[my_fn]:
			new_files.append(my_fn)
			fn_urls[my_fn].append(p_blob)

	blobs = src_uri.split()
	prev_blob = None
	pos = 0
	new_files = []

	while pos <= len(blobs):
		if pos < len(blobs):
			blob = blobs[pos]
		else:
			blob = ""
		if blob in [")", "(", "||"] or blob.endswith("?"):
			pos += 1
			continue
		if blob == "->":
			# We found a http://foo -> bar situation. Handle it:
			fn = blobs[pos + 1]
			if fn is not None:
				record_fn_url(fn, prev_blob)
				prev_blob = None
				pos += 2
		else:
			# Process previous item:
			if prev_blob:
				fn = prev_blob.split("/")[-1]
				record_fn_url(fn, prev_blob)
			prev_blob = blob
			pos += 1

	return fn_urls, new_files

class CatPkgScan(MergeStep):

	def __init__(self, now, engine : AsyncEngine = None):
		self.now = now
		self.engine = engine

	async def run(self, cur_overlay):
		if self.engine is None:
			return
		cur_tree = cur_overlay.root
		try:
			with open(os.path.join(cur_tree, 'profiles/repo_name')) as f:
				cur_name = f.readline().strip()
		except FileNotFoundError:
				cur_name = cur_overlay.name
		env = os.environ.copy()
		if cur_name != "core-kit":
			env['PORTAGE_REPOSITORIES'] = '''
		[DEFAULT]
		main-repo = core-kit

		[core-kit]
		location = %s/core-kit
		aliases = gentoo

		[%s]
		location = %s
		''' % (config.dest_trees, cur_name, cur_tree)
		else:
			env['PORTAGE_REPOSITORIES'] = '''
		[DEFAULT]
		main-repo = core-kit

		[core-kit]
		location = %s/core-kit
		aliases = gentoo
		''' % config.dest_trees
		env['ACCEPT_KEYWORDS'] = "~amd64 amd64"
		p = portage.portdbapi(mysettings=portage.config(env=env, config_profile_path=''))

		for pkg in p.cp_all(trees=[cur_overlay.root]):

			# src_uri now has the following format:

			# src_uri["foo.tar.gz"] = [ "https://url1", "https//url2" ... ]
			# entries in SRC_URI from fetch-restricted ebuilds will have SRC_URI prefixed by "NOMIRROR:"

			# We are scanning SRC_URI in all ebuilds in the catpkg, as well as Manifest.
			# This will give us a complete list of all archives used in the catpkg.

			# We want to prioritize SRC_URI for bestmatch-visible ebuilds. We will use bm
			# and prio to tag files that are in bestmatch-visible ebuilds.

			bm = await async_xmatch(p, "bestmatch-visible", pkg)

			fn_urls = defaultdict(list)
			fn_meta = defaultdict(dict)

			for cpv in await async_xmatch(p, "match-all", pkg):
				if len(cpv) == 0:
					continue

				aux_info = p.aux_get(cpv, ["SRC_URI", "RESTRICT" ], mytree=cur_overlay.root)

				restrict = aux_info[1].split()
				mirror_restrict = False
				for r in restrict:
					if r == "mirror":
						mirror_restrict = True
						break

				# record our own metadata about each file...
				new_fn_urls, new_files = extract_uris(aux_info[0])
				fn_urls.update(new_fn_urls)
				for fn in new_files:
					fn_meta[fn]["restrict"] = mirror_restrict
					fn_meta[fn]["bestmatch"] = cpv == bm

			man_info = {}
			man_file = cur_tree + "/" + pkg + "/Manifest"
			if os.path.exists(man_file):
				man_f = open(man_file, "r")
				for line in man_f.readlines():
					ls = line.split()
					if len(ls) <= 3 or ls[0] != "DIST":
						continue
					try:
						digest_index = ls.index("SHA512") + 1
						digest_type = "sha512"
					except ValueError:
						try:
							digest_index = ls.index("SHA256") + 1
							digest_type = "sha256"
						except ValueError:
							print("Error: Manifest file %s has invalid format: " % man_file)
							print(" ", line)
							continue
					man_info[ls[1]] = { "size" : ls[2], "digest" : ls[digest_index], "digest_type" : digest_type }
				man_f.close()

			# for each catpkg:

			for f, uris in fn_urls.items():

				if f not in man_info:
					print("Error: %s/%s: %s Manifest file contains nothing for %s, skipping..." % (cur_overlay.name, cur_overlay.branch, pkg, f))
					continue

				s_out = ""
				for u in uris:
					s_out += u + "\n"

				# If we have already grabbed this distfile, then let's not queue it for fetching...

				if man_info[f]["digest_type"] == "sha512":
					# enqueue this distfile to potentially be added to distfile-spider. This is done asynchronously.
					self.engine.enqueue(
						file=f,
						digest=man_info[f]["digest"],
						size=man_info[f]["size"],
						restrict=fn_meta[f]["restrict"],
						catpkg=pkg,
						src_uri=s_out,
						kit_name=cur_overlay["name"],
						kit_branch=cur_overlay["branch"],
						digest_type=man_info[f]["digest_type"],
						bestmatch= fn_meta[f]["bestmatch"]
						
					)
				
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

async def _getAllDriver(metadata, path_prefix, dest_kit):
	# these may be eclasses or licenses -- we use the term 'eclass' here:
	eclasses = await getAllMeta(metadata, dest_kit)
	out = { None: [], "dest_kit" : [] }
	for eclass in eclasses:
		ep = os.path.join(dest_kit.root, path_prefix, eclass)
		if os.path.exists(ep):
			out["dest_kit"].append(eclass)
			continue
		out[None].append(eclass)
	return out

def simpleGetAllLicenses(dest_kit, parent_repo):
	out = []
	for my_license in os.listdir(parent_repo.root + "/licenses"):
		if os.path.exists(dest_kit.root + "/licenses/" + my_license):
			continue
		out.append(my_license)
	return out

def simpleGetAllEclasses(dest_kit, parent_repo):
	"""
	A simpler method to get all eclasses copied into a kit. If the eclass exists in parent repo, but not in dest_kit,
	return it in a list.

	:param dest_kit:
	:param parent_repo:
	:return:
	"""
	out = []
	for eclass in os.listdir(parent_repo.root + "/eclass"):
		if not eclass.endswith(".eclass"):
			continue
		if os.path.exists(dest_kit.root + "/eclass/" + eclass):
			continue
		out.append(eclass)
	return out


async def getAllEclasses(dest_kit):
	return await _getAllDriver("INHERITED", "eclass", dest_kit)

async def getAllLicenses(dest_kit):
	return await _getAllDriver("LICENSE", "licenses", dest_kit)

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
async def getAllMeta(metadata, dest_kit):
	metadict = { "LICENSE" : 0, "INHERITED" : 1 }
	metapos = metadict[metadata]
	
	env = os.environ.copy()
	env['PORTAGE_DEPCACHEDIR'] = '/var/cache/edb/%s-%s-meta' % ( dest_kit.name, dest_kit.branch )
	if dest_kit.name != "core-kit":
		env['PORTAGE_REPOSITORIES'] = '''
	[DEFAULT]
	main-repo = core-kit

	[core-kit]
	location = %s/core-kit
	aliases = gentoo

	[%s]
	location = %s
		''' % ( config.dest_trees, dest_kit.name, dest_kit.root)
	else:
		# we are testing a stand-alone kit that should have everything it needs included
		env['PORTAGE_REPOSITORIES'] = '''
	[DEFAULT]
	main-repo = core-kit

	[%s]
	location = %s
	aliases = gentoo
		''' % ( dest_kit.name, dest_kit.root )

	p = portage.portdbapi(mysettings=portage.config(env=env, config_profile_path=''))
	mymeta = set()

	future_aux = {}
	cpv_map = {}

	def future_generator():
		for catpkg in p.cp_all(trees=[dest_kit.root]):
			for cpv in p.cp_list(catpkg, mytree=dest_kit.root):
				if cpv == '':
					print("No match for %s" % catpkg)
					continue
				cpv_map[cpv] = catpkg
				my_future = p.async_aux_get(cpv, [ "LICENSE", "INHERITED" ], mytree=dest_kit.root)
				future_aux[id(my_future)] = cpv
				yield my_future

	for fu_fu in async_iter_completed(future_generator()):
		future_set = await fu_fu
		for future in future_set:
			cpv = future_aux.pop(id(future))
			try:
				result = future.result()
			except KeyError as e:
				print("aux_get fail", cpv, e)
			else:
				if metadata == "INHERITED":
					for eclass in result[metapos].split():
						key = eclass + ".eclass"
						if key not in mymeta:
							mymeta.add(key)
				elif metadata == "LICENSE":
					for lic in result[metapos].split():
						if lic in [")", "(", "||"] or lic.endswith("?"):
							continue
						if lic not in mymeta:
							mymeta.add(lic)
	return mymeta


async def generateKitSteps(release, kit_name, from_tree, select_only="all", fixup_repo=None, cpm_logger=None, filter_repos=None, move_maps=None, force=None, secondary_kit=False):
	if force is None:
		force = set()
	else:
		force = set(force)
	literals = []
	steps = []
	pkglist = []
	pkgf = "package-sets/%s-packages" % kit_name
	pkgf_skip = "package-sets/%s-skip" % kit_name
	pkgdir = fixup_repo.root
	pkgf = pkgdir + "/" + pkgf
	pkgf_skip = pkgdir + "/" + pkgf_skip
	skip = []
	if move_maps is None:
		move_maps = {}
	else:
		move_maps = move_maps
	master_pkglist, skip = get_package_set_and_skips_for_kit(fixup_repo.root, release, kit_name)
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
			eclass_pkglist = await getPackagesWithEclass( from_tree, eclass )
			pkglist += list(eclass_pkglist)
		elif pattern.startswith("@cat_has_eclass@:"):
			patsplit = pattern.split(":")
			cat, eclass = patsplit[1:]
			cat_pkglist = await getPackagesInCatWithEclass( from_tree, cat, eclass )
			pkglist += list(cat_pkglist)
		else:
			linesplit = pattern.split()
			if len(linesplit) and linesplit[0].endswith("/*"):
				# we want to support exclusions, starting with "-":
				exclusions = []
				for exclusion in linesplit[1:]:
					if exclusion.startswith("-"):
						exclusions.append(exclusion[1:])
					else:
						print("Invalid exclusion: %s" % pattern)
				pkglist += getPackagesMatchingGlob( from_tree, linesplit[0], exclusions=exclusions )
			else:
				move_pkg = pattern.split("->")
				if len(move_pkg) == 2:
					# we have something in the form sys-apps/foo -> sys-apps/bar -- we will add foo to the merge list...
					pkglist.append(move_pkg[0].strip())
					# but create move_map so we have info that we want to to move to the new location if we find it.
					move_maps[move_pkg[0].strip()] = move_pkg[1].strip()
				else:
					pkglist.append(pattern)
					literals.append(pattern)

	to_insert = set(pkglist)

	if secondary_kit is True:
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
		do_skip = False
		for filter_repo in filter_repos:
			if filter_repo.catpkg_exists(catpkg):
				if catpkg not in force:
					do_skip = True
					break
		if do_skip:
			continue
		else:
			new_set.add(catpkg)
	to_insert = new_set

	insert_kwargs = {"select": sorted(list(to_insert))}

	if pkglist:
		steps += [ InsertEbuilds(from_tree, skip=skip, replace=False, literals=literals, cpm_logger=cpm_logger, move_maps=move_maps, **insert_kwargs) ]
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
		if not os.path.exists(repo_root) or not os.path.isdir(repo_root):
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
		# map catpkg to kit that matched it.
		self._match_map = {}

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

	def match(self, catpkg):
		"""
		This method tells us whether we should copy over a catpkg to a particular kit.
		:param catpkg: the catpkg in question.
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

	def get_other_kit(self, catpkg):
		return self._match_map[catpkg] if catpkg in self._match_map else "(unknown)"

	def record(self, kit, catpkg, regex_matched=None, is_fixup=False):
		"""
		This method records catpkgs that we are copying over, so we can determine whether or not the catpkg should be
		copied again into later kits. In general, we only want to copy a catpkg once -- but there are exceptions, like
		if we have different branches of the same kit, or if we have fixups. So the logic is nuanced.

		:param catpkg: Either a catpkg string or regex match.
		:param is_fixup: True if we are applying a fixup; else False.
		:return: None
		"""
		if regex_matched is not None:
			if is_fixup:
				raise IndexError("Can't use regex with fixup")
			self._regexdict_curkit[regex_matched.pattern] = catpkg
			self._match_map[catpkg] = kit
		else:
			# otherwise, record in our regular matchdict
			self._matchdict_curkit[catpkg] = True
			self._match_map[catpkg] = kit
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

	def __init__(self, catpkg, my_glob, maskdest):
		self.glob = my_glob
		self.catpkg = catpkg
		self.maskdest = maskdest

	async def run(self,tree):
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

	async def run(self,tree):
		orig = "%s/profiles/thirdpartymirrors" % tree.root
		new = "%s/profiles/thirdpartymirrors.new" % tree.root
		mirrors = "https://fastpull-us.funtoo.org/distfiles"
		a = open(orig, "r")
		b = open(new, "w")
		for line in a:
			ls = line.split()
			if len(ls) and ls[0] == "gentoo":
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

	async def run(self, tree):
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
	def __init__(self, name, masters=None, aliases=None, priority=None):
		self.name = name
		self.aliases = aliases if aliases is not None else []
		self.masters = masters if masters is not None else []
		self.priority = priority

	async def run(self, tree):
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
	def __init__(self,globs=None):
		if globs is None:
			globs = []
		self.globs = globs
	
	async def run(self, tree):
		for glob in self.globs:
			cmd = "rm -rf %s/%s" % ( tree.root, glob )
			runShell(cmd)

class SyncDir(MergeStep):
	def __init__(self,srcroot,srcdir=None,destdir=None,exclude=None,delete=False):
		self.srcroot = srcroot
		self.srcdir = srcdir
		self.destdir = destdir
		self.exclude = exclude if exclude is not None else []
		self.delete = delete

	async def run(self, tree):
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

	async def run(self, tree):
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

	async def run(self, tree):
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

	async def run(self, tree):
		dest = os.path.join(tree.root + "/eclass/ELT-patches")
		if not os.path.lexists(dest):
			os.makedirs(dest)

class MergeUpdates(MergeStep):
	def __init__(self, srcroot):
		self.srcroot = srcroot

	async def run(self, tree):
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

	def __init__(self,exclude=None):
		if exclude is None:
			exclude = []
		self.exclude = exclude
	
	async def run(self,tree):
		for fn in os.listdir(tree.root):
			if fn[:1] == ".":
				continue
			if fn in self.exclude:
				continue
			runShell("rm -rf %s/%s" % (tree.root, fn))

class SyncFromTree(SyncDir):
	# sync a full portage tree, deleting any excess files in the target dir:
	def __init__(self,srctree,exclude=None):
		if exclude is None:
			exclude=[]
		self.srctree = srctree
		SyncDir.__init__(self,srctree.root,srcdir=None,destdir=None,exclude=exclude,delete=True)

	async def run(self, desttree):
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
		if catxml is None:
			catxml = etree.Element("category", name=cat)
			self.xml_out.append(catxml)
		pkgxml = self.xml_out.find("category[@name='%s']/package/[@name='%s']" % (cat, pkg))

		# remove existing
		if pkgxml is not None:
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
					if name is not None:
						flag = etree.Element("flag")
						flag.attrib["name"] = name
						flag.text = etree.tostring(el, encoding='unicode', method="text").strip()
						usexml.append(flag)
				pkgxml.attrib["use"] = ",".join(use_vars)
				pkgxml.append(usexml)
		except IOError:
			pass
		catxml.append(pkgxml)

class GitTreeError(Exception):
	
	pass


class GitTree(Tree):

	"A Tree (git) that we can use as a source for work jobs, and/or a target for running jobs."

	def __init__(self, name: str, branch: str = "master", url: str = None, commit_sha1: str = None,
				 root: str = None,
				 create: bool = False,
				 reponame: str = None):

		# note that if create=True, we are in a special 'local create' mode which is good for testing. We create the repo locally from
		# scratch if it doesn't exist, as well as any branches. And we don't push.

		self.name = name
		self.root = root
		self.url = url
		self.merged = []
		self.pull = True
		self.reponame = reponame
		self.create = create
		self.has_cleaned = False

		self.initializeTree(branch, commit_sha1)

		# if we don't specify root destination tree, assume we are source only:
	
	def initializeTree(self, branch, commit_sha1=None):
		self.branch = branch
		self.commit_sha1 = commit_sha1
		if self.root is None:
			base = config.source_trees
			self.root = "%s/%s" % ( base, self.name )
		if not os.path.isdir("%s/.git" % self.root):
			# repo does not exist? - needs to be cloned or created
			if os.path.exists(self.root):
				raise GitTreeError("%s exists but does not appear to be a valid git repository." % self.root)
			
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
		if self.url is not None:
			retval, out = subprocess.getstatusoutput("(cd %s && git remote get-url origin)" % self.root)
			my_url = self.url
			if my_url.endswith(".git"):
				my_url = my_url[:-4]
			if out.endswith(".git"):
				out = out[:-4]
			if out != my_url:
				print()
				print("Error: remote url for origin at %s is:" % self.root)
				print()
				print("  existing:",out)
				print("  expected:", self.url)
				print()
				print("Please fix or delete any repos that are cloned from the wrong origin.")
				raise GitTreeError("%s: Git origin mismatch." % self.root)
		# first, we will clean up any messes:
		if not self.has_cleaned:
			runShell("(cd %s &&  git reset --hard && git clean -fd )" % self.root )
			self.has_cleaned = True

		# git fetch will run as part of this:
		self.gitCheckout(self.branch)

		# point to specified sha1:

		if self.commit_sha1:
			runShell("(cd %s && git checkout %s )" % (self.root, self.commit_sha1 ))
			if self.head() != self.commit_sha1:
				raise GitTreeError("%s: Was not able to check out specified SHA1: %s." % (self.root, self.commit_sha1))
		elif self.pull:
			# we are on the right branch, but we want to make sure we have the latest updates 
			runShell("(cd %s && git pull -f || true)" % self.root )

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
		
	def remoteBranchExists(self, branch):
		s, o = subprocess.getstatusoutput("( cd %s && git show-branch remotes/origin/%s )" % ( self.root, branch))
		if s:
			return False
		else:
			return True

	def getDepthOfCommit(self, sha1):
		s, depth = subprocess.getstatusoutput("( cd %s && git rev-list HEAD ^%s --count)" % ( self.root, sha1 ))
		return int(depth) + 1

	def getAllCatPkgs(self):
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

	def gitCheckout(self, branch="master"):
		runShell("(cd %s && git fetch)" % self.root)
		if self.localBranchExists(branch):
			runShell("(cd %s && git checkout %s && git pull -f || true)" % (self.root, branch))
		elif self.remoteBranchExists(branch):
			runShell("(cd %s && git checkout -b %s --track origin/%s)" % (self.root, branch, branch))
		else:
			runShell("(cd %s && git checkout -b %s)" % (self.root, branch))
		if self.currentLocalBranch != branch:
			raise GitTreeError("%s: On branch %s. not able to check out branch %s." % (self.root, self.currentLocalBranch, branch))
		
	def gitPush(self):
		runShell("(cd %s && git push --mirror)" % self.root)

	def gitCommit(self, message="", push=True):
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
				if sha1 is not None:
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

	async def run(self,steps):
		for step in steps:
			if step is not None:
				print("Running step", step.__class__.__name__, step)
				await step.run(self)

	def head(self):
		return headSHA1(self.root)

	def logTree(self,srctree):
		# record name and SHA of src tree in dest tree, used for git commit message/auditing:
		if srctree.name is None:
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
		base = config.source_trees
		self.root = "%s/%s" % (base, self.name)
		if not os.path.exists(base):
			os.makedirs(base)
		runShell("rsync --recursive --delete-excluded --links --safe-links --perms --times --compress --force --whole-file --delete --timeout=180 --exclude=/.git --exclude=/metadata/cache/ --exclude=/metadata/glsa/glsa-200*.xml --exclude=/metadata/glsa/glsa-2010*.xml --exclude=/metadata/glsa/glsa-2011*.xml --exclude=/metadata/md5-cache/	--exclude=/distfiles --exclude=/local --exclude=/packages %s %s/" % (self.url, self.root))

class SvnTree(Tree):
	def __init__(self, name, url=None):
		self.name = name
		self.url = url
		base = config.source_trees
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
		base = config.source_trees
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

	async def run(self,desttree):
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

	async def run(self,desttree):
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
		if branch is not None:
			# Allow dynamic switching to different branches/commits to grab things we want:
			self.srctree.gitCheckout(branch)

	async def run(self,desttree):
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


class RecordAllCatPkgs(MergeStep):
	
	"""
	This is used for non-auto-generated kits where we should record the catpkgs as belonging to a particular kit
	but perform no other action. A kit generation NO-OP, comparted to InsertEbuilds
	"""
	
	def __init__(self, srctree: GitTree, cpm_logger: CatPkgMatchLogger=None):
		self.cpm_logger = cpm_logger
		self.srctree = srctree
		
	async def run(self, desttree=None):
		for catpkg in self.srctree.getAllCatPkgs():
			self.cpm_logger.record(desttree.name, catpkg, is_fixup=False)
			

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
	def __init__(self, srctree: GitTree, select="all", select_only="all", skip=None, replace=False, categories=None,
				 ebuildloc=None, branch=None, cpm_logger: CatPkgMatchLogger=None, literals: list=None, move_maps: dict=None, is_fixup=False):
		self.select = select
		self.skip = skip
		self.srctree = srctree
		self.replace = replace
		self.categories = categories
		self.cpm_logger = cpm_logger
		self.is_fixup = is_fixup
		# literals is a list of catpkgs specified directly in the package set, in sys-foo/bar format. We want to
		# print a warning if one of these manually specified in the package list is not copied because it was already
		# included in another kit. This can indicate an issue.
		if literals is None:
			self.literals = []
		else:
			self.literals = literals
		if move_maps is None:
			self.move_maps = {}
		else:
			self.move_maps = move_maps
		if select_only is None:
			self.select_only = []
		else:
			self.select_only = select_only

		if branch is not None:
			# Allow dynamic switching to different branches/commits to grab things we want:
			self.srctree.gitCheckout(branch)

		self.ebuildloc = ebuildloc

	def __repr__(self):
		return "<InsertEbuilds: %s>" % self.srctree.root

	async def run(self,desttree):

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
		if self.categories is not None:
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
				if self.cpm_logger and self.cpm_logger.match(catpkg):
					if catpkg in self.literals:
						print("!!! WARNING: catpkg '%s' specified in package set was already included in kit %s. This should be fixed." % ( catpkg, self.cpm_logger.get_other_kit(catpkg)))
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
				tpkgdir = None
				tcatpkg = None
				if catpkg in self.move_maps:
					if os.path.exists(pkgdir):
						# old package exists, so we'll want to rename.
						tcatpkg = self.move_maps[catpkg]
						tpkgdir = os.path.join(desttree.root, tcatpkg)
					else:
						tcatpkg = self.move_maps[catpkg]
						# old package doesn't exist, so we'll want to use the "new" pkgname as the source, hope it's there...
						pkgdir = os.path.join(srctree_root, tcatpkg)
						# and use new package name as destination...
						tpkgdir = os.path.join(desttree.root, tcatpkg)
				else:
					tpkgdir = os.path.join(desttree.root, catpkg)
				tcatdir = os.path.dirname(tpkgdir)
				copied = False
				if self.replace is True or (isinstance(self.replace, list) and (catpkg in self.replace)):
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
							self.cpm_logger.record(desttree.name, catpkg, regex_matched=self.select, is_fixup=self.is_fixup)
						else:
							# otherwise, record the literal catpkg matched.
							self.cpm_logger.record(desttree.name, catpkg, is_fixup=self.is_fixup)
							if tcatpkg is not None:
								# This means we did a package move. Record the "new name" of the package, too. So both
								# old name and new name get marked as being part of this kit.
								self.cpm_logger.record(desttree.name, tcatpkg, is_fixup=self.is_fixup)
		if os.path.isdir(os.path.dirname(dest_cat_path)):
			with open(dest_cat_path, "w") as f:
				f.write("\n".join(sorted(dest_cat_set)))

class ProfileDepFix(MergeStep):

	"ProfileDepFix undeprecates profiles marked as deprecated."

	async def run(self,tree):
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

	async def run(self, tree):
		commands = list(itertools.chain.from_iterable(("-e", command) for command in self.commands))
		files = [os.path.join(tree.root, file) for file in self.files]
		run_command(["sed"] + commands + ["-i"] + files)

class GenCache(MergeStep):

	def __init__(self,cache_dir=None):
		self.cache_dir = cache_dir

	"GenCache runs egencache --update to update metadata."

	async def run(self,tree):

		if tree.name != "core-kit":
			repos_conf = "[DEFAULT]\nmain-repo = core-kit\n\n[core-kit]\nlocation = %s/core-kit\n\n[%s]\nlocation = %s\n" % (config.dest_trees, tree.reponame if tree.reponame else tree.name, tree.root)

			# Perform QA check to ensure all eclasses are in place prior to performing egencache, as not having this can
			# cause egencache to hang.

			result = await getAllEclasses(tree)
			if None in result and len(result[None]):
				missing_eclasses = []
				for ec in result[None]:
					# if a missing eclass is not in core-kit, then we'll be concerned:
					if not os.path.exists("%s/core-kit/eclass/%s" % (config.dest_trees, ec)):
						missing_eclasses.append(ec)
				if len(missing_eclasses):
					print("!!! Error: QA check on kit %s failed -- missing eclasses:" % tree.name)
					print("!!!      : " + " ".join(missing_eclasses))
					print(
						"!!!      : Please be sure to use kit-fixups or the overlay's eclass list to copy these necessary eclasses into place.")
					sys.exit(1)
		else:
			repos_conf = "[DEFAULT]\nmain-repo = core-kit\n\n[core-kit]\nlocation = %s/core-kit\n" % config.dest_trees
		cmd = ["egencache", "--update", "--tolerant", "--repo", tree.reponame if tree.reponame else tree.name,
			   "--repositories-configuration" , repos_conf ,
			   "--jobs", repr(multiprocessing.cpu_count()+1)]
		if self.cache_dir:
			cmd += [ "--cache-dir", self.cache_dir ]
			if not os.path.exists(self.cache_dir):
				os.makedirs(self.cache_dir)
				os.chown(self.cache_dir, pwd.getpwnam('portage').pw_uid, grp.getgrnam('portage').gr_gid)
		run_command(cmd, abort_on_failure=True)

class GenUseLocalDesc(MergeStep):

	"GenUseLocalDesc runs egencache to update use.local.desc"

	async def run(self,tree):
		if tree.name != "core-kit":
			repos_conf = "[DEFAULT]\nmain-repo = core-kit\n\n[core-kit]\nlocation = %s/core-kit\n\n[%s]\nlocation = %s\n" % (config.dest_trees, tree.reponame if tree.reponame else tree.name, tree.root)
		else:
			repos_conf = "[DEFAULT]\nmain-repo = core-kit\n\n[core-kit]\nlocation = %s/core-kit\n" % config.dest_trees
		run_command(["egencache", "--update-use-local-desc", "--tolerant", "--repo", tree.reponame if tree.reponame else tree.name, "--repositories-configuration" , repos_conf ], abort_on_failure=False)

class GitCheckout(MergeStep):

	def __init__(self,branch):
		self.branch = branch

	async def run(self,tree):
		runShell("(cd %s && git checkout %s || git checkout -b %s --track origin/%s || git checkout -b %s)" % ( tree.root, self.branch, self.branch, self.branch, self.branch ))

class CreateBranch(MergeStep):

	def __init__(self,branch):
		self.branch = branch

	async def run(self,tree):
		runShell("( cd %s && git checkout -b %s --track origin/%s )" % ( tree.root, self.branch, self.branch ))


class Minify(MergeStep):

	"Minify removes ChangeLogs and shrinks Manifests."

	async def run(self,tree):
		runShell("( cd %s && find -iname ChangeLog -exec rm -f {} \; )" % tree.root )
		runShell("( cd %s && find -iname Manifest -exec sed -n -i -e \"/DIST/p\" {} \; )" % tree.root )



# vim: ts=4 sw=4 noet
