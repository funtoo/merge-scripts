#!/usr/bin/python3

# This QA check will scan the meta-repo on the existing system for ebuilds that support an older version
# of python3 but not python3.6. This does not scan python_single_target ebuilds but rather those that can
# be built to support multiple python implementations.

from merge_utils import *

import portage
import os
from portage.versions import pkgsplit, pkgcmp
from portage.dbapi.porttree import portdbapi
from portage.dbapi.vartree import vardbapi

p = portage.portdbapi()

future_aux = {}

old_python_set = { "python_targets_python3_3", "python_targets_python3_4", "python_targets_python3_5" }
cur_python_set = { "python_targets_python3.6" }

def future_generator():
	for cp in p.cp_all():
		for cpv in p.xmatch("match-all", cp):
			future = p.async_aux_get(cpv, [ "INHERITED", "IUSE" ])
			future_aux[id(future)] = cpv
			yield future

for future in iter_completed(future_generator()):
	cpv = future_aux.pop(id(future))
	try:
		result = future.result()
	except KeyError as e:
		print("aux_get fail", cpv, e)
	eclasses, iuse = result
	iuse_set = set(iuse.split())

	if len(old_python_set & iuse_set) and not len(cur_python_set & iuse_set):
		# contains python3.4 or 3.5 compat but not python3.6 compat:
		print(cpv, old_python_set & iuse_set)

