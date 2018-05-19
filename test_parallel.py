#!/usr/bin/python3

from merge_utils import *
import os

core_kit = GitTree("core-kit", "1.2-prime", "git@github.com:funtoo/kit-fixups.git", root="/var/tmp/core-kit")

from portage.dbapi.porttree import portdbapi

env = os.environ.copy()
env['PORTAGE_REPOSITORIES'] = '''
[DEFAULT]
main-repo = %s

[%s]
location = %s
''' % ("core-kit", "core-kit", "/var/tmp/core-kit")

p = portdbapi(mysettings=portage.config(env=env, config_profile_path=''))
#for cp in p.cp_all(trees=[core_kit.root]):
#	for cpv in p.cp_list(cp, mytree=core_kit.root):
#		try:
#			aux = p.aux_get(cpv, ["LICENSE", "INHERITED"], mytree=core_kit.root)
#		except PortageKeyError:
#			print("Portage key error for %s" % repr(cpv))
#			continue
#		print(cpv, aux)

for cp in p.cp_all(trees=[core_kit.root]):
	results = p.parallel_aux_get(p.cp_list(cp), mylist=["LICENSE", "INHERITED"], mytree=core_kit.root)
	for result in results:
		print(repr(result))
