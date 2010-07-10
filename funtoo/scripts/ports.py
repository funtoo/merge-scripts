#!/usr/bin/python2

# Copyright 2010 Funtoo Technologies and Daniel Robbins

import os
import subprocess
import portage.versions
import commands
from grp import getgrnam

# This module implements a simplified mechanism to access the contents of a
# Portage tree. In addition, the PortageRepository class (see below) has
# an elegant design that should support alternate Portage repository layouts
# as well as alternate backend storage formats. An effort has been made to
# keep things simple and extendable.

class CatPkg(object):

	# CatPkg is an object that is used to specify a particular group of
	# ebuilds that is identified by a category and package name, such
	# as "sys-apps/portage".

	def __repr__(self):
		return "CatPkg(%s)" % self.catpkg

	def __init__(self,catpkg):
		# catpkg = something like "sys-apps/portage"
		self.catpkg = catpkg

	@property
	def cat(self):
		#i.e. "sys-apps"
		return self.catpkg.split("/")[0]
	
	@property
	def pkg(self):
		#i.e. "portage"
		return self.catpkg.split("/")[1]

	@property
	def p(self):
		#i.e. "portage"
		return self.pkg

	def __getitem__(self,key):
		
		# This method allows properties to be grabbed using atom["cat"]
		# as well as standard atom.cat. This comes in handy when expanding
		# strings: 
		#
		# path = "%(cat)s/%(p)s" % atom

		if hasattr(self,key):
			return getattr(self,key)

class RepositoryObjRef(object):

	# a reference to a file and the repository that owns it.

	def __repr__(self):
		return "RepsitoryObjRef(%s,%s,%s)" % ( self.repo, self.obj, self.path )

	def __init__(self,repo,obj,path):
		self.repo = repo
		self.obj = obj
		self.path = path

class PkgAtom(object):

	# Our PkgAtom is different from a dependency, and literally means "a
	# specific reference to an individual package". This package could be a
	# specific ebuild in a Portage tree, or a specific record in
	# /var/db/pkg indicating that the package is installed. An "PkgAtom"
	# uniquely references one package without ambiguity. 
	
	# LOGICAL TEST OF AN ATOM: Two identical atoms cannot co-exist in a
	# single repository. 

	# LOGICAL TEST OF WHAT IS CONSIDERED ATOM DATA: Any data that can be
	# used to specify a uniquely-existing package in a repository, that is
	# capable of co-existing with other similar atoms, should be considered
	# atom data. Otherwise, the data should not be considered atom data.
	# Example: slots *are* part of an PkgAtom for repositories of installed or
	# built packages, because foo/bar-1.0:slot=3 and foo/bar-1.0:slot=4 can
	# co-exist in these repositories.

	# So note that a package *slot* is considered part of the PkgAtom for
	# packages that have already been installed or built. However, slot is
	# *not* part of the PkgAtom for packages in a Portage tree, as the slot
	# can be undefined at this point. For installed packages, the slot can
	# be specified as follows:

	# sys-apps/portage-2.2_rc67:slot=3
	
	# However, USE variables are not considered PkgAtom data for any type of
	# repository because "foo/bar-1.0[gleep]" and "foo/bar-1.0[boing]"
	# cannot co-exist independently in a Portage tree *or* installed
	# package repository.

	# The PkgAtom object provides a standard class for describing a package
	# atom, in the abstract. Helper methods/properties are provided to
	# access the atom's various attributes, such as package name, category,
	# package version, revision, etc. The package atom is not tied to a
	# particular Portage repository, and does not have an on-disk path. If
	# you want an on-disk path for an PkgAtom, you'd create a new PkgAtom and
	# pass it to the PortageRepository object and it will tell you.

	# As touched on above, there is a text representation of an PkgAtom that
	# is standardized, which is:

	# <cat>/<p>{:key1=val1{:key2=val2...}}

	# <cat> = category name
	# <p> = full package name and version (including optional revision)
	# :key=val = optional additional data in key=value format. values can
	# consist of any printable character except a colon. Additional key
	# values can be specified by appending another colon to the line,
	# such as:

	# sys-foo/bar-1.0:slot=1:python=2.6:keywords=foo,bar,oni

	# (Although you wouldn't want to specify keywords in an PkgAtom as it
	# wouldn't pass the LOGICAL TESTS above.)
	
	def __repr__(self):
		return "PkgAtom(%s)" % self.atom

	def __init__(self,atom):
		self.atom = atom
		self._keysplit = None
		self._keys = None
		self._cpvs = None

	def __getitem__(self,key):
		
		# This method allows properties to be grabbed using atom["cat"]
		# as well as standard atom.cat. This comes in handy when expanding
		# strings: 
		#
		# path = "%(cat)s/%(p)s" % atom

		if hasattr(self,key):
			return getattr(self,key)

	@property
	def keys(self):
		
		# Additional atomdata key/value pairs in dictionary format. These
		# are created on initialization and you should not modify the
		# keys property directly.

		if self._keys == None:
			self._keys = {}
			for meta in self._keysplit[1:]:
				key, val = meta.split("=",1)
				self._keys[key] = val
		return self._keys

	@property
	def cpvs(self):
		# cpvs = "catpkgsplit string" and is used by other properties
		if self._cpvs == None:
			self._keysplit = self.atom.split(":")
			self._cpvs = portage.versions.catpkgsplit(self._keysplit[0])
		return self._cpvs
	
	@property
	def cat(self):
		#i.e. "sys-apps"
		return self.atom.split("/")[0]
	
	@property
	def pf(self):
		#i.e. "portage-2.2_rc67-r1"
		return self.atom.split("/")[1]
	
	@property
	def p(self):
		#i.e. "portage"
		return self.cpvs[1]

	@property
	def pv(self):
		#i.e. "2.2_rc67"
		return self.cpvs[2]
	
	@property
	def pr(self):
		#i.e. "r1"
		return self.cpvs[3]

	def __eq__(self,other):
		# We can only test for atom equality, but cannot otherwise compare them.
		# PkgAtoms are equal when they reference the same unique cat/pkg and have
		# the same key data.
		return self.cpvs == other.cpvs and self.keys == other.keys

