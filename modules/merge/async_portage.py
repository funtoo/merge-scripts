#!/usr/bin/python3

import portage
import warnings
portage.proxy.lazyimport.lazyimport(globals(),
	'portage.dbapi.dep_expand:dep_expand',
	'portage.dep:match_from_list,_match_slot',
	'portage.util.listdir:listdir',
	'portage.versions:best,_pkg_str',
)

async def async_xmatch(self, level, origdep, mydep=None, mykey=None, mylist=None):
	"caching match function; very trick stuff"
	
	if mydep is None:
		# this stuff only runs on first call of xmatch()
		# create mydep, mykey from origdep
		mydep = dep_expand(origdep, mydb=self, settings=self.settings)
		mykey = mydep.cp
	
	# if no updates are being made to the tree, we can consult our xcache...
	cache_key = None
	if self.frozen:
		cache_key = (mydep, mydep.unevaluated_atom)
		try:
			return self.xcache[level][cache_key][:]
		except KeyError:
			pass
	
	myval = None
	mytree = None
	if mydep.repo is not None:
		mytree = self.treemap.get(mydep.repo)
		if mytree is None:
			if level.startswith("match-"):
				myval = []
			else:
				myval = ""
	
	if myval is not None:
		# Unknown repo, empty result.
		pass
	elif level == "match-all-cpv-only":
		# match *all* packages, only against the cpv, in order
		# to bypass unnecessary cache access for things like IUSE
		# and SLOT.
		if mydep == mykey:
			# Share cache with match-all/cp_list when the result is the
			# same. Note that this requires that mydep.repo is None and
			# thus mytree is also None.
			level = "match-all"
			myval = self.cp_list(mykey, mytree=mytree)
		else:
			myval = match_from_list(mydep,
									self.cp_list(mykey, mytree=mytree))
	
	elif level in ("bestmatch-visible", "match-all",
				   "match-visible", "minimum-all", "minimum-all-ignore-profile",
				   "minimum-visible"):
		# Find the minimum matching visible version. This is optimized to
		# minimize the number of metadata accesses (improves performance
		# especially in cases where metadata needs to be generated).
		if mydep == mykey:
			mylist = self.cp_list(mykey, mytree=mytree)
		else:
			mylist = match_from_list(mydep,
									 self.cp_list(mykey, mytree=mytree))
		
		ignore_profile = level in ("minimum-all-ignore-profile",)
		visibility_filter = level not in ("match-all",
										  "minimum-all", "minimum-all-ignore-profile")
		single_match = level not in ("match-all", "match-visible")
		myval = []
		aux_keys = list(self._aux_cache_keys)
		if level == "bestmatch-visible":
			iterfunc = reversed
		else:
			iterfunc = iter
		
		for cpv in iterfunc(mylist):
			try:
				metadata = dict(zip(aux_keys, await self.async_aux_get(cpv, aux_keys, myrepo=cpv.repo)))
			except KeyError:
				# ebuild not in this repo, or masked by corruption
				continue
			
			try:
				pkg_str = _pkg_str(cpv, metadata=metadata,
								   settings=self.settings, db=self)
			except InvalidData:
				continue
			
			if visibility_filter and not self._visible(pkg_str, metadata):
				continue
			
			if mydep.slot is not None and \
					not _match_slot(mydep, pkg_str):
				continue
			
			if mydep.unevaluated_atom.use is not None and \
					not self._match_use(mydep, pkg_str, metadata,
										ignore_profile=ignore_profile):
				continue
			
			myval.append(pkg_str)
			if single_match:
				break
		
		if single_match:
			if myval:
				myval = myval[0]
			else:
				myval = ""
	
	elif level == "bestmatch-list":
		# dep match -- find best match but restrict search to sublist
		warnings.warn("The 'bestmatch-list' mode of "
					  "portage.dbapi.porttree.portdbapi.xmatch is deprecated",
					  DeprecationWarning, stacklevel=2)
		myval = best(list(self._iter_match(mydep, mylist)))
	elif level == "match-list":
		# dep match -- find all matches but restrict search to sublist (used in 2nd half of visible())
		warnings.warn("The 'match-list' mode of "
					  "portage.dbapi.porttree.portdbapi.xmatch is deprecated",
					  DeprecationWarning, stacklevel=2)
		myval = list(self._iter_match(mydep, mylist))
	else:
		raise AssertionError(
			"Invalid level argument: '%s'" % level)
	
	if self.frozen:
		xcache_this_level = self.xcache.get(level)
		if xcache_this_level is not None:
			xcache_this_level[cache_key] = myval
			if not isinstance(myval, _pkg_str):
				myval = myval[:]
	
	return myval