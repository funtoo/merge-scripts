#!/usr/bin/python3

# This QA check will scan the meta-repo on the existing system for ebuilds that support an older version
# of python3 but not python3.6. This does not scan python_single_target ebuilds but rather those that can
# be built to support multiple python implementations.

from merge.merge_utils import *

import portage

p = portage.portdbapi()
p.freeze()

future_aux = {}

old_python_set = { "python_targets_python3_3", "python_targets_python3_4", "python_targets_python3_5" }
cur_python_set = { "python_targets_python3_6" }

def future_generator():
	for cp in p.cp_all():
		repos = p.getRepositories(catpkg=cp)
		cpv = p.xmatch("bestmatch-visible", cp)
		if cpv:
			future = p.async_aux_get(cpv, [ "INHERITED", "IUSE" ])
			future_aux[id(future)] = (cpv, repos)
			yield future

for future in iter_completed(future_generator()):
	cpv, repo = future_aux.pop(id(future))
	try:
		result = future.result()
	except KeyError as e:
		print("aux_get fail", cpv, e)
	eclasses, iuse = result
	iuse_set = set(iuse.split())

	if len(old_python_set & iuse_set) and not len(cur_python_set & iuse_set):
		# contains python3.4 or 3.5 compat but not python3.6 compat:
		print(cpv, repo, old_python_set & iuse_set)

