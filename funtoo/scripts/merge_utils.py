#!/usr/bin/python2

import os,sys,types
import argparse
import commands
import shutil
import glob

debug = False

mergeLog = open("/var/tmp/merge.log","w")

def headSHA1(tree):
	head = None
	hfile = os.path.join(tree,".git/HEAD")
	if os.path.exists(hfile):
		infile = open(hfile,"r")
		head = infile.readline().split()[1]
		infile.close()
		hfile2 = os.path.join(tree,".git")
		hfile2 = os.path.join(hfile2,head)
		if os.path.exists(hfile2):
			infile = open(hfile2,"r")
			head = infile.readline().split()[0]
	return head

def runShell(string,abortOnFail=True):
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
			if abortOnFail:
				sys.exit(1)

class MergeStep(object):
	pass

class AutoGlobMask(MergeStep):

	def __init__(self,catpkg,glob,maskdest):
		self.glob = glob
		self.catpkg = catpkg
		self.maskdest = maskdest

	def run(self,tree):
		f = open(os.path.join(tree.root,"profiles/package.mask", self.maskdest), "w")
		os.chdir(os.path.join(tree.root,self.catpkg))
		cat = self.catpkg.split("/")[0]
		for item in glob.glob(self.glob+".ebuild"):
			f.write("=%s/%s\n" % (cat,item[:-7]))
		f.close()

class ThirdPartyMirrors(MergeStep):

	def run(self,tree):
		orig = "%s/profiles/thirdpartymirrors" % tree.root
		new = "%s/profiles/thirdpartymirrors.new" % tree.root
		a = open(orig, "r")
		b = open(new, "w")
		for line in a:
			ls = line.split()
			if len(ls) and ls[0] == "gentoo":
				b.write("gentoo\t"+ls[1]+" http://www.funtoo.org/distfiles "+" ".join(ls[2:])+"\n")
			else:
				b.write(line)
		a.close()
		b.close()
		os.unlink(orig)
		os.link(new, orig)
		os.unlink(new)

class ApplyPatchSeries(MergeStep):
	def __init__(self,path):
		self.path = path

	def run(self,tree):
		a = open(os.path.join(self.path,"series"),"r")
		for line in a:
			if line[0:1] == "#":
				continue
			if line[0:4] == "EXEC":
				ls = line.split()
				runShell( "( cd %s; %s/%s )" % ( tree.root, self.path, ls[1] ))
			else:
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
		if not os.path.exists(dest):
			os.makedirs(dest)
		cmd = "rsync -a --exclude CVS --exclude .svn --filter=\"hide /.git\" --filter=\"protect /.git\" "
		for e in self.exclude:
			cmd += "--exclude %s " % e
		if self.delete:
			cmd += "--delete --delete-excluded "
		cmd += "%s %s" % ( src, dest )
		runShell(cmd)

class SyncFiles(MergeStep):
	def __init__(self, srcroot, files):
		self.srcroot = srcroot
		self.files = files
		if not isinstance(files, dict):
			raise TypeError("'files' argument should be a dict of source:destination items")

	def run(self, tree):
		for src, dest in self.files.items():
			if dest is not None:
				dest = os.path.join(tree.root, dest)
			else:
				dest = os.path.join(tree.root, src)
			src = os.path.join(self.srcroot, src)
			if os.path.exists(dest):
				print("%s exists, attempting to unlink..." % dest)
				try:
					os.unlink(dest)
				except:
					pass
			dest_dir = os.path.dirname(dest)
			if os.path.exists(dest_dir) and os.path.isfile(dest_dir):
				os.unlink(dest_dir)
			if not os.path.exists(dest_dir):
				os.makedirs(dest_dir)
			print("copying %s to final location %s" % (src, dest))
			shutil.copyfile(src, dest)

class MergeUpdates(MergeStep):
	def __init__(self, srcroot):
		self.srcroot = srcroot

	def run(self, tree):
		for src in sorted(glob.glob(os.path.join(self.srcroot, "profiles/updates/?Q-????")), key=lambda x: (x[-4:], x[-7])):
			dest = os.path.join(tree.root, "profiles/updates", src[-7:])
			if os.path.exists(dest):
				src_file = open(src)
				dest_file = open(dest)
				src_lines = src_file.readlines()
				dest_lines = dest_file.readlines()
				src_file.close()
				dest_file.close()
				dest_lines.extend(src_lines)
				dest_file = open(dest, "w")
				dest_file.writelines(dest_lines)
				dest_file.close()
			else:
				shutil.copyfile(src, dest)

