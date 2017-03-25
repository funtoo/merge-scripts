#!/usr/bin/python3

import os
from merge_utils import *
# gentoo-1.19-snap: 355a7986f9f7c86d1617de98d6bf11906729f108
# gentoo-1.17-snap: d422f9aee8cba87a4d8ba8cfc6f49175be38a353
branch = "gentoo-1.17-snap"
gentoo_staging_w = GitTree("gentoo-staging", "d422f9aee8cba87a4d8ba8cfc6f49175be38a353", "repos@localhost:ports/gentoo-staging.git", root="/var/git/dest-trees/gentoo-staging", pull=False)

# shards are overlays where we collect gentoo's most recent changes. This way, we can merge specific versions rather than always be forced to
# get the latest.

shard_names = [ "xorg-kit" ]
shards = {}
shard_steps = {}

for s in shard_names:
	shards[s] = GitTree( s, branch, "repos@localhost:kits/%s" % s, root="/var/git/dest-trees/%s" % s, pull=False)
	shard_steps[s] = generateShardSteps(s, gentoo_staging_w)

# This function updates the gentoo-staging tree with all the latest gentoo updates:

def gentoo_staging_update():

	for s in shard_names:
		shards[s].run(shard_steps[s])
		shards[s].gitCommit(message="gentoo updates", branch=branch)

gentoo_staging_update()

# vim: ts=4 sw=4 noet
