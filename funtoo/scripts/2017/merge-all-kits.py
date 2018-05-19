#!/usr/bin/python3

from merge_utils import *
from datetime import datetime
import json
from collections import defaultdict, OrderedDict
from enum import Enum
import os
from decimal import Decimal
from configparser import ConfigParser

class Configuration:

	def __init__(self):

		self.config_path = os.path.join(os.environ["HOME"], ".merge")
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

meta-repo = https://github.com/funtoo/meta-repo
kits_root = https://github.com/funtoo

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
			"sources": [ "flora", "kit-fixups" ],
			"destinations": [ "meta-repo", "kits-root" ],
			"branches": [ "flora", "kit-fixups", "meta-repo" ],
			"work": [ "source", "destination"]
		}
		for section, my_valids in valids.items():

			if self.config.has_section(section):
				for opt in self.config[section]:
					if opt not in my_valids:
						print("Error: ~/.merge [source] option %s is invalid." % opt)
						sys.exit(1)

	def get_option(self, section, key, default):
		if self.config.has_section(section) and key in self.config[section]:
			my_path = self.config[section][key]
		else:
			my_path = default

	@property
	def flora(self):
		return self.get_option("sources", "flora", "https://github.com/funtoo/flora")

	@property
	def kit_fixups(self):
		return self.get_option("sources", "kit-fixups", "https://github.com/funtoo/kit-fixups")

	@property
	def meta_repo(self):
		return self.get_option("destinations", "meta-repo", "repos@git.funtoo.org:meta-repo.git")

	@property
	def gentoo_staging(self):
		return self.get_option("sources", "gentoo-staging", "repos@git.funtoo.org:ports/gentoo-staging.git")

	@property
	def kits_root(self):
		return self.get_option("destinations", "kits-root", "repos@git.funtoo.org:kits/")

	def branch(self, key):
		return self.get_option("branches", key, "master")

	@property
	def source_trees(self):
		return self.get_option("work", "source", "/var/git/source-trees")

	@property
	def dest_trees(self):
		return self.get_option("work", "source", "/var/git/dest-trees")

config = Configuration()

# KIT DESIGN AND DEVELOPER DOCS

# The maintainable model for kits is to have several source repositories that contain most of our source ebuilds/
# catpkgs, which are identified by SHA1 to point to a specific snapshot. Then, we combine that with a Funtoo 'kit-fixups'
# repository that contains only our forked ebuilds. Then this script, merge-all-kits.py, is used to automatically
# generate the kits. We don't commit directly to kits themselves -- this script automatically generates commits with
# updated ebuilds. 

# A kit is generated from:

# 1. a collection of repositories and SHA1 commit to specify a snapshot of each repository to serve as a source for catpkgs,
#    eclasses, licenses. It is also possible to specify a branch name instead of SHA1 (typically 'master') although this
#    shouldn't ever be done for 'prime' branches of kits.

# 1. a selection of catpkgs (ebuilds) that are selected from source repositories. Each kit has a package-set file located 
#    in ../package-sets/*-kit relative to this file which contains patterns of catpkgs to select from each source 
#    repository and copy into the kit when regenerating it.

# 3. a collection of fix-ups (from the kit-fixups repository) that can be used to replace catpkgs in various kits globally,
#    or in a specific branch of a kit. There is also an option to provide eclasses that get copied globally to each kit,
#    to a particular kit, or to a branch of a particular kit. This is the where we fork ebuilds to fix specific issues.

# Below, the kits and branches should be defined in a way that includes all this information. It is also possible to
# have a kit that simply is a collection of ebuilds but tracks the latest gentoo-staging. It may or may not have
# additional fix-ups.

# When setting up a kit repository, the 'master' branch may used to store an 'unfrozen' kit that just tracks upstream
# Gentoo. Kits are not required to have a master branch -- we only create one if the kit is designed to offer unfrozen
# ebuilds to Funtoo users.	Examples below are: science-kit, games-kit, text-kit, net-kit. These track gentoo.

# If we have a frozen enterprise branch that we are backporting security fixes to only, we want this to be an
# 'x.y-prime' branch. This branch's overlays' source SHA1s are not supposed to change and we will just augment it with
# fix-ups as needed.

# As kits are maintained, the following things may change:
#
# 1. The package-set files may change. This can result in different packages being selected for the kit the next time it
#	 is regenerated by this script. We can add mising packages, decide to move packages to other kits, etc. This script
#	 takes care of ensuring that all necessary eclasses and licenses are included when the kit is regenerated.
#
# 2. The fix-ups may change. This allows us to choose to 'fork' various ebuilds that we may need to fix, while keeping
#	 our changes separate from the source packages. We can also choose to unfork packages.
#
# 3. Kits can be added or removed.
#
# 4. Kit branches can be created, or alternatively deprecated. We need a system for gracefully deprecating a kit that does
#	 not involve deleting the branch. A user may decide to continue using the branch even if it has been deprecated.
#
# 5. Kits can be tagged by Funtoo as being mandatory or optional. Typically, most kits will be mandatory but some effort
#	 will be made as we progress to make things like the games-kit or the science-kit optional.
#
# HOW KITS ARE GENERATED

# Currently, kits are regenerated in a particluar order, such as: "first, core-kit, then security-kit, then perl-kit",
# etc. This script keeps a running list of catpkgs that are inserted into each kit. Once a catpkg is inserted into a
# kit, it is not available to be inserted into successive kits. This design is intended to prevent multiple copies of
# catpkgs existing in multiple kits in parallel that are designed to work together as a set. At the end of kit
# generation, this master list of inserted catpkgs is used to prune the 'nokit' repository of catpkgs, so that 'nokit'
# contains the set of all ebuilds that were not inserted into kits.

# Below, you will see how the sources for kits are defined.

# 1. OVERLAYS - lists sources for catpkgs, along with properties which can include "select" - a list of catpkgs to
# include.  When "select" is specified, only these catpkgs will be available for selection by the package-set rules. .
# If no "select" is specified, then by default all available catpkgs could be included, if they match patterns, etc. in
# package-sets. Note that we do not specify branch or SHA1 here. This may vary based on kit, so it's specified elsewhere
# (see KIT SOURCES, below.)

