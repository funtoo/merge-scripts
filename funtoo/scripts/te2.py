#!/usr/bin/python3

import merge_utils
a1 = merge_utils.getDependencies("/usr/portage", ["x11-base/xorg-server"])
print(a1)

