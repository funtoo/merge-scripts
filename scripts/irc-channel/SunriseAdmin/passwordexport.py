#!/usr/bin/python
import SunriseAdminDB
import os

htpasswdfile = "/path/to/svn/conf/svnusers"

os.remove(htpasswdfile)
filehandle = open(htpasswdfile,'w')
for entry in SunriseAdminDB.SunriseAdminDB().htpasswdList():
    filehandle.write(entry+'\n')