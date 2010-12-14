#!/usr/bin/python2

import os,sys
import commands

debug = False

def runShell(string):
	if debug:
		print string
	else:
		print "running: %s" % string
		out = commands.getstatusoutput(string)
		if out[0] != 0:
			print "Error executing '%s'" % string
			print
			print "output:"
			print out[1]
			sys.exit(1)

class MergeStep(object):
	pass

class ApplyPatchSeries(MergeStep):
	def __init__(self,path):
		self.path = path

	def run(self,tree):
		a = open(os.path.join(self.path,"series"),"r")
		for line in a:
			if line[0:1] == "#":
				continue
			runShell( "( cd %s; git apply %s/%s )" % ( tree.root, self.path, line[:-1] ))

class SyncDir(MergeStep):
	def __init__(self,srcroot,srcdir=None,destdir=None):
		self.srcroot = srcroot
		self.srcdir = srcdir
		self.destdir = destdir

	def run(self,tree):
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
		cmd = "rsync -a --exclude /.git %s %s" % ( src, dest )
		runShell(cmd)

class UnifiedTree(object):
	def __init__(self,root,steps):
		self.root = root
		self.steps = steps

	def run(self):
		for step in self.steps:
			step.run(self)

class InsertEbuilds(MergeStep):

	def __init__(self,root,replace=False,categories=None):
		self.root = root
		self.replace = replace
		self.categories = categories

	def run(self,tree):

		# Figure out what categories to process:
		catpath = os.path.join(self.root,"profiles/categories")

		if self.categories != None:
			# categories specified in __init__:
			a = self.categories
		elif os.path.exists(catpath):
			# categories defined in profile:
			a = []
			f = open(os.path.join(self.root,"profiles/categories"),"r")
			for cat in f.readlines():
				a.append(cat.strip())
			f.close()
		else:
			# no categories specified to __init__, and no profiles/categories file, so auto-detect categories:
			a = []
			cats = os.listdir(self.root)
			for cat in cats:
				# All categories have a "-" in them and are directories:
				if os.path.isdir(os.path.join(self.root,cat)) and cat.find("-") != -1:
					a.append(cat)

		# Our main loop:
		print "# Merging in ebuilds from %s" % self.root 
		for cat in a:
			catdir = os.path.join(self.root,cat)
			if not os.path.isdir(catdir):
				# not a valid category in source overlay, so skip it
				continue
			runShell("install -d %s" % catdir)
			for pkg in os.listdir(catdir):
				pkgdir = os.path.join(catdir, pkg)
				if not os.path.isdir(pkgdir):
					# not a valid package dir in source overlay, so skip it
					continue
				tpkgdir = os.path.join(tree.root,cat)
				tpkgdir = os.path.join(tpkgdir,pkg)
				copy = False
				if self.replace:
					runShell("rm -rf %s; cp -a %s %s" % (tpkgdir, pkgdir, tpkgdir ))
				else:
					runShell("[ ! -e %s ] && cp -a %s %s || echo \"# skipping %s/%s\"" % (tpkgdir, pkgdir, tpkgdir, cat, pkg ))

steps = [
	SyncDir("/var/git/portage-gentoo"),
	ApplyPatchSeries("/root/git/funtoo-overlay/funtoo/patches"),
	SyncDir("/root/git/funtoo-overlay","funtoo/profiles","profiles"),
	SyncDir("/root/git/funtoo-overlay","licenses"),
	SyncDir("/root/git/funtoo-overlay","eclass"),
	InsertEbuilds("/root/git/funtoo-overlay",replace=True),
	InsertEbuilds("/root/git/tarsius-overlay",replace=False)
]


"""
ProfileFix(),
InsertEbuilds("/root/git/tarsius-portage",replace=["sys-apps/foo"])
"""

a = UnifiedTree("/var/git/portage-test",steps)
a.run()
