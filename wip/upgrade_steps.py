#!/usr/bin/python3

funtoo_releases = OrderedDict()

funtoo_releases["1.0"] = {
	"kit_compat_group": [
		("core-kit", "1.0-prime"),
		("security-kit", "1.0-prime"),
		("media-kit", "1.1-prime"),
		("java-kit", "1.0-prime"),
		("ruby-kit", "1.0-prime"),
		("haskell-kit", "1.0-prime"),
		("lisp-scheme-kit", "1.0-prime"),
		("lang-kit", "1.0-prime"),
		("dev-kit", "1.0-prime"),
		("desktop-kit", "1.0-prime"),
	],
	"upgrade_from": []
}

funtoo_releases["1.2"] = {
	"kit_compat_group": [
		("core-kit", "1.2-prime"),
		("security-kit", "1.2-prime"),
		("media-kit", "1.2-prime"),
		("java-kit", "1.2-prime"),
		("ruby-kit", "1.2-prime"),
		("haskell-kit", "1.2-prime"),
		("lisp-scheme-kit", "1.2-prime"),
		("lang-kit", "1.2-prime"),
		("dev-kit", "1.2-prime"),
		("desktop-kit", "1.2-prime"),
	],
	"upgrade_from": ["1.0"],
	"release_docs": "RELEASE.mediawiki",  # TODO: where is the optimal place to place this file?
	"package_prerequisites": [">=app-admin/ego-1.9.0"],
	# TODO: these upgrade steps might be better placed in the ego repo.... maybe exported to JSON?
	"upgrade_steps": [
		"emerge -1 gcc",
		"emerge -1 glibc",
		"emerge -uDN @system",
		"emerge -uDN @world",
		"emerge @preserved-rebuild"
		"revdep-rebuild --library 'libstdc++.so.6' -- --exclude sys-devel/gcc"
	]
}


class UpgradeHandler:
	pass

class KitHandler(UpgradeHandler):
	pass

class ReleaseHandler(UpgradeHandler):
	pass

class Release12UpgradeHandler(UpgradeHandler):

	_kits = [
		"core-kit"
		"security-kit",
		"media-kit",
		"java-kit",
		"ruby-kit",
		"haskell-kit",
		"lisp-scheme-kit",
		"lang-kit",
		"dev-kit",
		"desktop-kit"
	]

	@classmethod
	def available_upgrades(cls):

		reqs = []
		results = []

		for kit in cls._kits:
			if kit == "media-kit":
				reqs.append({"kit": kit, "branch": "1.1-prime"})
			reqs.append({ "kit" : kit, "branch" : "1.0-prime" })

		for kit in cls._kits:
			results.append({ "kit": kit, "branch": "1.2-prime" })

		return [
			{
				"target" : { "release" : "1.2" },
				"requirements": reqs,
				"results" : results
			}
		]

class PythonKitHandler(KitHandler):

	@classmethod
	def available_upgrades(cls):

		return [
			{
				"target" : { "kit" : "python-kit", "branch" : "3.6-prime" },
				"requirements" : [
					{ "kit" : "python-kit", "branch" : "3.4-prime" }
				]
			}
		]

	def get_steps(self, new_branch, old_branch):
		new_v, new_rating = new_branch.split("-") # "3.6", "prime"
		old_v, old_rating = old_branch.split("-")
		new_major = Decimal(new_v[:3]) # 3.6
		old_major = Decimal(old_v[:3])
		post_steps = [ "emerge -uDN @world" ]
		if new_major != old_major:
			post_steps += [ "eselect python set --python3 python%s" % new_major ]
		for major in self.settings["remove"]:
			post_steps.append("emerge -C =dev-lang/python-%s" % major)
		return [], post_steps

	settings = {
		#	branch / primary python / alternate python / python mask (if any)
		'master': {
			"primary": "python3_6",
			"alternate": "python2_7",
			"mask": None,
			"remove" : [ "3.3", "3.4", "3.5" ]
		},
		'3.4-prime': {
			"primary": "python3_4",
			"alternate": "python2_7",
			"mask": ">=dev-lang/python-3.5",
			"remove": ["3.3", "3.5", "3.6"]
		},
		'3.6-prime': {
			"primary": "python3_6",
			"alternate": "python2_7",
			"mask": ">=dev-lang/python-3.7",
			"remove": ["3.3", "3.4", "3.5"]
		},
		'3.6.3-prime': {
			"primary": "python3_6",
			"alternate": "python2_7",
			"mask": ">=dev-lang/python-3.7",
			"remove": ["3.3", "3.4", "3.5"]
		}
	}



""""

ego kit upgrade python-kit 3.4-prime 3.6-prime
>> Would you like to upgrade to python-kit 3.6-prime? y/n
>> Starting kit upgrade....
>> Recording log...
>> changing kit..
>> syncing...
>> upgrading...
>> Will execute the following steps. Would you like me to execute these for you?:
>>
1. emerge -auDN @world
2






"""

