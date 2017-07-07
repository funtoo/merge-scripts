#!/usr/bin/env python

import os
import portage
cur_tree="/var/git/dest-trees/xorg-kit"
os.environ['PORTAGE_REPOSITORIES'] = '''
[DEFAULT]
main-repo = gentoo

[gentoo]
location = /var/git/source-trees/funtoo-staging-2017

[xorg-kit]
location = %s
''' % cur_tree

p = portage.portdb
# portage uses cannonical paths here
overlay_path = p.porttrees[-1]
print(overlay_path)
for cp in p.cp_all(trees=[overlay_path]):
	for cpv in p.cp_list(cp, mytree=overlay_path):
		inherited, = p.aux_get(cpv, ['INHERITED'], mytree=overlay_path)
		print('\t'.join([cpv, inherited]))
