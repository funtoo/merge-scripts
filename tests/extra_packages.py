#!/usr/bin/python3

import os, sys
import unittest
sys.path.insert(0, os.path.normpath(os.path.join(os.path.realpath(__file__), "../modules")))
from merge.merge_utils import get_extra_catpkgs_from_kit_fixups

class MockTree():

	def __init__(self, name, root):
		self.name = name
		self.root = root

class ExtraPackageTest(unittest.TestCase):

	def setUp(self):

		self.fixups = MockTree("kit-fixups", os.path.join(os.getcwd(), "kit-fixups"))

	def test_basic(self):

		extras = get_extra_catpkgs_from_kit_fixups(self.fixups, "foo-kit")
		extras = set(extras)
		self.assertEqual(len(extras),2)
		self.assertIn('sys-apps/foobartronic', extras)
		self.assertIn('sys-apps/funapp', extras)

if __name__ == "__main__":
	unittest.main()
