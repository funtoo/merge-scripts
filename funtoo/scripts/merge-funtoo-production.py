#!/usr/bin/python3

import os
import subprocess
from merge_utils import *

def run(cmdargs, env={}):
	print("Running command: %s (env %s) " % ( cmdargs,env ))
	try:
		cmd = subprocess.Popen(cmdargs, env=env)
		exitcode = cmd.wait()
	except KeyboardInterrupt:
		cmd.terminate()
		print("Interrupted via keyboard!")
		return 1
	else:
		if exitcode != 0:
			print("Command exited with return code %s" % exitcode)
			return exitcode
		return 0

funtoo_staging_r = GitTree("funtoo-staging", "master", "repos@git.funtoo.org:ports/funtoo-staging.git", commit=commit, pull=True)
ports_2012 = GitTree("ports-2012", "funtoo.org", "repos@git.funtoo.org:ports-2012.git", root="/var/git/dest-trees/ports-2012", pull=False)

my_steps = [
	GitCheckout("funtoo.org"),
	SyncFromTree(funtoo_staging_r),
	GenCache()
]

retval = run(["/usr/bin/ssh","root@et.host.funtoo.org","/root/metro/scripts/ezbuild.sh","funtoo-current-next","x86-64bit","corei7",funtoo_staging_r.head(), os.environ)

ports_2012.run(my_steps)
ports_2012.gitCommit(message="merged from funtoo-staging", branch="funtoo.org")
