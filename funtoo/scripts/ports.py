#!/usr/bin/python2

import os

class PortageRepository(object):

	def grabfile(self,path):
		out=[]	
		if not os.path.exists(path):
			return out
		a=open(path,"r")
		for line in a.readlines():
			if len(line) and line[0] != "#":
				out.append(line[:-1])
		a.close()
		return out
	
	def grabebuilds(self,path,cat,pkg):
		out=[]
		fullpath = "%s/%s/%s" % ( path, cat, pkg )
		if not os.path.exists(fullpath):
			return out
		for file in os.listdir(fullpath):
			if file[-7:] == ".ebuild":
				out.append("%s/%s" % ( cat, file[:-7] ))
		return out

	def __init__(self,base_path, **args):
		self.base_path = base_path
		self.children = []
		if "overlay" in args and args["overlay"] == True:
			self.overlay = True
		else:
			self.overlay = False
	
	@property
	def categories(self,recurse=True):
		cats = set(self.grabfile(self.base_path+"/profiles/categories"))
		if recurse:
			for overlay in self.children:
				cats = cats | overlay.categories
		return cats

	def packages(self,cat,pkg,recurse=True):
		ebs = set(self.grabebuilds(self.base_path,cat,pkg))
		if recurse:
			for overlay in self.children:
				ebs = ebs | overlay.packages(cat,pkg)
		return ebs

a=PortageRepository("/usr/portage-gentoo")
b=PortageRepository("/root/git/funtoo-overlay",overlay=True)
a.children=[b]
print a.categories
print a.packages("sys-apps","portage")
print a.packages("sys-apps","portage",recurse=False)

