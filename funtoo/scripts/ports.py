#!/usr/bin/python2

# Copyright 2010 Funtoo Technologies and Daniel Robbins

import os
import subprocess
import portage.versions

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


class Atom(object):

	# The Atom object provides a standard class for describing a package
	# atom, in the abstract. Helper methods/properties are provided to
	# access the atom's various attributes, such as package name, category,
	# package version, revision, etc. The package atom is not tied to a
	# particular Portage repository, and does not have an on-disk path. If
	# you want an on-disk path for an Atom, you'd create a new Atom and
	# pass it to the PortageRepository object and it will tell you.

	def __repr__(self):
		return "Atom(%s)" % self.atom

	def __init__(self,atom):
		self.atom = atom
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
	def cpvs(self):
		# cpvs = "catpkgsplit string" and is used by other properties
		if self._cpvs == None:
			self._cpvs = portage.versions.catpkgsplit(self.atom)
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

class PortageRepository(object):

	# PortageRepository provides an easy-to-use and elegant means of accessing an
	# on-disk Gentoo/Funtoo Portage repository. It is designed to allow for some
	# abstraction of the underlying repository structure.

	# PortageRepository should be suitable for creating subclasses accessed a
	# remote Portage repository, or accessed the contents of .git metadata to view
	# the repository, or even a Portage repository with a non-standard filesystem
	# layout.

	# This class has minimal dependencies, utilizing only "portage.versions" from
	# the official Portage sources for version splitting, etc. This allows this
	# code to be easily used by utility programs.

	# Subclasses can override PortageRepository's init_paths() method to implement
	# alternate layouts, or override accessor functions to implement alternate
	# storage mechanisms.

	def __repr__(self):
		return "PortageRepository(%s)" % self.base_path

	def grabfile(self,path):

		# grabfile() is a simple helper method that grabs the contents
		# of a typical portage configuration file, minus any lines
		# beginning with "#", and returns each line as an item in a
		# list. Newlines are stripped. This helper function looks at
		# the repository base_path, not any children (overlays).
		# If a directory is specified, the contents of the directory
		# are concatenated and returned.

		out=[]	
		if not os.path.exists(path):
			return out
		if os.path.isdir(path):
			scan = os.listdir(path)
			scan = map(lambda(x): "%s/%s" % ( path, x ), scan )
		else:
			scan = [ path ]
		for path in scan:
			a=open(path,"r")
			for line in a.readlines():
				if len(line) and line[0] != "#":
					out.append(line[:-1])
			a.close()
		return out
	
	def grabebuilds(self,path,catpkg):

		# grabebuilds() is another simple helper method that will
		# return a list of cpvs (ie. "foo/bar-1.0") in a list that
		# represent the ebuilds that exist on disk in this particular
		# repository. This helper function looks at the repository
		# base_path, not any children (overlays).

		out=[]
		fullpath = self.base_path + "/" + self.path["ebuild_dir"] % catpkg
		if not os.path.exists(fullpath):
			return out
		for file in os.listdir(fullpath):
			if self.isebuild(file):
				out.append(Atom("%s/%s" % ( catpkg.cat, self.ebuild2p(file) )))
		return out

	def init_paths(self):

		# The Portage repository structure is abstracted somewhat using
		# the settings defined in the init_paths() function. This function
		# is automatically called by __init__() so you can simply override
		# this method for any variant PortageRepository layouts without
		# having to mess with __init__()

		self.path = {
			"ebuild_atom" : "%(cat)s/$(p)s/$(pf)s.ebuild",
			"ebuild_dir" : "%(cat)s/%(p)s",
			"eclass_atom" : "eclass/%s.eclass",
			"eclass_dir" : "eclass",
			"categories" : "profiles/categories",
			"info_pkgs" : "profiles/info_pkgs",
			"info_vars" : "profiles/info_vars"
		}

		# The following helper functions attempt to abstract the on-disk
		# name of the ebuild:

		self.isebuild = lambda(x): x[-7:] == ".ebuild"
		self.ebuild2p = lambda(x): x[:-7]

	def __init__(self,base_path, **args):

		# initialize variables. Also note that self.children contains a
		# list of child overlays, which in turn can have their own
		# child overlays. Overlays at the beginning of the
		# self.overlays list have precedence.
		#
		# Rather than provide overlay access methods, you just set these
		# manually, like this:
		#
		# a = PortageRepository("/usr/portage")
		# b = PortageRepository("/var/tmp/git/funtoo-overlay",overlay=True)
		# a.children = [b]

		self.base_path = base_path
		self.children = []
		if "overlay" in args and args["overlay"] == True:
			self.overlay = True
		else:
			self.overlay = False
		self.init_paths()


	@property
	def overlays(self):

		# returns a list of all overlay paths, in priority
		# order. " ".join(foo.overlays) is suitable for passing
		# as a shell PORTDIR_OVERLAY value.

		out=[]
		for child in self.children:
			out.append(child.base_path)
		return out

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

		out = set(self.grabfile(self.base_path+"/"+path))
		if recurse:
			for overlay in self.children:
				out = out | overlay.__grabset__(path)
		return out

	def packages(self,catpkg,recurse=True):

		# This property will return a set containing all ebuilds
		# (in cpv format) of a particular category and package
		# name that exist in the repository. By default, overlays
		# are scanned as well.

		ebs = set(self.grabebuilds(self.base_path,catpkg))
		if recurse:
			for overlay in self.children:
				ebs = ebs | overlay.packages(catpkg)
		return ebs

	def getPathAndOwnerOfAtom(self,atom,recurse=True):

		# This is a handy method that, when given an ebuild Atom, will
		# return the path to the atom on disk, as well as the object
		# reference to the PortageRepository that owns the atom. This
		# method will look in the current repository, as well as any
		# child repositories if recurse=True, which is the default
		# setting. First argument is an Atom() object.

		if recurse:
			for overlay in self.children:
				path, owner = overlay.getPathAndOwnerOfAtom(atom)
				if path != None:
					return path, owner 
			#path = self.atomToPath(atom)
			path = self.base_path + "/" + self.path["ebuild_atom"] % atom
			if os.path.exists(path):
				return path, self
			else:
				return None, None

	def getPathAndOwnerOfEClass(self,eclass,recurse=True):

		# This is a handy method that, when given an eclass, will
		# return the path to the atom on disk, as well as the object
		# reference to the PortageRepository that owns the eclass. This
		# method will look in the current repository, as well as any
		# child repositories if recurse=True, which is the default
		# setting. First argument is a simple string specifying the
		# name of the eclass; i.e. "eutils".

		if recurse:
			for overlay in self.children:
				path, owner = overlay.getPathAndOwnerOfEClass(eclass)
				if path != None:
					return path, owner
			path = self.paths["eclass_atom"] % eclass
			if os.path.exists(path):
				return path, self
			else:
				return None, None

	def do(self,action,atom):
		path, owner = self.getPathAndOwnerOfAtom(atom)
		if path == None:
			return None
		env = {
			"PORTAGE_TMPDIR" : "/var/tmp/portage",
			"EBUILD" : path,
			"EBUILD_PHASE" : action,
			"ECLASSDIR" : "%s/%s" % ( self.base_path, self.path["eclass_dir"] ),
			"PORTDIR" : self.base_path,
			"PORTDIR_OVERLAY" : " ".join(self.overlays),
			"PORTAGE_GID" : "250",
			"CATEGORY" : atom.cat,
			"PF" : atom.pf,
			"P" : atom.p,
			"PV" : atom.pv,
			"dbkey" : "/var/tmp/foob/boob",
			"dbkey_format" : "extend-1"
		}
		retval = subprocess.call(["/usr/lib/portage/bin/ebuild.sh",action],env=env)

a=PortageRepository("/usr/portage-gentoo")
b=PortageRepository("/root/git/funtoo-overlay",overlay=True)
a.children=[b]
print a.categories
print a.info_pkgs
print a.info_vars
a.do("depend",Atom("sys-boot/grub-1.98-r1"))
print a.packages(CatPkg("sys-apps/portage"))

