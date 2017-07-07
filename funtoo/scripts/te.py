#!/usr/bin/python3

import portage
from portage.dbapi.porttree import portdbapi
from portage.dep import use_reduce, dep_getkey, flatten
from portage.versions import catpkgsplit
config=portage.config()

# TODO: accept set of catpkgs.....
# TODO: analyze all deps of xorg-server for x11-apps deps

p = portdbapi(config)
def getDependencies(catpkgs, levels=0, cur_level=0):
	mypkgs = set()
	for catpkg in list(catpkgs):
		pkg = p.xmatch("bestmatch-visible", catpkg)
		if pkg == '':
			print("No match for %s", catpkg)
			return mypkgs
		try:
			aux = p.aux_get(pkg, ["DEPEND", "RDEPEND"])
		except portage.exception.PortageKeyError:
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
				mypkgs = mypkgs.union(getDependencies(mypkg, levels=levels, cur_level=cur_level+1))
	return mypkgs

def filtermatch(pkgset, fil):
	match = set()
	nomatch = set()
	for pkg in list(pkgset):
		if pkg.startswith(fil):
			match.add(pkg)
		else:
			nomatch.add(pkg)
	return match, nomatch

def stripCategories(pkgset, cats):
	newpkgset = set()
	for pkg in list(pkgset):
		a = pkg.split("/")
		print(pkg, a)
		if a[0] in cats:
			continue
		newpkgset.add(pkg)
	return newpkgset
"""
pkg = p.xmatch("bestmatch-visible", "x11-base/xorg-server")
aux = p.aux_get(pkg, ["DEPEND", "RDEPEND"])
for dep in flatten(use_reduce(aux[0]+" "+aux[1], matchall=True)):
	if len(dep) and dep[0] == "!":
		continue
	try:
		mypkg = dep_getkey(dep)
	except portage.exception.InvalidAtom:
		continue
	if mypkg not in mypkgs:
		mypkgs.add(mypkg)
print(sorted(list(mypkgs)))	
"""
a1 = getDependencies("x11-base/xorg-server")
a1_strip = stripCategories(a1, ['sys-devel','dev-perl', 'sys-apps', 'app-text', 'app-eselect' ])
print(a1_strip)

a1_m, a1_nom = filtermatch(a1, 'x11-')
print(a1_m)
print(a1_nom)
a2_m, a2_nom, = filtermatch(a1, 'x11-apps')
print(a2_m)
print(a2_nom)