overlays = {
	# use gentoo-staging-2017 dirname to avoid conflicts with ports-2012 generation
	"gentoo-staging" : { "type" : GitTree, "url" : config.gentoo_staging, "dirname" : "gentoo-staging-2017" },
	"gentoo-staging-underlay": {"type": GitTree, "url": config.gentoo_staging,
	                   "dirname": "gentoo-staging-2017-underlay"},
	"faustoo" : { "type" : GitTree, "url" : "https://github.com/fmoro/faustoo.git", "eclasses" : [
		"waf",
		"googlecode"
		],
	     # SKIP any catpkgs that also exist in gentoo-staging (like nvidia-drivers). All others will be copied.
	    "filter" :  [ "gentoo-staging" ],
	    # well, I lied. There are some catpkgs that exist in gentoo-staging that we DO want to copy. These are the
		# ones we will copy. We need to specify each one. This list may change over time as faustoo/gentoo gets stale.
	    "force" : [
		    "dev-java/maven-bin",
		    "dev-java/sun-java3d-bin",
		    "dev-php/pecl-mongo",
		    "dev-php/pecl-mongodb",
		    "dev-python/mongoengine",
		    "dev-python/pymongo",
		    "dev-util/idea-community",
		    "dev-util/webstorm",
		    "x11-wm/blackbox"
	    ]
	},
	"fusion809" : { "type" : GitTree, "url" : "https://github.com/fusion809/fusion809-overlay.git", "select" : [
			"app-editors/atom-bin", 
			"app-editors/notepadqq", 
			"app-editors/bluefish", 
			"app-editors/textadept", 
			"app-editors/scite", 
			"app-editors/gvim", 
			"app-editors/vim", 
			"app-editors/vim-core",
			"app-editors/sublime-text"
		]
	}, # FL-3633, FL-3663, FL-3776
	"plex" : { "type" : GitTree, "url" : "https://github.com/Ghent/funtoo-plex.git", "select" : [
			"media-tv/plex-media-server",
		],
	},
	# Ryan Harris glassfish overlay. FL-3985:
	"rh1" : { "type" : GitTree, "url" : "https://github.com/x48rph/glassfish.git", "select" : [
			"www-servers/glassfish-bin",
		],
	},
	# damex's deadbeef (music player like foobar2000) overlay
	"deadbeef" : { "type" : GitTree, "url" : "https://github.com/damex/deadbeef-overlay.git", "copyfiles" : {
			"profiles/package.mask": "profiles/package.mask/deadbeef.mask"
		},
	},
	# damex's wmfs (window manager from scratch) overlay
	"wmfs" : { "type" : GitTree, "url" : "https://github.com/damex/wmfs-overlay.git", "copyfiles" : {
			"profiles/package.mask": "profiles/package.mask/wmfs.mask" 
		},
	},
	"flora" : { "type" : GitTree, "url" : config.flora, "copyfiles" : {
			"licenses/renoise-EULA": "licenses/renoise-EULA"
		},
	},
}

# SUPPLEMENTAL REPOSITORIES: These are overlays that we are using but are not in KIT SOURCES. merge_scripts is something
# we are using only for profiles and other misc. things and may get phased out in the future:

merge_scripts = GitTree("merge-scripts", "master", "git@github.com:funtoo/merge-scripts.git")
fixup_repo = GitTree("kit-fixups", config.branch("kit-fixups"), config.kit_fixups)

# OUTPUT META-REPO: This is the master repository being written to.

meta_repo = GitTree("meta-repo", config.branch("meta-repo"), config.meta_repo, root=config.dest_trees+"/meta-repo")

# 2. KIT SOURCES - kit sources are a combination of overlays, arranged in a python list [ ]. A KIT SOURCE serves as a
# unified collection of source catpkgs for a particular kit. Each kit can have one KIT SOURCE. KIT SOURCEs MAY be
# shared among kits to avoid duplication and to help organization. Note that this is where we specify branch or SHA1
# for each overlay.

# Each kit source can be used as a source of catpkgs for a kit. Order is important -- package-set rules are applied in
# the same order that the overlay appears in the kit_source_defs list -- so for "funtoo_current", package-set rules will
# be applied to gentoo-staging first, then flora, then faustoo, then fusion809. Once a particular catpkg matches and is
# copied into a dest-kit, a matching capkg in a later overlay, if one exists, will be ignored.

# It is important to note that we support two kinds of kit sources -- the first is the gentoo-staging master repository
# which contains a master set of eclasses and contains everything it needs for all the catpkgs it contains. The second
# kind of repository we support is an overlay that is designed to be used with the gentoo-staging overlay, so it may
# need some catpkgs (as dependencies) or eclasses from gentoo-staging. The gentoo-staging repository should always
# appear as the first item in kit_source_defs, with the overlays appearing after.

