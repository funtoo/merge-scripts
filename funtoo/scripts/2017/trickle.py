#!/usr/bin/python3

import sys, os, subprocess
from email.utils import parsedate
from time import mktime
from datetime import datetime

repo_name = sys.argv[1]

def run(command):
	s, o = subprocess.getstatusoutput(command)
	if s == 0:
		return o
	else:
		return None

def get_audit_cycle(path):
	try:
		with open(path+"/.audit-cycle", "r") as auditfile:
			content = auditfile.read().strip()
			try:
				return int(content)
			except:
				raise IOError
	except IOError:
		return None

if not os.path.exists(repo_name):
	print("path does not exist. Exiting.")
	sys.exit(1)

default_audit_cycle = 60
catpkg_list = []
now = datetime.now()
utcnow = datetime.utcnow()
for kit in os.listdir(repo_name):
	kit_path = os.path.join(repo_name, kit)
	if not os.path.isdir(kit_path):
		continue
	audit_cycle = get_audit_cycle(kit_path) or default_audit_cycle
	for branch in os.listdir(kit_path):
		branch_path = os.path.join(kit_path, branch)
		if not os.path.isdir(branch_path):
			continue
		audit_cycle = get_audit_cycle(branch_path) or audit_cycle
		for cat in os.listdir(branch_path):
			if "-" not in cat and cat != "virtual":
				continue
			cat_path = os.path.join(branch_path, cat)
			if not os.path.isdir(cat_path):
				continue
			for pkg in os.listdir(cat_path):
				catpkg = cat + "/" + pkg
				auditfile = cat + "/" + pkg + "/.audit"
				if os.path.exists(auditfile):
					datecheckfile = pkg + "/.audit"
				else:
					datecheckfile = pkg
				out = run ("(cd %s; git log -n 1 --oneline -- %s)" % ( cat_path, datecheckfile ))
				sha1 = out.split(" ")[0]
				out = run ("(cd %s; git show --no-patch --format=%%ce_%%cD %s)" % ( cat_path, sha1))
				email, isodate = out.split("_")
				dt = (now - datetime.fromtimestamp(mktime(parsedate(isodate))))
				if dt.days >= audit_cycle:
					catpkg_list.append((dt, kit, branch, catpkg, email))
				#"git log -n 1 --oneline -- ."
				#"git show --no-patch --format=%ce,%cI 68dc82e"
print('<html><head><title>kit-fixups that need review</title><link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0-beta.3/css/bootstrap.min.css" integrity="sha384-Zug+QiDoJOrZ5t4lssLdxGhVrurbmBWopoEl+M6BdEfwnCJZtKxi1KgxUyJq13dy" crossorigin="anonymous"></head><body>'
      '<div class="container"><div class="row"><div class="col-md" style="margin-top: 50px;"><h2>Funtoo Linux Stale Packages QA List</h2>'
      '<div class="alert alert-primary" style="margin-top: 50px;">This page lists catpkgs in kit-fixups that are <i>stale</i>. These catpkgs should be reviewed and updated; when they are updated in git, they will no longer be stale and will be removed automatically from this list.</div>'
		'<div class="alert alert-dark"><p>If you review a catpkg and determine that it does not need an update, it is still possible to remove it from this list. Add a <tt>.audit</tt> file to the catpkg directory containing a text description of your review and commit it. This will result in the catpkg being \'reviewed\' and it will drop from this list.'
		'<p>By default, catpkgs will be up for review after <b>60</b> days. To change this threshold, you can create a <tt>.audit-cycle</tt> file in the kit or branch directory containing an integer number of days after which catpkgs in the kit or branch should be considered stale.</p><p><a href="https://github.com/funtoo/kit-fixups">Visit kit-fixups on GitHub</a></p>'
      '<p>Please ensure catpkgs are not stale. Ideally review them every 30 days or less; please do not let catpkgs go without review for 60 days or more. Also note that because Funtoo doesn\'t have official maintainers for packages, the \'last modified by\' column is listed for convenience so you can coordinate with the previous committer if necessary.</p></div>'
      '<div style="text-align: right; width: 100%;"><p style="font-size: 8pt;"><i>This page was last updated on ' + now.strftime("%Y-%m-%d %H:%M:%S %p %Z local time") + " (" + utcnow.strftime(" %y-%m-%d %H:%M") + " UTC)</i></p></div>"
      '</div></div></div>'
      '<table class="table table-striped"><thead class="thead-dark"><th>days stale</th><th>kit</th><th>branch</th><th>catpkg</th><th>last modified by</th></thead>')
catpkg_list.sort(key=lambda x: x[0], reverse=True)
for item in catpkg_list:
	days = item[0].days
	if days > 100:
		days = '<b><span style="color: #ff0000;">' + str(days) + '</span></b>'
	print("<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>" % ( days, item[1], item[2], item[3], item[4]))
print("</table></body></html>")