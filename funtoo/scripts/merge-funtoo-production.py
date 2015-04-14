#!/usr/bin/python3

import os
import subprocess
from merge_utils import *

host="root@build.host.funtoo.org"
arch_desc="x86-64bit"
subarch="corei7"

def qa_build(host,build,arch_desc,subarch,head,target):
	success = False
	exists = subprocess.getoutput("ssh %s '[ -e /home/mirror/funtoo/%s/%s/%s/" % ( host, build, arch_desc, subarch ) + head + "/status ] && echo yep || echo nope'") == "yep"
	if not exists:
		status, output = subprocess.getstatusoutput("ssh %s /root/metro/scripts/ezbuild.sh %s %s %s %s " % ( host, build, arch_desc, subarch, target ) + head)
	success = subprocess.getoutput("ssh %s cat /home/mirror/funtoo/%s/%s/%s/" % ( host, build, arch_desc, subarch )  + head + "/status") == "ok"
	return success

funtoo_staging_r = GitTree("funtoo-staging", "master", "repos@git.funtoo.org:ports/funtoo-staging.git", pull=True)
head = funtoo_staging_r.head()
print(head)
success = False
if qa_build(host,"funtoo-current-next",arch_desc,subarch,head,"freshen"):
	if qa_build(host,"funtoo-stable-next",arch_desc,subarch,head,"freshen"):
#		if qa_build(host,"funtoo-current-gnome-next",arch_desc,subarch,head,"test"):
		success = True
if not success:
	print("QA builds were not successful.")
	sys.exit(1)

ports_2012 = GitTree("ports-2012", "funtoo.org", "repos@git.funtoo.org:ports-2012.git", root="/var/git/dest-trees/ports-2012", pull=False)

my_steps = [
	GitCheckout("funtoo.org"),
	SyncFromTree(funtoo_staging_r),
	GenCache()
]

ports_2012.run(my_steps)
ports_2012.gitCommit(message="merged from funtoo-staging", branch="funtoo.org")
