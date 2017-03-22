#!/usr/bin/python3

from merge_utils import *

host="root@build.funtoo.org"
arch_desc="x86-64bit"
subarch="intel64-westmere"

funtoo_staging_r = GitTree("funtoo-staging-2017", "master", "repos@localhost:ports/funtoo-staging-2017.git", pull=True)
head = funtoo_staging_r.head()
print(head)
success = True
#if qa_build(host,"funtoo-current-next",arch_desc,subarch,head,"freshen"):
#	if qa_build(host,"funtoo-stable-next",arch_desc,subarch,head,"freshen"):
		#if qa_build(host,"funtoo-current-hardened",arch_desc,subarch,head,"freshen"):
#		success = True
if not success:
	print("QA builds were not successful.")
	sys.exit(1)

ports_2012 = GitTree("ports-2017", "master", "repos@localhost:ports-2017.git", root="/var/git/dest-trees/ports-2017", pull=False)

my_steps = [
	GitCheckout("master"),
	SyncFromTree(funtoo_staging_r, exclude=["metadata/.gitignore"]),
	GenCache(),
	GenUseLocalDesc()
]

ports_2012.run(my_steps)
ports_2012.gitCommit(message="merged from funtoo-staging", branch="master")

# vim: ts=4 sw=4 noet