class CleanTree(MergeStep):
	# remove all files from tree, except dotfiles/dirs.
	def run(self,tree):
		for fn in os.listdir(tree.root):
			if fn[:1] == ".":
				continue
			runShell("rm -rf %s/%s" % (tree.root, fn))

class SyncTree(SyncDir):
	# sync a full portage tree, deleting any excess files in the target dir:
	def __init__(self,srctree,exclude=[]):
		self.srctree = srctree
		SyncDir.__init__(self,srctree.root,srcdir=None,destdir=None,exclude=exclude,delete=True)

	def run(self,desttree):
		SyncDir.run(self,desttree)
		desttree.logTree(self.srctree)
class Tree(object):
	def __init__(self,name,branch="master",url=None,pull=False, trylocal=None):
		self.name = name
		self.branch = branch
		self.url = url
		self.merged = []
		self.trylocal = trylocal
		if self.trylocal and os.path.exists(self.trylocal):
			base = os.path.basename(self.trylocal)
			self.root = trylocal
		else:
			base = "/var/git/source-trees"
			self.root = "%s/%s" % ( base, self.name )

		if not os.path.exists(base):
			os.makedirs(base)
		if os.path.exists(self.root):
			runShell("(cd %s; git fetch origin)" % self.root, abortOnFail=False)
			runShell("(cd %s; git checkout %s)" % ( self.root, self.branch ))
			if pull:
				runShell("(cd %s; git pull -f origin %s)" % ( self.root, self.branch ), abortOnFail=False)
		else:
			runShell("(cd %s; git clone %s %s)" % ( base, self.url, self.name ))
			runShell("(cd %s; git checkout %s)" % ( self.root, self.branch ))

	def head(self):
		return headSHA1(self.root)


	def logTree(self,srctree):
		# record name and SHA of src tree in dest tree, used for git commit message/auditing:
		if srctree.name == None:
			# this tree doesn't have a name, so just copy any existing history from that tree
			self.merged.extend(srctree.merged)
		else:
			# this tree has a name, so record the name of the tree and its SHA1 for reference
			if hasattr(srctree, "origroot"):
				self.merged.append([srctree.name, headSHA1(srctree.origroot)])
				return

			self.merged.append([srctree.name, headSHA1(srctree.root)])

class DeadTree(Tree):
	def __init__(self,name,root):
		self.name = name
		self.root = root
	def head(self):
		return "None"

class RsyncTree(Tree):
        def __init__(self,name,url="rsync://rsync.us.gentoo.org/gentoo-portage/"):
                self.name = name
                self.url = url 
                base = "/var/rsync/source-trees"
                self.root = "%s/%s" % (base, self.name)
                if not os.path.exists(base):
                    os.makedirs(base)
                runShell("rsync --recursive --delete-excluded --links --safe-links --perms --times --compress --force --whole-file --delete --timeout=180 --exclude=/.git --exclude=/metadata/cache/ --exclude=/metadata/glsa/glsa-200*.xml --exclude=/metadata/glsa/glsa-2010*.xml --exclude=/metadata/glsa/glsa-2011*.xml --exclude=/metadata/md5-cache/  --exclude=/distfiles --exclude=/local --exclude=/packages %s %s/" % (self.url, self.root))

class SvnTree(object):
	def __init__(self, name, url=None, trylocal=None):
		self.name = name
		self.url = url
		self.trylocal = trylocal
		if self.trylocal and os.path.exists(self.trylocal):
			base = os.path.basename(self.trylocal)
			self.root = trylocal
		else:
			base = "/var/svn/source-trees"
			self.root = "%s/%s" % (base, self.name)
		if not os.path.exists(base):
			os.makedirs(base)
		if os.path.exists(self.root):
			runShell("(cd %s; svn up)" % self.root, abortOnFail=False)
		else:
			runShell("(cd %s; svn co %s %s)" % (base, self.url, self.name))

