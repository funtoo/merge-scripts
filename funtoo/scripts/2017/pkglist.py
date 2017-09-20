#!/usr/bin/python3.4

from merge_utils import *

import portage
from portage.versions import pkgsplit, pkgcmp
from portage.dbapi.porttree import portdbapi
from portage.dbapi.vartree import vardbapi

cur_name = sys.argv[1]
cur_tree = "/var/git/meta-repo/kits/" + cur_name
cur_overlay = GitTree(cur_name, root=cur_tree)
env = os.environ.copy()
env['PORTAGE_DEPCACHEDIR'] = '/var/cache/edb/%s-%s-meta' % (cur_overlay.name, cur_overlay.branch)
env['PORTAGE_REPOSITORIES'] = '''
[DEFAULT]
main-repo = %s

[%s]
location = %s
''' % (cur_name, cur_name, cur_tree)

p = portage.portdbapi()
#mysettings=portage.config(env=env, config_profile_path=''))
v = portage.vardbapi()

results = {
	"orphaned" : [],
	"masked" : [],
	"stale" : []
}

#for catpkg in v.cp_all():
#	inst_match = v.cp_list(catpkg)
#	if len(inst_match):
#		matches = p.match(catpkg)
#		all_matches = p.xmatch("match-all", catpkg)
#		if len(matches):
#			for inst in inst_match:
#				if inst not in matches:
#					inst_split =  pkgsplit(inst)
#					match_split = pkgsplit(matches[-1])
#					my_cmp = pkgcmp(inst_split,match_split)
#					if my_cmp > 0:
#						results["masked"].append(inst)
#					elif my_cmp < 0:
#						results["stale"].append(inst)
#		else:
#			if len(all_matches):
#				results["masked"] += inst_match
#			else:
#				results["orphaned"] += inst_match

p = portage.portdbapi(mysettings=portage.config(env=env, config_profile_path=''))
mypkgs = {}
cp_all = p.cp_all()
for catpkg in cp_all:
	for pkg in p.cp_list(catpkg):
		if pkg == '':
			print("No match for %s" % catpkg)
			continue
		try:
			aux = p.aux_get(pkg, ["DEPEND", "RDEPEND"])
		except PortageKeyError:
			print("Portage key error for %s" % repr(pkg))
			continue
		for dep in flatten(use_reduce(aux[0]+" "+aux[1], matchall=True)):
			if len(dep) and dep[0] == "!":
				continue
			try:
				mypkg = dep_getkey(dep)
			except portage.exception.InvalidAtom:
				continue
			if mypkg not in cp_all:
				if mypkg not in mypkgs:
					mypkgs[mypkg] = []
				if catpkg not in mypkgs[mypkg]:
					mypkgs[mypkg].append(catpkg)
print("External dependency            Packages with dependency")
print("=============================  ================================================================")
for pkg in sorted(mypkgs.keys()):
	print(pkg.ljust(30), mypkgs[pkg])

#print(results)
# vim: ts=4 sw=4 noet
