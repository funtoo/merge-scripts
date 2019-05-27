#!/usr/bin/python3

import os
from merge.merge_utils import runShell, MergeStep, CreateEbuildFromTemplate, get_catpkg_from_ebuild_path
from glob import glob
from collections import defaultdict
import itertools
import asyncio

class XProtoStepGenerator(MergeStep):

	"""

	This merge step will auto-generate surrogate "stub" ebuilds for a master xproto ebuild. The template
	used for the stub ebuilds can be seen below. The run() method takes advantage of threads to process
	multiple xproto ebuilds concurrently.

	"""
	
	def __init__(self, template_text: str):
		self.template_text = template_text

	def get_pkgs_from_meson(self, master_cpv, fn, prefix="pcs"):

		"""This is a helper method that grabs package names from meson build files in xproto sources.

		It accepts the master_cpv we are processing as an argument, so we can also return it and process the results in a
		more pipeline-oriented fashion. We also accept the arguments ``fn`` -- filename of the meson file, and a prefix
		parameter used to tweak the specific result sets we want to grab from the meson file.
		"""

		capture = False
		
		with open(fn, "r") as f:
			lines = f.readlines()
			for line in lines:
				ls = line.strip()
				if ls.startswith("%s = [" % prefix):
					capture = True
				elif capture is True:
					if ls == "]":
						break
					else:
						ls = ls.lstrip("[").rstrip("],").split(",")
						pkg = ls[0].strip().strip("'")
						ver = ls[1].strip().strip("'")
						yield master_cpv, pkg, ver
	
	async def worker_async(self, meta_pkg_ebuild_path, tree):
		"""
		This is a worker method that will extract an xproto ebuild using the ebuild command, then use the get_pkgs_from_meson
		helper method to grab all package names from meson, and then will return the results.
		:param meta_pkg_ebuild_path: This is the absolute path of the xproto ebuild to process.
		:return: A list of entries from the meson files -- each entry in the list is a tuple containing cpv of our xproto ebuild,
		the meson package name, and the meson version.
		"""

		env = os.environ.copy()
		env['PORTAGE_DEPCACHEDIR'] = '/var/cache/edb/%s-%s-meta' % (tree.name, tree.branch)
		if tree.name != "core-kit":
			env['PORTAGE_REPOSITORIES'] = '''
[DEFAULT]
main-repo = core-kit

[core-kit]
location = %s/core-kit
aliases = gentoo

[%s]
location = %s
		''' % (tree.config.dest_trees, tree.name, tree.root)
		else:
			env['PORTAGE_REPOSITORIES'] = '''
[DEFAULT]
main-repo = core-kit

[core-kit]
location = %s/core-kit
aliases = gentoo
		''' % tree.config.dest_trees

		sdata = meta_pkg_ebuild_path.rstrip(".ebuild").split("/")
		master_cpv = sdata[-3] + "/" + sdata[-1]
		success = await runShell("(cd %s; ebuild %s clean unpack)" % (os.path.dirname(meta_pkg_ebuild_path), os.path.basename(meta_pkg_ebuild_path)), abort_on_failure=False, env=env)
		if not success:
			return defaultdict(set)
		meson_file = os.path.expanduser("~portage/%s/work/xorg*proto-*/meson.build" % master_cpv)
		meson_file = glob(meson_file)
		if len(meson_file) != 1 or not os.path.exists(meson_file[0]):
			print("File not found:", meson_file)
		else:
			meson_file = meson_file[0]
		meta_mappings = defaultdict(set)
		for master_cpv, pkg, ver in itertools.chain(self.get_pkgs_from_meson(master_cpv, meson_file), self.get_pkgs_from_meson(master_cpv, meson_file, "legacy_pcs")):
			meta_mappings[(pkg, ver)].add(master_cpv)
		await runShell("(cd %s; ebuild %s clean)" % (os.path.dirname(meta_pkg_ebuild_path), os.path.basename(meta_pkg_ebuild_path)), abort_on_failure=False, env=env)
		return meta_mappings
		
	async def run(self, tree):

		"""
		This is the main "run" method which will run our main worker methods -- worker_async -- concurrently in a ThreadPoolExecutor.
		We then get the results of the meson extractions, and create new MergeSteps for generating the appropriate ebuilds using
		templates, and run them.
		:return: None
		"""

		env = os.environ.copy()
		env['PORTAGE_DEPCACHEDIR'] = '/var/cache/edb/%s-%s-meta' % (tree.name, tree.branch)
		if tree.name != "core-kit":
			env['PORTAGE_REPOSITORIES'] = '''
		[DEFAULT]
		main-repo = core-kit

		[core-kit]
		location = %s/core-kit
		aliases = gentoo

		[%s]
		location = %s
		''' % (tree.config.dest_trees, tree.name, tree.root)
		else:
			env['PORTAGE_REPOSITORIES'] = '''
		[DEFAULT]
		main-repo = core-kit

		[core-kit]
		location = %s/core-kit
		aliases = gentoo
		''' % tree.config.dest_trees


		all_meta_pkg_ebuilds = list(glob(tree.root + "/x11-base/xorg-proto/xorg-proto-*.ebuild"))
		futures =[
			self.loop.run_in_executor(self.cpu_bound_executor, self.run_async_in_executor, self.worker_async, meta_pkg_ebuild_path, tree)
			for meta_pkg_ebuild_path in all_meta_pkg_ebuilds
		]
		meta_mappings = defaultdict(set)
		for future in asyncio.as_completed(futures):
			new_meta_mappings = await future
			for key, new_set in new_meta_mappings.items():
				meta_mappings[key] |= new_set
		
		for pv_key, all_meta_atoms in meta_mappings.items():
			pkg, ver = pv_key
			all_meta_atoms = sorted(list(all_meta_atoms))
			output_ebuild = tree.root + "/x11-proto/%s/%s-%s.ebuild" % (pkg, pkg, ver)
			output_dir = os.path.dirname(output_ebuild)
			if not os.path.exists(output_dir):
				os.makedirs(output_dir)
			step = CreateEbuildFromTemplate(
				template_text=self.template_text,
				template_params={ "all_meta_atoms" : all_meta_atoms },
				file_subpath = "x11-proto/%s/%s-%s.ebuild" % ( pkg, pkg, ver )
			)
			await step.run(tree)
			self.collector.cpm_logger.record(tree.name, get_catpkg_from_ebuild_path(output_ebuild), is_fixup=True)