kit_source_defs = {
	"funtoo_current" : [
		# allow overlays to override gentoo
		{ "repo" : "flora" },
		{ "repo" : "faustoo" },
		{ "repo" : "fusion809" },
		{ "repo" : "rh1" },
		{ "repo" : "gentoo-staging" }
	],
	"funtoo_mk2_prime" : [
		# allow overlays to override gentoo
		{ "repo" : "flora", },
		{ "repo" : "faustoo" },
		{ "repo" : "fusion809", "src_sha1" : "489b46557d306e93e6dc58c11e7c1da52abd34b0", 'date' : '31 Aug 2017' },
		{ "repo" : "rh1", },
		{ "repo" : "gentoo-staging", "src_sha1" : '80d2f3782e7f351855664919d679e94a95793a06', 'date' : '31 Aug 2017'},
		# add current gentoo-staging to catch any new ebuilds that are not yet in our snapshot above (dev-foo/* match)
		{ "repo" : "gentoo-staging-underlay" },
	],
	"funtoo_mk3_prime" : [
		# allow overlays to override gentoo
		{ "repo" : "flora", },
		{ "repo" : "faustoo", },
		{ "repo" : "fusion809", "src_sha1" : "8733034816d3932486cb593db2dfbfbc7577e28b", 'date' : '09 Oct 2017' },
		{ "repo" : "rh1", },
		{ "repo" : "gentoo-staging", "src_sha1" : '2de4b388863ab0dbbd291422aa556c9de646f1ff', 'date' : '10 Oct 2017'},
		{ "repo" : "gentoo-staging-underlay" },
	],
	"funtoo_mk3_late_prime": [
		# allow overlays to override gentoo
		{"repo": "flora", },
		{"repo": "faustoo", },
		{"repo": "fusion809", "src_sha1": "574f9f6f69b30f4eec7aa2eb53f55059d3c05b6a", 'date': '23 Oct 2017'},
		{"repo": "rh1", },
		{"repo": "gentoo-staging", "src_sha1": 'aa03020139bc129af2ad5f454640c102afa712e6', 'date': '22 Oct 2017'},
		{"repo": "gentoo-staging-underlay" },
	],

	"funtoo_mk4_prime": [
		# allow overlays to override gentoo
		{"repo": "flora", },
		{"repo": "faustoo", },
		{"repo": "fusion809", "src_sha1": "574f9f6f69b30f4eec7aa2eb53f55059d3c05b6a", 'date': '23 Oct 2017'},
		{"repo": "rh1", },
		{"repo": "gentoo-staging", "src_sha1": 'bb740efd8e9667dc19f162e936c5c876fb716b5c', 'date': '19 Jan 2018'},
		{"repo": "gentoo-staging-underlay" },
	],

	"funtoo_prime" : [
		# allow overlays to override gentoo
		{ "repo" : "flora", },
		{ "repo" : "faustoo", },
		{ "repo" : "fusion809", "src_sha1" : "8322bcd79d47ef81f7417c324a1a2b4772020985" },
		{ "repo" : "rh1", },
		{ "repo" : "gentoo-staging", "src_sha1" : '06a1fd99a3ce1dd33724e11ae9f81c5d0364985e', 'date' : '21 Apr 2017'},
		{ "repo" : "gentoo-staging-underlay" },
	],
	"gentoo_prime_mk3_protected" : [
		# lock down core-kit and security-kit
		{ "repo" : "gentoo-staging", "src_sha1" : '2de4b388863ab0dbbd291422aa556c9de646f1ff', 'date' : '10 Oct 2017'},
	],
	"gentoo_prime_mk4_protected" : [
		# lock down core-kit and security-kit
		{ "repo" : "gentoo-staging", "src_sha1" : '887b32c487432a9206208fc42a313e9e0517bf2b', 'date' : '8 Jan 2018'},
	],
	"gentoo_prime_protected" : [
		# lock down core-kit and security-kit
		{ "repo" : "gentoo-staging", "src_sha1" : '06a1fd99a3ce1dd33724e11ae9f81c5d0364985e', 'date' : '21 Apr 2017'},
	],
	"gentoo_current_protected" : [
		# lock down core-kit and security-kit
		{ "repo" : "gentoo-staging" },
	],
	"funtoo_prime_xorg" : [
		# specific snapshot for xorg-kit
		{ "repo" : "gentoo-staging", 'src_sha1' : 'a56abf6b7026dae27f9ca30ed4c564a16ca82685', 'date' : '18 Nov 2016' }
	],
	"funtoo_prime_gnome" : [
		# specific snapshot for gnome-kit
		{ "repo" : "gentoo-staging", 'src_sha1' : '44677858bd088805aa59fd56610ea4fb703a2fcd', 'date' : '18 Sep 2016' }
	],
	"funtoo_prime_media" : [
		# specific snapshot for media-kit, though we should bump and expand this soon
		{ "repo" : "gentoo-staging", 'src_sha1' : '355a7986f9f7c86d1617de98d6bf11906729f108', 'date' : '25 Feb 2017' }
	],
	"funtoo_prime_perl" : [
		# specific snapshot for perl-kit
		{ "repo" : "gentoo-staging", 'src_sha1' : 'fc74d3206fa20caa19b7703aa051ff6de95d5588', 'date' : '11 Jan 2017' }
	],
	"funtoo_prime_kde" : [
		# specific snapshot for kde-kit
		{ "repo" : "gentoo-staging", 'src_sha1' : '1a0337dbb94be980733eeb9d9661da58cffd4e59', 'date' : '28 Jan 2018' }
	],
	"funtoo_prime_kde_late" : [
		# specific snapshot for kde-kit
		{ "repo" : "gentoo-staging", 'src_sha1' : '4d219563cd80de1a9a0ebb7c2718d8639415cc07', 'date' : '10 Mar 2018' }
	],
	"funtoo_prime_llvm" : [
		# specific snapshot for llvm-kit
		{ "repo" : "gentoo-staging", 'src_sha1' : 'e4d303da8b2ad31692eddba258ef28b69fec3efb', 'date' : '20 Mar 2018' }
	]
}

# 2. KIT GROUPS - this is where kits are actually defined. They are organized by GROUP: 'prime', 'current', or 'shared'.
# 'prime' kits are production-quality kits. Current kits are bleeding-edge kits. 'shared' kits are used by both 'prime'
# and 'current' -- they can have some "prime" kits as well as some "current" kits depending on what we want to stabilize.
# Note that we specify a 'source' which points to a name of a kit_source to use as a source of ebuilds. A kit is defined
# by a GROUP such as 'prime', a NAME, such as 'core-kit', a BRANCH, such as '1.0-prime', and a source (kit source) such
# as 'funtoo_prime'.

class KitStabilityRating(Enum):
	PRIME = 0               # Kit is enterprise-quality
	NEAR_PRIME = 1          # Kit is approaching enterprise-quality
	BETA = 2                # Kit is in beta
	ALPHA = 3               # Kit is in alpha
	DEV = 4                 # Kit is newly created and in active development
	CURRENT = 10            # Kit follows Gentoo currrent
	DEPRECATED = 11         # Kit is deprecated/retired

def KitRatingString(kit_enum):
	if kit_enum is KitStabilityRating.PRIME:
		return "prime"
	elif kit_enum is KitStabilityRating.NEAR_PRIME:
		return "near-prime"
	elif kit_enum is KitStabilityRating.BETA:
		return "beta"
	elif kit_enum is KitStabilityRating.ALPHA:
		return "alpha"
	elif kit_enum is KitStabilityRating.DEV:
		return "dev"
	elif kit_enum is KitStabilityRating.CURRENT:
		return "current"
	elif kit_enum is KitStabilityRating.DEPRECATED:
		return "deprecated"

# Next release is 1.2-prime and will be based on a 'master' snapshot until it is near release, at which point the
# tree will be frozen.

