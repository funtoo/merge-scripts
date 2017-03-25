#!/usr/bin/python3

import os
from merge_utils import *
# 4582f593f6c9bc96f1fcb740e7ace44472707c7f
# d422f9aee8cba87a4d8ba8cfc6f49175be38a353
branch = "1.17-gentoo-snap"
gentoo_staging_w = GitTree("gentoo-staging", "4582f593f6c9bc96f1fcb740e7ace44472707c7f", "repos@localhost:ports/gentoo-staging.git", root="/var/git/dest-trees/gentoo-staging", pull=False)

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
