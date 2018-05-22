#!/usr/bin/python3.4

from src.merge_utils import *

import portage

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

p_global = portage.portdbapi()
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
kit_count = {}
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
		try:
			f = flatten(use_reduce(aux[0]+" "+aux[1], matchall=True))
		except portage.exception.InvalidDependString:
			print("bad dep string in " + pkg + ": " + aux[0] + " " + aux[1])
			continue
		for dep in f:
			if len(dep) and dep[0] == "!":
				continue
			try:
				mypkg = dep_getkey(dep)
			except portage.exception.InvalidAtom:
				continue
			try:
				kit = p_global.better_cache[mypkg][0].name
			except KeyError:
				kit = "(none)"
			if kit == sys.argv[1]:
				continue
			if mypkg not in cp_all:
				if mypkg not in mypkgs:
					mypkgs[mypkg] = []
				if catpkg not in mypkgs[mypkg]:
					mypkgs[mypkg].append(catpkg)
			if kit not in kit_count:
				kit_count[kit] = 0
			kit_count[kit] += 1
print("External dependency            Packages with dependency")
print("=============================  ================================================================")
for pkg in sorted(mypkgs.keys()):
	print(pkg.ljust(30), mypkgs[pkg])

kit_tot = 0
for key, val in kit_count.items():
	kit_tot += val
print()
print("External Kit         Percentage")
print("===================  ================================================================")

for key in sorted(kit_count.keys()):
	print(key.ljust(20), "%4.2f%%" % ((kit_count[key]*100)/kit_tot))
#print(results)
# vim: ts=4 sw=4 noet
