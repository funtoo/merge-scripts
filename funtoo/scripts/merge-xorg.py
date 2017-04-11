#!/usr/bin/python3

import os
from merge_utils import *
# gentoo-1.19-snap: 355a7986f9f7c86d1617de98d6bf11906729f108
# gentoo-1.17-snap: Nov 18th, 2016: a56abf6b7026dae27f9ca30ed4c564a16ca82685
branch = "gentoo-1.17-snap"
gentoo_staging_w = GitTree("gentoo-staging", "a56abf6b7026dae27f9ca30ed4c564a16ca82685", "repos@localhost:ports/gentoo-staging.git", root="/var/git/dest-trees/gentoo-staging", pull=False)

# shards are overlays where we collect gentoo's most recent changes. This way, we can merge specific versions rather than always be forced to
# get the latest.

shard_names = [ "xorg-kit" ]
shards = {}
shard_steps = {}

for s in shard_names:
	shards[s] = GitTree( s, branch=branch, url="repos@localhost:kits/%s" % s, root="/var/git/dest-trees/%s" % s, pull=False)
	shard_steps[s] = generateShardSteps(s, gentoo_staging_w, branch=branch)

# This function updates the gentoo-staging tree with all the latest gentoo updates:

def gentoo_staging_update():

	for s in shard_names:
		shards[s].run(shard_steps[s])
		shards[s].gitCommit(message="gentoo updates", branch=branch)

gentoo_staging_update()

# vim: ts=4 sw=4 noet
