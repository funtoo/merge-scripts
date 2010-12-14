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
	def __init__(self,srcroot,srcdir=None,destdir=None,exclude=[],delete=False):
		self.srcroot = srcroot
		self.srcdir = srcdir
		self.destdir = destdir
		self.exclude = exclude
		self.delete = delete

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
		cmd = "rsync -a --exclude /.git "
		for e in self.exclude:
			cmd += "--exclude %s " % e
		if self.delete:
			cmd += "--delete "
		cmd += "%s %s" % ( src, dest )
		runShell(cmd)

class SyncTree(SyncDir):
	# sync a full portage tree, deleting any excess files in the target dir:
	def __init__(self,srcroot,exclude=[]):
		SyncDir.__init__(self,srcroot,srcdir=None,destdir=None,exclude=exclude,delete=True)

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

class ProfileDepFix(MergeStep):

	def run(self,tree):
		fpath = os.path.join(tree.root,"profiles/profiles.desc")
		if os.path.exists(fpath):
			a = open(fpath,"r")
			for line in a:
				if line[0:1] == "#":
					continue
				sp = line.split()
				if len(sp) >= 2:
					prof_path = sp[2]
					runShell("rm -f %s/profiles/%s/deprecated" % ( tree.root, prof_path ))

class GenCache(MergeStep):
	def run(self,tree):
		runShell("egencache --update --portdir=%s --jobs=12" % tree.root)

class GitPrep(MergeStep):
	def __init__(self,branch):
		self.branch = branch

	def run(self,tree):
		runShell("( cd %s; git checkout %s )" % ( tree.root, self.branch ))

class Minify(MergeStep):
	def run(self,tree):
		runShell("( cd %s; find -iname ChangeLog -exec rm -f {} \; )" % tree.root )
		runShell("( cd %s; find -iname Manifest -exec sed -n -i -e \"/DIST/p\" {} \; )" % tree.root )

class GitAdd(MergeStep):
	def __init__(self,commit=False,message="(no message)"):
		self.commit = commit
		self.message = message
	def run(self,tree):
		runShell("( cd %s; git add . )" % tree.root )
		if self.commit:
			runShell("( cd %s; [ -n \"$(git status --porcelain)\" ] && git commit -a -m \"%s\" )" % ( tree.root, self.message ))

steps = [
	SyncTree("/var/git/portage-gentoo",exclude=["/metadata/cache/**"]),
	ApplyPatchSeries("/root/git/funtoo-overlay/funtoo/patches"),
	SyncDir("/root/git/funtoo-overlay","funtoo/profiles","profiles"),
	ProfileDepFix(),
	SyncDir("/root/git/funtoo-overlay","licenses"),
	SyncDir("/root/git/funtoo-overlay","eclass"),
	InsertEbuilds("/root/git/funtoo-overlay",replace=True),
	InsertEbuilds("/root/git/tarsius-overlay",replace=False),
	GenCache()
]


a = UnifiedTree("/var/src/merge-portage-work",steps)
a.run()
b = UnifiedTree("/var/git/merge-portage-prod", [ 
	GitPrep("funtoo.org"), 
	SyncTree("/var/src/merge-portage-work"), 
	GitAdd(commit=True,message="glorious funtoo updates") 
])
b.run()
c = UnifiedTree("/var/git/merge-portage-mini", [ 
	GitPrep("funtoo.org"), 
	SyncTree("/var/src/merge-portage-work", exclude=["ChangeLog"]), 
	Minify(), 
	GitAdd(commit=True,message="glorious funtoo updates") 
])
c.run()

