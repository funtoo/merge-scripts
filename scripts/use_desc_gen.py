#!/usr/bin/env python
# Written by Alec Warner for the Gentoo Foundation 2008
# This code is hereby placed into the public domain.

"""Craws an ebuild repository for local use flags and generates documentation.

This module attempts to read metadata.xml files in an ebuild repository and
uses the <flag> xml tags to generate a set of documentation for local USE
flags.

It is a non-goal of this script to validate XML contents.

CAVEATS:
TEXT, <pkg>, <pkg>, TEXT. is difficult to parse into text and requires icky
rules; see _GetTextFromNode for the nasty details.
"""

__author__ = "Alec Warner <antarus@gentoo.org>"

import errno
import logging
import optparse
import os
import re
import sys

from xml.dom import minidom
from xml.parsers import expat

METADATA_XML = 'metadata.xml'


class RepositoryError(Exception):
  """Basic Exception for repository problems."""
  pass


def FindMetadataFiles(repo_path, category_path, output=sys.stdout):
  """Locate metadata files in repo_path.

  Args:
    repo_path: path to repository.
    category_path: path to a category file (None is ok).
    output: file-like object to write output to.
  Returns:
    Nothing.
  Raises; RepositoryError.
  """

  profile_path = os.path.join(repo_path, 'profiles')
  logging.info('path to profile is: %s' % profile_path)
  categories = GetCategories(profile_path, category_path)
  packages = []
  for cat in categories:
    cat_path = os.path.join(repo_path, cat)
    logging.debug('path to category %s is %s' % (cat, cat_path))
    try:
      tmp_pkgs = GetPackages(cat_path)
    except OSError, e:
      if e.errno == errno.ENOENT:
        logging.error('skipping %s because it was not in %s' % (cat,
                                                                repo_path))
    pkg_paths = [os.path.join(cat_path, pkg) for pkg in tmp_pkgs]
    packages.extend(pkg_paths)

  total = len(packages)
  for num, pkg_path in enumerate(packages):
    metadata_path = os.path.join(pkg_path, METADATA_XML)
    logging.info('processing %s (%s/%s)' % (metadata_path, num, total))
    try:
      f = open(metadata_path, 'rb')
    except IOError, e:
      if e.errno == errno.ENOENT:
        logging.error('Time to shoot the maintainer: %s does not contain a metadata.xml!' % (pkg_path))
        continue
      else:
        # remember to re-raise if it's not a missing file
        raise e
    metadata = GetLocalFlagInfoFromMetadataXml(f)
    pkg_split = pkg_path.split('/')
    for k, v in metadata.iteritems():
      try:
        output.write('%s/%s:%s - %s\n' % (pkg_split[-2] ,pkg_split[-1], k, v))
      except UnicodeEncodeError, e:
        logging.error('Unicode found in %s, not generating to output' % (pkg_path))
        continue

def _GetTextFromNode(node):
  """Given an XML node, try to turn all it's children into text.

  Args:
    node: a Node instance.
  Returns:
    some text.

  This function has a few tweaks 'children' and 'base_children' which attempt
  to aid the parser in determining where to insert spaces.  Nodes that have
  no children are 'raw text' nodes that do not need spaces.  Nodes that have
  children are 'complex' nodes (often <pkg> nodes) that usually require a
  trailing space to ensure sane output.

  NOTE: The above comment is now bullocks as the regex handles spacing;  I may
  remove the 'children' crap in a future release but it works for now.

  Strip out \n and \t as they are not valid in use.local.desc.
  """

  if node.nodeValue:
    children = 0
    data = node.nodeValue

    whitespace = re.compile('\s+')
    data = whitespace.sub(' ', data)
    return (data, children)
  else:
    desc = ''
    base_children = 1
    for child in node.childNodes:
      child_desc, children = _GetTextFromNode(child)
      desc += child_desc
    return (desc, base_children)


def GetLocalFlagInfoFromMetadataXml(metadata_file):
  """Determine use.local.desc information from metadata files.

  Args:
    metadata_file: a file-like object holding metadata.xml
  """

  d = {}

  try:
    dom_tree = minidom.parseString(metadata_file.read())
  except expat.ExpatError, e:
    logging.error('%s (in file: %s)' % (e, metadata_file))
    return d

  flag_tags = dom_tree.getElementsByTagName('flag')
  for flag in flag_tags:
    use_flag = flag.getAttribute('name')
    desc, unused_children = _GetTextFromNode(flag)
    desc.strip()
    d[use_flag] = desc

  return d


def GetPackages(cat_path):
  """Return a list of packages for a given category."""

  files = os.listdir(cat_path)
  func = lambda f: f != METADATA_XML and f != 'CVS' and f != '.svn'
  files = filter(func, files)

  return files

def GetCategories(profile_path, categories_path):
  """Return a set of categories for a given repository.

  Args:
    profile_path: path to profiles/ dir of a repository.
  Returns:
    a list of categories.
  Raises: RepositoryError.
  """

  if not categories_path:
    categories_path = os.path.join(profile_path, 'categories')
  try:
    f = open(categories_path, 'rb')
  except (IOError, OSError), e:
    raise RepositoryError('Problem while opening %s: %s' % (
        categories_path, e))
  categories = [cat.strip() for cat in f.readlines()]
  return categories


def GetOpts():
  """Simple Option Parsing."""

  parser = optparse.OptionParser()
  parser.add_option('-r', '--repo_path', help=('path to repository from '
                    'which the documentation will be generated.'))
  parser.add_option('-c', '--category_file', help=('path to a category',
                    'file if repo_path lacks a profile/category file'))

  opts, unused_args = parser.parse_args()

  if not opts.repo_path:
    parser.error('--repo_path is a required option')

  logging.debug('REPO_PATH is %s' % opts.repo_path)

  return (opts, unused_args)


def Main():
  """Main."""
  opts, unused_args = GetOpts()
  FindMetadataFiles(opts.repo_path, opts.category_file)


if __name__ == '__main__':
  Main()