# 1.2 RELEASE
# =================================================================================
#
# Roadmap (compressed development schedule)
#
# 1. Development starts                                                            December 28, 2017
# 1a. Addition of python-modules-kit and perl-modules-kit (for 1.1+)               January 1, 2018
# 2. Alpha release (best attempt to get everything functioning)                    January 4, 2018
# 3. Beta release (most stuff should be functioning and becoming stable)           January 11, 2018
# 4. Near-prime (release candidate)                                                To be determined
# 5. Prime release                                                                 January 21, 2018
# 6. 1.0-prime kits EOL                                                            February 1, 2018
#
# 1.3 development starts                                                           April 1, 2018
# 1.3 release                                                                      July 1, 2018
# 1.2-prime kits EOL                                                               August 1, 2018
#
#							NEW VERSION             EXISTING
#                           =======================================================
# core-kit                  1.2-prime
# security-kit              1.2-prime
# xorg-kit                                          1.19-prime
# gnome-kit                 3.26-prime              3.20-prime (also supported)
# kde-kit                                           5.10-prime
# media-kit                 1.2-prime
# perl-kit                                          5.26-prime
# > perl-modules-kit        1.2-prime
# python-kit                3.6-prime
# > python-modules-kit      1.2-prime
# php-kit                                           master
# java-kit                  1.2-prime
# ruby-kit                  1.2-prime
# haskell-kit               1.2-prime
# ml-lang-kit               1.2-prime
# lisp-scheme-kit           1.2-prime
# lang-kit                  1.2-prime
# llvm-kit                  1.2-prime
# dev-kit                   1.2-prime
# xfce-kit                                          4.12-prime
# desktop-kit               1.2-prime
# editors-kit                                       master
# net-kit                   1.2-prime
# text-kit                                          master
# science-kit                                       master
# games-kit                                         master
# nokit                                             master

kit_groups = {
	'prime' : [
		{ 'name' : 'core-kit', 'branch' : '1.0-prime', 'source': 'gentoo_prime_protected', 'default' : True },
		{ 'name' : 'core-kit', 'branch' : '1.1-prime', 'source': 'gentoo_prime_mk3_protected', 'stability' : KitStabilityRating.DEPRECATED },
		{ 'name' : 'core-kit', 'branch': '1.2-prime', 'source': 'gentoo_prime_mk4_protected', 'stability': KitStabilityRating.BETA },
		{ 'name' : 'core-hw-kit', 'branch' : 'master', 'source': 'funtoo_current', 'default' : True },
		{ 'name' : 'security-kit', 'branch' : '1.0-prime', 'source': 'gentoo_prime_protected', 'default' : True },
		{ 'name' : 'security-kit', 'branch' : '1.1-prime', 'source': 'gentoo_prime_mk3_protected', 'stability' : KitStabilityRating.DEPRECATED },
		{ 'name' : 'security-kit', 'branch': '1.2-prime', 'source': 'gentoo_prime_mk4_protected', 'stability': KitStabilityRating.BETA },
		{ 'name' : 'xorg-kit', 'branch' : '1.17-prime', 'source': 'funtoo_prime_xorg', 'default' : False, 'stability' : KitStabilityRating.PRIME },
		{ 'name' : 'xorg-kit', 'branch' : '1.19-prime', 'source': 'funtoo_mk2_prime', 'default' : True, 'stability' : KitStabilityRating.PRIME  }, # MK2
		{ 'name' : 'gnome-kit', 'branch' : '3.20-prime', 'source': 'funtoo_prime_gnome', 'default' : True },
		{ 'name' : 'gnome-kit', 'branch': '3.26-prime', 'source': 'funtoo_mk4_prime', 'default': False, 'stability' : KitStabilityRating.DEV },
		{ 'name' : 'kde-kit', 'branch' : '5.10-prime', 'source': 'funtoo_mk3_prime', 'default' : False, 'stability' : KitStabilityRating.DEPRECATED  },
		{ 'name' : 'kde-kit', 'branch' : '5.11-prime', 'source': 'funtoo_prime_kde', 'stability' : KitStabilityRating.DEPRECATED },
		{ 'name' : 'kde-kit', 'branch' : '5.12-prime', 'source': 'funtoo_prime_kde_late', 'default' : True, 'stability' : KitStabilityRating.PRIME },
		{ 'name' : 'media-kit', 'branch' : '1.0-prime', 'source': 'funtoo_prime_media', 'default' : False, 'stability' : KitStabilityRating.DEPRECATED },
		{ 'name' : 'media-kit', 'branch' : '1.1-prime', 'source': 'funtoo_mk3_prime', 'default' : True, 'stability' : KitStabilityRating.PRIME }, # MK3
		{ 'name' : 'media-kit', 'branch' : '1.2-prime', 'source': 'funtoo_mk4_prime', 'stability': KitStabilityRating.BETA},
		{ 'name' : 'perl-kit', 'branch' : '5.24-prime', 'source': 'funtoo_prime_perl', 'default' : True },
		{ 'name' : 'perl-kit', 'branch' : '5.26-prime', 'source': 'funtoo_mk3_prime', 'default' : False, 'stability' : KitStabilityRating.DEV },
		{ 'name' : 'python-modules-kit', 'branch': 'master', 'source': 'funtoo_current', 'default': True, 'stability' : KitStabilityRating.PRIME },
		{ 'name' : 'python-kit', 'branch' : '3.4-prime', 'source': 'funtoo_prime', 'default' : True },
		{ 'name' : 'python-kit', 'branch' : '3.6-prime', 'source': 'funtoo_mk2_prime', 'default' : False, 'stability' : KitStabilityRating.PRIME }, # MK2
		{ 'name' : 'python-kit', 'branch' : '3.6.3-prime', 'source': 'funtoo_mk3_prime', 'default': False, 'stability' : KitStabilityRating.DEPRECATED }, # MK3
		{ 'name' : 'php-kit', 'branch' : 'master', 'source': 'funtoo_current', 'default' : True }, # We will freeze when 7.2.0 is released...
		{ 'name' : 'java-kit', 'branch' : '1.1-prime', 'source': 'funtoo_mk3_late_prime', 'default' : True  },
		{ 'name' : 'java-kit', 'branch': '1.2-prime', 'source': 'funtoo_mk4_prime', 'stability': KitStabilityRating.BETA},
		{ 'name' : 'ruby-kit', 'branch': '1.1-prime', 'source': 'funtoo_mk3_late_prime', 'default': True},
		{ 'name' : 'ruby-kit', 'branch': '1.2-prime', 'source': 'funtoo_mk4_prime', 'stability': KitStabilityRating.BETA},
		{ 'name' : 'haskell-kit', 'branch': '1.1-prime', 'source': 'funtoo_mk3_late_prime', 'default': True },
		{ 'name' : 'haskell-kit', 'branch': '1.2-prime', 'source': 'funtoo_mk4_prime', 'stability': KitStabilityRating.BETA},
		{ 'name' : 'ml-lang-kit', 'branch': '1.1-prime', 'source': 'funtoo_mk3_late_prime', 'default' : False, 'stability' : KitStabilityRating.DEPRECATED },
		{ 'name' : 'ml-lang-kit', 'branch': '1.2-prime', 'source': 'funtoo_mk4_prime', 'default' : True, 'stability' : KitStabilityRating.PRIME },
		{ 'name' : 'lisp-scheme-kit', 'branch': '1.1-prime', 'source': 'funtoo_mk3_late_prime', 'default': True },
		{ 'name' : 'lisp-scheme-kit', 'branch': '1.2-prime', 'source': 'funtoo_mk4_prime', 'stability': KitStabilityRating.BETA},
		{ 'name' : 'lang-kit', 'branch': '1.1-prime', 'source': 'funtoo_mk3_late_prime', 'default': True },
		{ 'name' : 'lang-kit', 'branch': '1.2-prime', 'source': 'funtoo_mk4_prime', 'stability': KitStabilityRating.BETA},
		{ 'name' : 'llvm-kit', 'branch': '1.2-prime', 'source': 'funtoo_prime_llvm', 'default' : True, 'stability': KitStabilityRating.PRIME},
		{ 'name' : 'dev-kit', 'branch' : '1.1-prime', 'source': 'funtoo_mk3_late_prime', 'default' : True },
		{ 'name' : 'dev-kit', 'branch': '1.2-prime', 'source': 'funtoo_mk4_prime', 'stability': KitStabilityRating.BETA},
		{ 'name' : 'xfce-kit', 'branch': '4.12-prime', 'source': 'funtoo_mk3_late_prime', 'default': True },
		{ 'name' : 'desktop-kit', 'branch' : '1.1-prime', 'source': 'funtoo_mk3_late_prime', 'default' : True  },
		{ 'name' : 'desktop-kit', 'branch': '1.2-prime', 'source': 'funtoo_mk4_prime', 'stability': KitStabilityRating.BETA},
		{ 'name' : 'editors-kit', 'branch' : 'master', 'source': 'funtoo_current', 'default' : True },
		{ 'name' : 'net-kit', 'branch' : 'master', 'source': 'funtoo_current', 'default' : True },
		{ 'name' : 'text-kit', 'branch' : 'master', 'source': 'funtoo_current', 'default' : True },
		{ 'name' : 'science-kit', 'branch' : 'master', 'source': 'funtoo_current', 'default' : True },
		{ 'name' : 'games-kit', 'branch' : 'master', 'source': 'funtoo_current', 'default' : True },
		{ 'name' : 'nokit', 'branch' : 'master', 'source': 'funtoo_current', 'default' : True }
	]
}



