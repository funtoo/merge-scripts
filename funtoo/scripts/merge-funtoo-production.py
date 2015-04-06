#!/usr/bin/python3

import os
import subprocess
from merge_utils import *

funtoo_staging_r = GitTree("funtoo-staging", "master", "repos@git.funtoo.org:ports/funtoo-staging.git", pull=True)
head = funtoo_staging_r.head()
print(head)
exists = subprocess.getoutput("ssh root@build.funtoo.org '[ -e /home/mirror/funtoo/funtoo-current-next/x86-64bit/corei7/" + head + "/status ] && echo yep || echo nope'") == "yep"
if not exists:
	status, output = subprocess.getstatusoutput("ssh root@build.funtoo.org /root/metro/scripts/ezbuild.sh funtoo-current-next x86-64bit corei7 freshen " + head)
success = subprocess.getoutput("ssh root@build.funtoo.org cat /home/mirror/funtoo/funtoo-current-next/x86-64bit/corei7/" + head + "/status") == "ok"
if not success:
	print("QA build did not complete successfully. Exiting.")

ports_2012 = GitTree("ports-2012", "funtoo.org", "repos@git.funtoo.org:ports-2012.git", root="/var/git/dest-trees/ports-2012", pull=False)

my_steps = [
	GitCheckout("funtoo.org"),
	SyncFromTree(funtoo_staging_r),
	GenCache()
]

ports_2012.run(my_steps)
#ports_2012.gitCommit(message="merged from funtoo-staging", branch="funtoo.org")
ports_2012.gitCommit(message="merged from funtoo-staging", branch=False)