class CvsTree(object):
	def __init__(self, name, url=None, path=None, trylocal=None):
		self.name = name
		self.url = url
		if path is None:
			path = self.name
		self.trylocal = trylocal
		if self.trylocal and os.path.exists(self.trylocal):
			base = os.path.basename(self.trylocal)
			self.root = trylocal
		else:
			base = "/var/cvs/source-trees"
			self.root = "%s/%s" % (base, path)
		if not os.path.exists(base):
			os.makedirs(base)
		if os.path.exists(self.root):
			runShell("(cd %s; cvs update -dP)" % self.root, abortOnFail=False)
		else:
			runShell("(cd %s; cvs -d %s co %s)" % (base, self.url, path))

class UnifiedTree(Tree):
	def __init__(self,root,steps):
		self.steps = steps
		self.root = root
		self.name = None
		self.merged = []

	def run(self):
		for step in self.steps:
			step.run(self)

	def gitCommit(self,message="",push=False):
		runShell("( cd %s; git add . )" % self.root )
		cmd = "( cd %s; [ -n \"$(git status --porcelain)\" ] && git commit -a -F - << EOF || exit 0\n" % self.root
		if message != "":
			cmd += "%s\n\n" % message
		cmd += "merged: \n\n"
		for name, sha1 in self.merged:
			if sha1 != None:
				cmd += "  %s: %s\n" % ( name, sha1 )
		cmd += "EOF\n"
		cmd += ")\n"
		print "running: %s" % cmd
		# we use os.system because this multi-line command breaks runShell() - really, breaks commands.getstatusoutput().
		retval = os.system(cmd)
		if retval != 0:
			print "Commit failed."
			sys.exit(1)
		if push != False:
			runShell("(cd %s; git push %s)" % ( self.root, push ))

class VarLocTree(Tree):
	# This class is for use with overlays where the ebuilds are not stored at the root of the tree.
	# It allows self.root to be modified later and still remember original root location

	def __init__(self,name,branch="master",url=None,pull=False, trylocal=None):
		Tree.__init__(self, name, branch, url, pull, trylocal)
		self.origroot = self.root

	def head(self):
		return headSHA1(self.origroot)