python_kit_settings = {
	#	branch / primary python / alternate python / python mask (if any)
	'master' :  { 
		"primary" : "python3_6", 
		"alternate" : "python2_7",
		"mask" : None
	},
	'3.4-prime' : {
		"primary" : "python3_4",
		"alternate" : "python2_7",
		"mask" : ">=dev-lang/python-3.5"
	},
	'3.6-prime' : { 
		"primary" : "python3_6",
		"alternate" : "python2_7",
		"mask" : ">=dev-lang/python-3.7"
	},
	'3.6.3-prime' : { 
		"primary" : "python3_6",
		"alternate" : "python2_7",
		"mask" : ">=dev-lang/python-3.7"
	}
}

# It has already been explained how when we apply package-set rules, we process the kit_source repositories in order and
# after we find a catpkg that matches, any matches in successive repositories for catpkgs that we have already copied
# over to the destination kit are *ignored*. This is implemented using a dictionary called "kitted_catpkgs".  Once a
# catpkg is inserted into a kit, it's no longer 'available' to be inserted into successive kits, to avoid duplicates.

kit_order = [ 'prime' ]

# We want to reset 'kitted_catpkgs' at certain points. The 'kit_order' variable below is used to control this, and we
# normally don't need to touch it. 'kitted_order' above tells the code to generate 'prime', then 'shared' (without
# resetting kitted_catpkgs to empty), then the None tells the code to reset kitted_catpkgs, so when 'current' kits are
# generated, they can include from all possible catpkgs. This is done because prime+shared is designed to be our
# primary enterprise-set of Funtoo kits. current+shared is also supported as a more bleeding edge option.

# 3. KIT PREP STEPS. To rebuild kits from scratch, we need to perform some initial actions to initialize an empty git
# repository, as well as some final actions. In the kit_steps dictionary below, indexed by kit, 'pre' dict lists the
# initial actions, and 'post' lists the final actions for the kit. There is also a special top-level key called
# 'regular-kits'. These actions are appended to any kit that is not core-kit or nokit. In addition to 'pre' and 'post'
# steps, there is also a 'copy' step that is not currently used (but is supported by getKitPrepSteps()).

