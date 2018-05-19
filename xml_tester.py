#!/usr/bin/python3

from merge_utils import *

class Repo:

	root = "/foo/bar"

	def __init__(self, name):
		self.name = name

r = Repo("foo")
k = Repo('mykit')

a = XMLRecorder()
a.xml_record(r, k, "foo-bar/oni")
a.xml_record(r, k, "foo-bar/oni")
print(etree.tostring(a.xml_out))

