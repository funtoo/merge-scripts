#!/usr/bin/python3

from merge_utils import *

gentoo_staging = GitTree("gentoo-staging", "master", "repos@git.funtoo.org:ports/gentoo-staging.git", pull=True)
kit_dict = { 'name' : 'xorg-kit', 'branch' : '1.17-prime', 'source': 'gentoo', 'src_branch' : 'a56abf6b7026dae27f9ca30ed4c564a16ca82685', 'date' : '18 Nov 2016'  }
kit_dict['kit'] = kit = GitTree(kit_dict['name'], kit_dict['branch'], "repos@git.funtoo.org:kits/%s.git" % kit_dict['name'], root="/var/git/dest-trees/%s" % kit_dict['name'], pull=True)
x = list(getAllEclasses(ebuild_repo=kit, super_repo=gentoo_staging))
print(x)
print(len(x))