def getKitPrepSteps(repos, kit_dict, gentoo_staging, fixup_repo):

	kit_steps = {
		'core-kit' : { 'pre' : [
				GenerateRepoMetadata("core-kit", aliases=["gentoo"], priority=1000),
				# core-kit has special logic for eclasses -- we want all of them, so that third-party overlays can reference the full set.
				# All other kits use alternate logic (not in kit_steps) to only grab the eclasses they actually use.
				SyncDir(gentoo_staging.root, "eclass"),
							],
			'post' : [
				# We copy files into funtoo's profile structure as post-steps because we rely on kit-fixups step to get the initial structure into place
				CopyAndRename("profiles/funtoo/1.0/linux-gnu/arch/x86-64bit/subarch", "profiles/funtoo/1.0/linux-gnu/arch/pure64/subarch", lambda x: os.path.basename(x) + "-pure64"),
				# news items are not included here anymore
				SyncDir(fixup_repo.root, "metadata", exclude=["cache","md5-cache","layout.conf"]),
				# add funtoo stuff to thirdpartymirrors
				ThirdPartyMirrors(),
				RunSed(["profiles/base/make.defaults"], ["/^PYTHON_TARGETS=/d", "/^PYTHON_SINGLE_TARGET=/d"]),
			]
		},
		# masters of core-kit for regular kits and nokit ensure that masking settings set in core-kit for catpkgs in other kits are applied
		# to the other kits. Without this, mask settings in core-kit apply to core-kit only.
		'regular-kits' : { 'pre' : [
				GenerateRepoMetadata(kit_dict['name'], masters=[ "core-kit" ], priority=500),
			]
		},
		'all-kits' : { 'pre' : [
				SyncFiles(fixup_repo.root, {
						"COPYRIGHT.txt":"COPYRIGHT.txt",
						"LICENSE.txt":"LICENSE.txt",
					}),
			]
		},
		'nokit' : { 'pre' : [
				GenerateRepoMetadata("nokit", masters=[ "core-kit" ], priority=-2000),
			]
		}
	}

	out_pre_steps = []
	out_copy_steps = []
	out_post_steps = []

	kd = kit_dict['name']
	if kd in kit_steps:
		if 'pre' in kit_steps[kd]:
			out_pre_steps += kit_steps[kd]['pre']
		if 'post' in kit_steps[kd]:
			out_post_steps += kit_steps[kd]['post']
		if 'copy' in kit_steps[kd]:
			out_copy_steps += kit_steps[kd]['copy']

	# a 'regular kit' is not core-kit or nokit -- if we have pre or post steps for them, append these steps:
	if kit_dict['name'] not in [ 'core-kit', 'nokit' ] and 'regular-kits' in kit_steps:
		if 'pre' in kit_steps['regular-kits']:
			out_pre_steps += kit_steps['regular-kits']['pre']
		if 'post' in kit_steps['regular-kits']:
			out_post_steps += kit_steps['regular-kits']['post']

	if 'all-kits' in kit_steps:
		if 'pre' in kit_steps['all-kits']:
			out_pre_steps += kit_steps['all-kits']['pre']
		if 'post' in kit_steps['all-kits']:
			out_post_steps += kit_steps['all-kits']['post']

	return ( out_pre_steps, out_copy_steps, out_post_steps )

# GET KIT SOURCE INSTANCE. This function returns a list of GitTree objects for each of repositories specified for
# a particular kit's kit_source, in the order that they should be processed (in the order they are defined in
# kit_source_defs, in other words.)

def getKitSourceInstance(kit_dict):

	global kit_source_defs
	
	source_name = kit_dict['source']

	repos = []

	source_defs = kit_source_defs[source_name]

	for source_def in source_defs:

		repo_name = source_def['repo']
		repo_branch = source_def['src_branch'] if "src_branch" in source_def else "master"
		repo_sha1 = source_def["src_sha1"] if "src_sha1" in source_def else None
		repo_obj = overlays[repo_name]["type"]
		repo_url = overlays[repo_name]["url"]
		if "dirname" in overlays[repo_name]:
			path = overlays[repo_name]["dirname"]
		else:
			path = repo_name
		repo = repo_obj(repo_name, url=repo_url, root="%s/%s" % (config.source_trees, path), branch=repo_branch, commit_sha1=repo_sha1)
		repos.append( { "name" : repo_name, "repo" : repo, "overlay_def" : overlays[repo_name] } )

	return repos

# UPDATE KIT. This function does the heavy lifting of taking a kit specification included in a kit_dict, and
# regenerating it. The kitted_catpkgs argument is a dictionary which is also written to and used to keep track of
# catpkgs copied between runs of updateKit.