class InsertEbuilds(MergeStep):

	def __init__(self,srctree,select="all",skip=None,replace=False,merge=None,categories=None,ebuildloc=None):
		self.select = select
		self.skip = skip
		self.srctree = srctree
		self.replace = replace
		self.merge = merge
		self.categories = categories

		# ebuildloc is the path to the tree relative to srctree.root.
		# This is for overlays where the tree is not located at root of overlay. Use wth VarLocTree
		if ebuildloc != None:
			self.srctree.root = os.path.join(self.srctree.root, ebuildloc)


	def run(self,desttree):
		desttree.logTree(self.srctree)
		# Figure out what categories to process:
		src_cat_path = os.path.join(self.srctree.root, "profiles/categories")
		dest_cat_path = os.path.join(desttree.root, "profiles/categories")
		if self.categories != None:
			# categories specified in __init__:
			src_cat_set = set(self.categories)
		else:
			src_cat_set = set()
			if os.path.exists(src_cat_path):
				# categories defined in profile:
				with open(src_cat_path, "r") as f:
					src_cat_set.update(f.read().splitlines())
			# auto-detect additional categories:
			cats = os.listdir(self.srctree.root)
			for cat in cats:
				# All categories have a "-" in them and are directories:
				if os.path.isdir(os.path.join(self.srctree.root,cat)):
					if "-" in cat or cat == "virtual":
						src_cat_set.add(cat)

		with open(dest_cat_path, "r") as f:
			dest_cat_set = set(f.read().splitlines())

		# Our main loop:
		print "# Merging in ebuilds from %s" % self.srctree.root
		for cat in src_cat_set:
			catdir = os.path.join(self.srctree.root,cat)
			if not os.path.isdir(catdir):
				# not a valid category in source overlay, so skip it
				continue
			#runShell("install -d %s" % catdir)
			for pkg in os.listdir(catdir):
				catpkg = "%s/%s" % (cat,pkg)
				pkgdir = os.path.join(catdir, pkg)
				if not os.path.isdir(pkgdir):
					# not a valid package dir in source overlay, so skip it
					continue
				if type(self.select) == types.ListType and catpkg not in self.select:
					# we have a list of pkgs to merge, and this isn't on the list, so skip:
					continue
				if type(self.skip) == types.ListType and catpkg in self.skip:
					# we have a list of pkgs to skip, and this catpkg is on the list, so skip:
					continue
				dest_cat_set.add(cat)
				tcatdir = os.path.join(desttree.root,cat)
				tpkgdir = os.path.join(tcatdir,pkg)
				copy = False
				copied = False
				if self.replace == True or (type(self.replace) == types.ListType and "%s/%s" % (cat,pkg) in self.replace):
					if not os.path.exists(tcatdir):
						os.makedirs(tcatdir)
					if self.merge is True or (isinstance(self.merge, list) and "%s/%s" % (cat,pkg) in self.merge and os.path.isdir(tpkgdir)):
						try:
							pkgdir_manifest_file = open("%s/Manifest" % pkgdir)
							pkgdir_manifest = pkgdir_manifest_file.readlines()
							pkgdir_manifest_file.close()
						except IOError:
							pkgdir_manifest = []
						try:
							tpkgdir_manifest_file = open("%s/Manifest" % tpkgdir)
							tpkgdir_manifest = tpkgdir_manifest_file.readlines()
							tpkgdir_manifest_file.close()
						except IOError:
							tpkgdir_manifest = []
						entries = {
							"AUX": {},
							"DIST": {},
							"EBUILD": {},
							"MISC": {}
						}
						for line in tpkgdir_manifest + pkgdir_manifest:
							if line.startswith(("AUX ", "DIST ", "EBUILD ", "MISC ")):
								entry_type = line.split(" ")[0]
								if entry_type in (("AUX", "DIST", "EBUILD", "MISC")):
									entries[entry_type][line.split(" ")[1]] = line
						runShell("cp -a %s %s" % (pkgdir, os.path.dirname(tpkgdir)))
						merged_manifest_file = open("%s/Manifest" % tpkgdir, "w")
						for entry_type in ("AUX", "DIST", "EBUILD", "MISC"):
							for key in sorted(entries[entry_type]):
								merged_manifest_file.write(entries[entry_type][key])
						merged_manifest_file.close()
					else:
						runShell("rm -rf %s; cp -a %s %s" % (tpkgdir, pkgdir, tpkgdir ))
					copied = True
				else:
					if not os.path.exists(tpkgdir):
						copied = True
					if not os.path.exists(tcatdir):
						os.makedirs(tcatdir)
					runShell("[ ! -e %s ] && cp -a %s %s || echo \"# skipping %s/%s\"" % (tpkgdir, pkgdir, tpkgdir, cat, pkg ))
				if copied:
					# log here.
					cpv = "/".join(tpkgdir.split("/")[-2:])
					mergeLog.write("%s\n" % cpv)

		with open(dest_cat_path, "w") as f:
			f.write("\n".join(sorted(dest_cat_set)))

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
					prof_path = sp[1]
					runShell("rm -f %s/profiles/%s/deprecated" % ( tree.root, prof_path ))

class GenCache(MergeStep):
	def run(self,tree):
		runShell("egencache --update --portdir=%s --jobs=12" % tree.root, abortOnFail=False)

class GenUseLocalDesc(MergeStep):
	def run(self,tree):
		runShell("egencache --update-use-local-desc --portdir=%s" % tree.root, abortOnFail=False)

class GitPrep(MergeStep):
	def __init__(self,branch):
		self.branch = branch

	def run(self,tree):
		runShell("( cd %s; git checkout %s )" % ( tree.root, self.branch ))

class Minify(MergeStep):
	def run(self,tree):
		runShell("( cd %s; find -iname ChangeLog -exec rm -f {} \; )" % tree.root )
		runShell("( cd %s; find -iname Manifest -exec sed -n -i -e \"/DIST/p\" {} \; )" % tree.root )


pull = True

parser = argparse.ArgumentParser(description="merge.py checks out funtoo.org's Gentoo tree, some developers overlays and the funtoo-overlay, and merges them to create Funtoo's unified Portage tree.")
parser.add_argument("--nopush", action="store_true", help="Prevents the script to push the git repositories")
parser.add_argument("--branch", default="master", help="The funtoo-overlay branch to use. Default: master.")
parser.add_argument("--experimental", default="store_false", help="Generate an experimental tree.")
parser.add_argument("destination", nargs="+", help="The destination git repository.")

args = parser.parse_args()

if args.nopush:
	push = False
else:
	push = "origin funtoo.org"

dest = args.destination
for d in dest:
	if d[0] != "/":
		print("%s: Please specify destination git tree with an absolute path." % d)
		sys.exit(1)

branch = args.branch
experimental = args.experimental
