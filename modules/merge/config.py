#!/usr/bin/python3

import os
import sys
from configparser import ConfigParser


class Configuration:

	def __init__(self, filename=None):
		if filename is None:
			home_dir = os.path.expanduser("~")
			self.config_path = os.path.join(home_dir, ".merge")
		else:
			self.config_path = filename
		if not os.path.exists(self.config_path):
			print("""
Merge scripts now use a configuration file. Create a ~/.merge file with the following format. Note that
while the config file must exist, it may be empty, in which case, the following settings will be used.
These are the production configuration settings, so you will probably want to override most or all of
these.	

[sources]

flora = https://github.com/funtoo/flora
kit-fixups = https://github.com/funtoo/kit-fixups
gentoo-staging = repos@git.funtoo.org:ports/gentoo-staging.git

[destinations]

base_url = https://github.com/funtoo

[branches]

flora = master
kit-fixups = master
meta-repo = master

[work]

source = /var/git/source-trees
destination = /var/git/dest-trees
			""")
			sys.exit(1)

		self.config = ConfigParser()
		self.config.read(self.config_path)

		valids = {
			"sources": [ "flora", "kit-fixups", "gentoo-staging" ],
			"destinations": [ "base_url", "mirror", "indy_url" ],
			"branches": [ "flora", "kit-fixups", "meta-repo" ],
			"work": [ "source", "destination" ]
		}
		for section, my_valids in valids.items():

			if self.config.has_section(section):
				if section == "database":
					continue
				for opt in self.config[section]:
					if opt not in my_valids:
						print("Error: ~/.merge [%s] option %s is invalid." % (section, opt))
						sys.exit(1)

	def get_option(self, section, key, default=None):
		if self.config.has_section(section) and key in self.config[section]:
			my_path = self.config[section][key]
		else:
			my_path = default
		return my_path

	def db_connection(self, dbname):
		return self.get_option("database", dbname)

	@property
	def flora(self):
		return self.get_option("sources", "flora", "ssh://git@code.funtoo.org:7999/co/flora.git")

	@property
	def kit_fixups(self):
		return self.get_option("sources", "kit-fixups", "ssh://git@code.funtoo.org:7999/core/kit-fixups.git")

	@property
	def mirror(self):
		return self.get_option("destinations", "mirror", None)

	@property
	def gentoo_staging(self):
		return self.get_option("sources", "gentoo-staging", "ssh://git@code.funtoo.org:7999/auto/gentoo-staging.git")

	def base_url(self, repo):
		base = self.get_option("destinations", "base_url", "ssh://git@code.funtoo.org:7999/auto/")
		if not base.endswith("/"):
			base += "/"
		if not repo.endswith(".git"):
			repo += ".git"
		return base + repo

	def indy_url(self, repo):
		base = self.get_option("destinations", "indy_url", "ssh://git@code.funtoo.org:7999/indy/")
		if not base.endswith("/"):
			base += "/"
		if not repo.endswith(".git"):
			repo += ".git"
		return base + repo

	def branch(self, key):
		return self.get_option("branches", key, "master")

	@property
	def source_trees(self):
		return self.get_option("work", "source", "/var/git/source-trees")

	@property
	def dest_trees(self):
		return self.get_option("work", "destination", "/var/git/dest-trees")