def updateKit(kit_dict, prev_kit_dict, kit_group, cpm_logger, db=None, create=False, push=False, now=None, fixup_repo=None):

	# secondary_kit means: we're the second (or third, etc.) xorg-kit or other kit to be processed. The first kind of
	# each kit processed has secondary_kit = False, and later ones have secondary_kit = True. We need special processing
	# to grab any 'orphan' packages that were selected as part of prior kit scans (and thus will not be included in
	# later kits) but were not picked up in our current kit-scan. For example, let's say @depsincat@:virtual/ttf-fonts:
	# media-fonts picks up a funky font in the first xorg-kit scan, but in the second xorg-kit scan, the deps have
	# changed and thus this font isn't selected. Well without special handling, if we are using the second (or later)
	# xorg-kit, funky-font won't exist. We call these guys 'orphans' and need to ensure we include them.

	secondary_kit = False
	if prev_kit_dict != None:
		if kit_dict['name'] != prev_kit_dict['name']:
		
			# We are advancing to the next kit. For example, we just processed an xorg-kit and are now processing a python-kit. So we want to apply all our accumulated matches.
			# If we are processing an xorg-kit again, this won't run, which is what we want. We want to keep accumulating catpkg names/matches.

			cpm_logger.nextKit()

		else:
			secondary_kit = True
	print("Processing kit %s branch %s, secondary kit is %s" % ( kit_dict['name'], kit_dict['branch'], repr(secondary_kit)))

	# get set of source repos used to grab catpkgs from:

	repos = kit_dict["repo_obj"] = getKitSourceInstance(kit_dict)

	# get a handy variable reference to gentoo_staging:
	gentoo_staging = None
	for x in repos:
		if x["name"] == "gentoo-staging":
			gentoo_staging = x["repo"]
			break

	if gentoo_staging == None:
		print("Couldn't find source gentoo staging repo")
	elif gentoo_staging.name != "gentoo-staging":
		print("Gentoo staging mismatch -- name is %s" % gentoo_staging["name"])

	kit_path = config.kits_root
	if not kit_path.endswith("/"):
		kit_path += "/"
	kit_dict['tree'] = tree = GitTree(kit_dict['name'], kit_dict['branch'],
	                                  kit_path + kit_dict['name'], create=create,
	                                  root="%s/%s" % (config.dest_trees, kit_dict['name']), pull=True)

	if "stability" in kit_dict and kit_dict["stability"] == KitStabilityRating.DEPRECATED:
		# no longer update this kit.
		return tree.head()

	# Phase 1: prep the kit
	pre_steps = [
		GitCheckout(kit_dict['branch']),
		CleanTree()
	]
	
	prep_steps = getKitPrepSteps(repos, kit_dict, gentoo_staging, fixup_repo)
	pre_steps += prep_steps[0]
	copy_steps = prep_steps[1]
	post_steps = prep_steps[2]

	tree.run(pre_steps)

	# Phase 2: copy core set of ebuilds

	# Here we generate our main set of ebuild copy steps, based on the contents of the package-set file for the kit. The logic works as
	# follows. We apply our package-set logic to each repo in succession. If copy ebuilds were actually copied (we detect this by
	# looking for changed catpkg count in our dest_kit,) then we also run additional steps: "copyfiles" and "eclasses". "copyfiles"
	# specifies files like masks to copy over to the dest_kit, and "eclasses" specifies eclasses from the overlay that we need to
	# copy over to the dest_kit. We don't need to specify eclasses that we need from gentoo_staging -- these are automatically detected
	# and copied, but if there are any special eclasses from the overlay then we want to copy these over initially.

	copycount = cpm_logger.copycount
	for repo_dict in repos:
		steps = []
		select_clause = "all"
		overlay_def = repo_dict["overlay_def"]

		if "select" in overlay_def:
			select_clause = overlay_def["select"]

		# If the repo has a "filter" : [ "foo", "bar", "oni" ], then construct a list of repos with those names and put
		# them in filter_repos. We will pass this list of repo objects to InsertEbuilds inside generateKitSteps, and if
		# a catpkg exists in any of these repos, then it will NOT be copied if it is scheduled to be copied for this
		# repo. This is a way we can lock down overlays to not insert any catpkgs that are already defined in gentoo --
		# just add: filter : [ "gentoo-staging" ] and if the catpkg exists in gentoo-staging, it won't get copied. This
		# way we can more safely choose to include all ebuilds from 'potpurri' overlays like faustoo without exposing
		# ourself to too much risk from messing stuff up.

		filter_repos = []
		if "filter" in overlay_def:
			for filter_repo_name in overlay_def["filter"]:
				for x in repos:
					if x["name"] == filter_repo_name:
						filter_repos.append(x["repo"])

		if kit_dict["name"] == "nokit":
			# grab all remaining ebuilds to put in nokit
			steps += [ InsertEbuilds(repo_dict["repo"], select_only=select_clause, skip=None, replace=False, cpm_logger=cpm_logger) ]
		else:
			steps += generateKitSteps(kit_dict['name'], repo_dict["repo"], fixup_repo=fixup_repo,
			                          select_only=select_clause, pkgdir=merge_scripts.root+"/funtoo/scripts",
			                          filter_repos=filter_repos, force=overlay_def["force"] if "force" in overlay_def else None,
			                          cpm_logger=cpm_logger, secondary_kit=secondary_kit)
		tree.run(steps)
		if copycount != cpm_logger.copycount:
			# this means some catpkgs were installed from the repo we are currently processing. This means we also want to execute
			# 'copyfiles' and 'eclasses' copy logic:
			
			ov = overlays[repo_dict["name"]]

			if "copyfiles" in ov and len(ov["copyfiles"]):
				# since we copied over some ebuilds, we also want to make sure we copy over things like masks, etc:
				steps += [ SyncFiles(repo_dict["repo"].root, ov["copyfiles"]) ]
			if "eclasses" in ov:
				# we have eclasses to copy over, too:
				ec_files = {}
				for eclass in ov["eclasses"]:
					ecf = "/eclass/" + eclass + ".eclass"
					ec_files[ecf] = ecf
				steps += [ SyncFiles(repo_dict["repo"].root, ec_files) ]
		copycount = cpm_logger.copycount

	# Phase 3: copy eclasses, licenses, profile info, and ebuild/eclass fixups from the kit-fixups repository. 

	# First, we are going to process the kit-fixups repository and look for ebuilds and eclasses to replace. Eclasses can be
	# overridden by using the following paths inside kit-fixups:

	# kit-fixups/eclass <--------------------- global eclasses, get installed to all kits unconditionally (overrides those above)
	# kit-fixups/<kit>/global/eclass <-------- global eclasses for a particular kit, goes in all branches (overrides those above)
	# kit-fixups/<kit>/global/profiles <------ global profile info for a particular kit, goes in all branches (overrides those above)
	# kit-fixups/<kit>/<branch>/eclass <------ eclasses to install in just a specific branch of a specific kit (overrides those above)
	# kit-fixups/<kit>/<branch>/profiles <---- profile info to install in just a specific branch of a specific kit (overrides those above)

	# Note that profile repo_name and categories files are excluded from any copying.

	# Ebuilds can be installed to kits by putting them in the following location(s):

	# kit-fixups/<kit>/global/cat/pkg <------- install cat/pkg into all branches of a particular kit
	# kit-fixups/<kit>/<branch>/cat/pkg <----- install cat/pkg into a particular branch of a kit

	# Remember that at this point, we may be missing a lot of eclasses and licenses from Gentoo. We will then perform a final sweep
	# of all catpkgs in the dest_kit and auto-detect missing eclasses from Gentoo and copy them to our dest_kit. Remember that if you
	# need a custom eclass from a third-party overlay, you will need to specify it in the overlay's overlays["ov_name"]["eclasses"]
	# list. Or alternatively you can copy the eclasses you need to kit-fixups and maintain them there :)

	steps = []

	# Here is the core logic that copies all the fix-ups from kit-fixups (eclasses and ebuilds) into place:

	if os.path.exists(fixup_repo.root + "/eclass"):
		steps += [ InsertEclasses(fixup_repo, select="all", skip=None) ]
	if kit_dict["branch"] == "master":
		fixup_dirs = [ "global", "master" ]
	else:
		fixup_dirs = [ "global", "curated", kit_dict["branch"] ]
	for fixup_dir in fixup_dirs:
		fixup_path = kit_dict['name'] + "/" + fixup_dir
		if os.path.exists(fixup_repo.root + "/" + fixup_path):
			if os.path.exists(fixup_repo.root + "/" + fixup_path + "/eclass"):
				steps += [
					InsertFilesFromSubdir(fixup_repo, "eclass", ".eclass", select="all", skip=None, src_offset=fixup_path)
				]
			if os.path.exists(fixup_repo.root + "/" + fixup_path + "/licenses"):
				steps += [
					InsertFilesFromSubdir(fixup_repo, "licenses", None, select="all", skip=None, src_offset=fixup_path)
				]
			if os.path.exists(fixup_repo.root + "/" + fixup_path + "/profiles"):
				steps += [
					InsertFilesFromSubdir(fixup_repo, "profiles", None, select="all", skip=["repo_name", "categories"] , src_offset=fixup_path)
				]
			# copy appropriate kit readme into place:
			readme_path = fixup_path + "/README.rst"
			if os.path.exists(fixup_repo.root + "/" + readme_path ):
				steps += [
					SyncFiles(fixup_repo.root, {
						readme_path : "README.rst"
					})
				]

			# We now add a step to insert the fixups, and we want to record them as being copied so successive kits
			# don't get this particular catpkg. Assume we may not have all these catpkgs listed in our package-set
			# file...

			steps += [
				InsertEbuilds(fixup_repo, ebuildloc=fixup_path, select="all", skip=None, replace=True,
				              cpm_logger=cpm_logger, is_fixup=True )
			]
	tree.run(steps)

	# Now we want to perform a scan of any eclasses in the Gentoo repo that we need to copy over to our dest_kit so that it contains all
	# eclasses and licenses it needs within itself, without having to reference any in the Gentoo repo.

	copy_steps = []

	# For eclasses we perform a much more conservative scan. We will only scour missing eclasses from gentoo-staging, not
	# eclasses. If you need a special eclass, you need to specify it in the eclasses list for the overlay explicitly.

	tree.run(copy_steps)
	copy_steps = []

	# copy all available licenses that have not been copied in fixups from gentoo-staging over to the kit.
	# We will remove any unused licenses below...

	copy_steps += [ InsertLicenses(gentoo_staging, select=simpleGetAllLicenses(tree, gentoo_staging)) ]
	tree.run(copy_steps)

	# Phase 4: finalize and commit

	# remove unused licenses...
	used_licenses = getAllLicenses(tree)
	to_remove = []
	for license in os.listdir(tree.root + "/licenses"):
		if license not in used_licenses["dest_kit"]:
			to_remove.append(tree.root + "/licenses/" + license)
	for file in to_remove:
		os.unlink(file)

	post_steps += [
		ELTSymlinkWorkaround(),
		CreateCategories(gentoo_staging),
		# multi-plex this and store in different locations so that different selections can be made based on which python-kit is enabled.
		# python-kit itself only needs one set which will be enabled by default.
	]

	if kit_dict["name"] == "python_kit":
		# on the python-kit itself, we only need settings for ourselves (not other branches)
		python_settings = python_kit_settings[kit_dict["name"]]
	else:
		# all other kits -- generate multiple settings, depending on what version of python-kit is active -- epro will select the right one for us.
		python_settings = python_kit_settings

	# TODO: GenPythonUse now references core-kit in the repository config in order to find needed eclasses for
	# TODO: metadata generation. For now, core-kit is going to be pointing to 1.2, and this should work, but in the
	# TODO: future, we may want more control over exactly what core-kit is chosen.

	for branch, py_settings in python_settings.items():
		post_steps += [ GenPythonUse(py_settings, "funtoo/kits/python-kit/%s" % branch) ]

	# TODO: note that GenCache has been modified to utilize eclasses from core-kit as well.

	post_steps += [
		Minify(),
		GenUseLocalDesc(),
		GenCache( cache_dir="/var/cache/edb/%s-%s" % ( kit_dict['name'], kit_dict['branch'] ) ),
	]

	if kit_group in [ "prime" ]:
		# doing to record distfiles in mysql only for prime, not current, at least for now
		post_steps += [
			CatPkgScan(now=now, db=db)
		]

	tree.run(post_steps)
	tree.gitCommit(message="updates",branch=kit_dict['branch'],push=push)
	return tree.head()

