#!/usr/bin/python3 

import merge_utils

a = open('catpkgs.txt','r')
catpkgs=[]
for x in a.readlines():
    catpkgs.append(x.strip())

print(catpkgs)
funtoo_staging_w = merge_utils.GitTree("funtoo-staging-2017", "master", "repos@localhost:ports/funtoo-staging-2017.git", root="/usr/portage", pull=False)
dep_pkglist = merge_utils.getDependencies(funtoo_staging_w, catpkgs, levels=4)

print(dep_pkglist)

b = open('dep_catpkgs.txt','w')
for p in dep_pkglist:
    b.write(p + "\n")
b.close()