class EClassAtom(object):

	def __repr__(self):
		return "EClassAtom(%s)" % self.atom

	def __init__(self,atom):
		self.atom = atom

class Adapter(object):

	def __init__(self,**args):
		for arg in args.keys():
			setattr(self,arg,args[arg])

class FileAccessInterface(object):

	def __init__(self,base_path):
		self.base_path = base_path
	
	def open(self,file, mode):
		return open("%s/%s" % ( self.base_path, file ), mode)

	def listdir(self,path):
		return os.listdir(os.path.normpath("%s/%s" % ( self.base_path, path ) ))

	def exists(self,path):
		return os.path.exists("%s/%s" % ( self.base_path, path ))

	def isdir(self,path):
		return os.path.isdir("%s/%s" % ( self.base_path, path ))

	def diskpath(self,path):
		return os.path.normpath("%s/%s" % ( self.base_path, path ))

class GitAccessInterface(FileAccessInterface):

	def __init__(self,base_path):
		self.base_path = base_path
		self.tree = {}

	def populate(self):
		print commands.getoutput("cd %s; git ls-tree --name-only HEAD" % self.base_path)

class PortageRepository(object):

	# PortageRepository provides an easy-to-use and elegant means of
	# accessing an on-disk Gentoo/Funtoo Portage repository. It is designed
	# to allow for some abstraction of the underlying repository structure.

	# PortageRepository should be suitable for creating subclasses accessed
	# a remote Portage repository, or accessed the contents of .git
	# metadata to view the repository, or even a Portage repository with a
	# non-standard filesystem layout.

	# This class has minimal external source code dependencies, utilizing
	# only "portage.versions" from the official Portage sources for version
	# splitting, etc. This allows this code to be easily used by utility
	# programs.

	# Subclasses can override PortageRepository's init_paths() method to
	# implement alternate repository layouts, or override accessor
	# functions (via self.access) to implement alternate storage
	# mechanisms.

	def __repr__(self):
		return "PortageRepository(%s)" % self.base_path

	def grabfile(self,path):

		# grabfile() is a simple helper method that grabs the contents
		# of a typical portage configuration file, minus any lines
		# beginning with "#", and returns each line as an item in a
		# list. Newlines are stripped. This helper function looks at
		# the repository base_path, not any overlays.  If a directory
		# is specified, the contents of the directory are concatenated
		# and returned.

		out=[]	
		if not self.access.exists(path):
			return out
		if self.access.isdir(path):
			scan = self.access.listdir(path)
			scan = map(lambda(x): "%s/%s" % ( path, x ), scan )
		else:
			scan = [ path ]
		for path in scan:
			a=self.access.open(path,"r")
			for line in a.readlines():
				if len(line) and line[0] != "#":
					out.append(line[:-1])
			a.close()
		return out

	# The self._has_*() and self._*_list() methods below are used to query
	# the Portage repository. If you want to change the structure of the
	# Portage repository, you would override these methods in a subclass,
	# and possibly update self.init_paths() as needed to ensure that the
	# Adapters reference your methods (we don't call these methods
	# directly, instead we look at self.atom_map which will point to the
	# right methods to use for each object type in the repository.)

	# Note that the _has_*() methods will return a path to the object if
	# it exists, otherwise None. This behavior should be preserved as it
	# improves the utility of these methods. Better than True/False.

	# Also note that the self.access object is used for all file-related
	# operations. This approach should also be preserved to allow
	# retargetable storage back-ends to be implemented.

	# The _has_*() and _*_list() methods do not recurse through overlays.
	# They query the local repository only. That is why these methods
	# should not be called by other code.

	# Also note that I don't implement _eclass_list(), as eclasses are
	# not something that you need to query in this way. You just need
	# to find the right eclasses from your base tree and overlays, and
	# _has_eclass() is sufficient to get this done.

	def _has_eclass(self,arg,**args):
		path = "eclass/%s.eclass" % arg.atom
		if self.access.exists(path):
			return path

	def _has_catpkg(self,catpkg):
		if self.access.isdir(catpkg.catpkg):
			return catpkg.catpkg

	def _catpkg_list(self,categories=None):
		cp = []
		if categories == None:
			categories = self.categories
		for cat in categories:
			if not self.access.isdir(cat):
				continue
			for pkg in self.access.listdir(cat):
				cp.append(CatPkg("%s/%s" % ( cat, pkg )))
		return cp

	def _has_pkgatom(self,pkgatom):
		path = "%s/%s/%s.ebuild" % ( pkgatom.cat, pkgatom.p, pkgatom.pf )
		if self.access.exists(path):
			return path

	def _pkgatom_list(self,catpkgs=None):
		pa = []
		if catpkgs == None:
			catpkgs = self._catpkg_list()
		for catpkg in catpkgs:
			if not self.access.isdir(catpkg.catpkg):
				continue
			for file in self.access.listdir(catpkg.catpkg):
				if file[-7:] == ".ebuild":
					pa.append(PkgAtom("%s/%s" % ( catpkg.cat, file[:-7])))
		return pa

	def init_paths(self):

		# The Portage repository structure is abstracted somewhat using
		# the settings defined in the init_paths() function. This
		# function is automatically called by __init__() so you can
		# simply override this method for any variant PortageRepository
		# layouts without having to mess with __init__()

		# self.access points to a FileAccessInterface object, which
		# provides methods for accessing the underlying file objects.
		# GitAccessInterface can also be used. All IO operations like
		# "listdir", "exists", "is_dir", etc. should go through
		# self.access to allow retargetable storage back-ends.

		self.access = FileAccessInterface(self.base_path)

		self.path = {
			"eclass_dir" : "eclass",
			"categories" : "profiles/categories",
			"info_pkgs" : "profiles/info_pkgs",
			"info_vars" : "profiles/info_vars"
		}

		#self.config_map = {
		#	"categories" : {
		#		"read" : 
		
		# self.atom_map defines the different types of Atoms that are
		# in the PortageTree, and points to internal methods for 
		# determining if an Atom exists ("has") and getting a list of
		# Atoms ("list"), and points to a list of overlays to use
		# when we need to take overlays into account.

		# Eclasses and packages can have different inheritance
		# patterns, and the "overlays" setting below allows their
		# inheritance patterns to be different.
		
		# The Adapter objects are a convenience so I don't need to use
		# recursive dictionaries and type
		# self.atom_map[objtype]["overlays"].  Instead I can type
		# self.atom_map[objtype].overlays and avoid one hash lookup to
		# boot. It also makes the code easier to read. All the Adapter
		# does is create object attributes and methods based on the
		# keyword arguments you pass to __init__().

		self.atom_map = {
			CatPkg : Adapter( 
					has=self._has_catpkg,
					list=self._catpkg_list,
					overlays=self.overlays
			),
			PkgAtom: Adapter( 
					has=self._has_pkgatom, 
					list=self._pkgatom_list,
					overlays=self.overlays  
			),
			EClassAtom: Adapter(
					has=self._has_eclass, 
					overlays=self.eclass_overlays 
			)
		}

	def __init__(self,base_path, **args):

		# initialize variables. Also note that self.overlays contains a
		# list of child overlays, which in turn can have their own
		# child overlays (even though classic Portage doesn't allow
		# overlays to have their own overlays, this is supported by
		# this code. Typically just your "main" tree would have
		# overlays and overlays would not have their own overlays.)
		
		# Overlays at the beginning of the self.overlays list have
		# precedence.
		#
		# Here's how you would set up /usr/portage as the base tree
		# with /var/tmp/git/funtoo-overlay as its overlay:
		#
		# a = PortageRepository("/usr/portage")
		# b = PortageRepository("/var/tmp/git/funtoo-overlay",overlay=True)
		# a.overlays = [b]
		#
		# You would then call "a" and it would automatically access
		# its overlays as needed.
		#
		# Eclass Overlays are normally disabled, but can be enabled
		# using the eclass_overlays variable:
		#
		# a.eclass_overlays = [b]
		#
		# Now, not only will ebuilds in "b" complement and override
		# those ebuilds in "a", but eclasses in "b" will also complement
		# and override those in "a".

		self.overlays = []
		self.eclass_overlays = []

		# self.base_path is a variable pointing to the starting path
		# of the Portage tree, i.e. "/usr/portage".

		self.base_path = base_path

		# specifying "overlay=True" to __init__() will set self.overlay
		# to True. This is not really used for anything right now other
		# than making any code using this class easier to read.

		if "overlay" in args and args["overlay"] == True:
			self.overlay = True
		else:
			self.overlay = False

		# self.init_paths() sets up repository-specific configuration,
		# and can be overridden by PortageRepository subclasses without
		# having to mess around with hacking the standard __init__()
		# logic:

		self.init_paths()

	@property
	def info_pkgs(self,recurse=True):

		# Returns "info_pkgs" from repository, which is a set
		# of ebuild atoms that "emerge --info" should display
		# versions of (used for user bug reports)

		return self.__grabset__(self.path["info_pkgs"],recurse)

	@property
	def info_vars(self,recurse=True):
		
		# Returns "info_vars" from repository, which is a set
		# of variables that "emerge --info" should display.
		# (Used for user bug reports.)
		
		return self.__grabset__(self.path["info_vars"],recurse)

	@property
	def categories(self,recurse=True):
		
		# This property will return a set containing all valid
		# categories. By default, overlays are scanned as well.
		
		return self.__grabset__(self.path["categories"],recurse)

	def __grabset__(self,path,recurse=True):
		
		# This is a helper function for various methods above
		# that need to grab data from a file in the repo and
		# return the data. This helper function *will* recurse
		# through child overlays and append the child data
		# -- useful for categories, info_pkgs, and info_vars,
		# but probably not what you want for package.mask :)

		out = set(self.grabfile(path))
		if recurse:
			for overlay in self.overlays:
				out = out | overlay.__grabset__(path)
		return out

	def getList(self,otype,qlist,recurse=True):
		atoms = set()
		if recurse:
			for overlay in self.atom_map[otype].overlays:
				atoms = atoms | overlay.getList(otype,qlist,recurse)
		atoms = atoms | set(self.atom_map[otype].list(qlist))
		return atoms

	def getRef(self,atom,recurse=True,**args):

		# This is a handy method that, when given an ebuild PkgAtom, will
		# return the path to the atom on disk, as well as the object
		# reference to the PortageRepository that owns the atom. This
		# method will look in the current repository, as well as any
		# child repositories if recurse=True, which is the default
		# setting. First argument is an PkgAtom() object.

		if recurse:
			for overlay in self.atom_map[type(atom)].overlays:
				ref = overlay.getRef(atom,recurse,**args)
				if ref != None:
					return ref
			path = self.atom_map[type(atom)].has(atom, **args)
			if path != None:
				return RepositoryObjRef(self,atom,path)
			else:
				return None
	
	def do(self,action,atom,env={}):
		ref = self.getRef(atom)
		if ref == None:
			return None
		master_env = {
			"PORTAGE_TMPDIR" : "/var/tmp/portage",
			"EBUILD" : ref.repo.access.diskpath(ref.path),
			"EBUILD_PHASE" : action,
			"ECLASSDIR" : self.access.diskpath(self.path["eclass_dir"]),
			"PORTDIR" : self.access.base_path,
			"PORTDIR_OVERLAY" : " ".join(self.overlays),
			"PORTAGE_GID" : repr(getgrnam("portage")[2]),
			"CATEGORY" : atom.cat,
			"PF" : atom.pf,
			"P" : atom.p,
			"PV" : atom.pv
		} 
		master_env.update(env)	
		pr, pw = os.pipe()
		a = os.dup(pw)
		os.dup2(a,9)
		p = subprocess.call(["/usr/lib/portage/bin/ebuild.sh",action],env=master_env,close_fds=False)
		a = os.read(pr, 100000)
		print a.split("\n")
		os.close(pr)
		os.close(pw)

a=PortageRepository("/usr/portage-gentoo")
b=PortageRepository("/root/git/funtoo-overlay",overlay=True)
a.overlays=[b]
print a.getRef(PkgAtom("sys-apps/portage-2.2_rc67-r2"))
print a.getRef(EClassAtom("autotools"))
print a.getRef(CatPkg("sys-libs/glibc"))
print a.getList(CatPkg,["sys-apps","sys-libs"])
print
print a.getList(PkgAtom,[CatPkg("sys-apps/portage")])