if __name__ == "__main__":

	# one global timestamp for each run of this tool -- for mysql db
	now = datetime.utcnow()

	if len(sys.argv) < 2 or sys.argv[1] not in [ "push", "nopush" ]:
		print("Please specify push or nopush as an argument.")
		sys.exit(1)
	else:
		push = True if "push" in sys.argv else False

	if "db" in sys.argv:
		db = getMySQLDatabase()
	else:
		db = None

	cpm_logger = CatPkgMatchLogger(log_xml=push)

	output_sha1s = {}
	output_order = []
	output_settings = defaultdict(dict)

	for kit_group in kit_order: 
		if kit_group is None:
			if push:
				cpm_logger.writeXML()
			cpm_logger = CatPkgMatchLogger(log_xml=False)
		else:
			prev_kit_dict = None
			# kits that are officially tagged as 'prime' -- this means that they are really prime -- branch name doesn't guarantee
			kit_labels = defaultdict(list)
			for kit_dict in kit_groups[kit_group]:
				print("Regenerating kit ",kit_dict)
				head = updateKit(kit_dict, prev_kit_dict, kit_group, cpm_logger, db=db, create=not push, push=push, now=now, fixup_repo=fixup_repo)
				kit_name = kit_dict["name"]
				kit_branch = kit_dict["branch"]

				if 'default' in kit_dict and kit_dict['default'] is True:
					kit_stability = KitStabilityRating.PRIME
				elif 'stability' in kit_dict:
					kit_stability = kit_dict['stability']
				elif kit_group == 'current':
					kit_stability = KitStabilityRating.CURRENT
				else:
					print("Unknown kit stability")
					sys.exit(1)
				if kit_group in [ "prime" ] and kit_name not in output_order:
					output_order.append(kit_name)
				if 'default' in kit_dict and kit_dict['default'] == True:
					output_settings[kit_name]["default"] = kit_branch
				# specific keywords that can be set for each branch to identify its current quality level
				if 'stability' not in output_settings[kit_name]:
					output_settings[kit_name]['stability'] = {}
				output_settings[kit_name]['stability'][kit_branch] = KitRatingString(kit_stability)
				if kit_name not in output_sha1s:
					output_sha1s[kit_name] = {}
				output_sha1s[kit_name][kit_branch] = head
				prev_kit_dict = kit_dict

	if not os.path.exists(meta_repo.root + "/metadata"):
		os.makedirs(meta_repo.root + "/metadata")

	with open(meta_repo.root + "/metadata/kit-sha1.json", "w") as a:
		a.write(json.dumps(output_sha1s, sort_keys=True, indent=4, ensure_ascii=False))

	outf = meta_repo.root + "/metadata/kit-info.json"
	# read first to preserve any metadata we added manually
	k_info = {}
	if os.path.exists(outf):
		a = open(outf, 'r')
		k_info = json.loads(a.read())
		a.close()
	k_info["kit_order"] = output_order
	k_info["kit_settings"] = output_settings
	with open(meta_repo.root + "/metadata/kit-info.json", "w") as a:
		a.write(json.dumps(k_info, sort_keys=True, indent=4, ensure_ascii=False))

	print("Checking out default versions of kits.")
	for kit_dict in kit_groups['prime']:
		if 'default' not in kit_dict or kit_dict['default'] != True:
			# skip non-default kits
			continue
		kit_dict["tree"].run([GitCheckout(branch=kit_dict['branch'])])
	if push:
		meta_repo.gitCommit(message="kit updates", branch="master", push=push)

# vim: ts=4 sw=4 noet tw=140
