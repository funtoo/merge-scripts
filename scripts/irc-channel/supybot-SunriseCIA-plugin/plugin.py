###
# Copyright (c) 2006, Markus Ullmann
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#   * Redistributions of source code must retain the above copyright notice,
#     this list of conditions, and the following disclaimer.
#   * Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions, and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#   * Neither the name of the author of this software nor the name of
#     contributors to this software may be used to endorse or promote products
#     derived from this software without specific prior written consent.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

###

import threading
import time

import supybot.utils as utils
from supybot.commands import *
import supybot.ircmsgs as ircmsgs
import supybot.plugins as plugins
import supybot.ircutils as ircutils
import supybot.callbacks as callbacks
import SunriseCIAParser
import os

DIRCHECK="/path/to/commitwatch"
ANNOUNCEINCHANNEL="#gentoo-sunrise"

class SunriseCIA(callbacks.Plugin):
	"""Add the help for "@plugin help SunriseCIA" here
	This should describe *how* to use this plugin."""
	threaded = True
	
	def __init__(self, irc):
		self.__parent = super(SunriseCIA,self)
		self.__parent.__init__(irc)
		self.filelist = []
		self.watchactive = 0

	def parsestart(self, irc, msg, args):
		if not self.ParseActive():
			self.GetFileList()
			if len(self.filelist) > 2:
				irc.queueMsg(ircmsgs.privmsg(ANNOUNCEINCHANNEL,"Found too many pending announcements, killing them now, see Timeline please"))
		                while (len(self.filelist) > 0):
            				file = self.filelist.pop()
		                	os.remove(file) 	
			elif len(self.filelist) > 0:
				irc.queueMsg(ircmsgs.privmsg(ANNOUNCEINCHANNEL,"Found %s pending announcement(s), queueing them"))
			
			self.watchactive = 1
			self.t = threading.Thread(target=self.Parseit, name="ParserWatcher",args=(irc,msg,args))
			self.t.setDaemon(True)
			self.t.start()
	        else:
			irc.queueMsg(ircmsgs.privmsg(ANNOUNCEINCHANNEL,"SunriseCIA already started"))

	parsestart = wrap(parsestart)

	def parsestop(self,irc,msg,args):
		self.watchactive = 0

	parsestop = wrap(parsestop, [('checkCapability',ANNOUNCEINCHANNEL+',op')])

	def parsestatus(self, irc, msg, args):
		if self.ParseActive():
			irc.reply("SunriseCIA active")
		else:
			irc.reply("SunriseCIA disabled")

	parsestatus = wrap(parsestatus)
	
	def GetFileList(self):
		for root, dirs, files in os.walk(DIRCHECK):
			for name in files:
				self.filelist.append(os.path.join(root,name))

	def Parseit(self, irc, msg, args):
		irc.queueMsg(ircmsgs.privmsg(ANNOUNCEINCHANNEL,"SunriseCIA started"))
		while(self.watchactive):
			self.GetFileList()
	                while (len(self.filelist) > 0):
    	            		file = self.filelist.pop()
	    			parser = SunriseCIAParser.CommitParser( )
	                	parser.filename = file
        			parser.doit()
	                	tempstr = parser.logmessage.strip()
        			temppos = tempstr.find(":")
	                	if temppos > 0:
        		        	tempstr = tempstr[(temppos+1):].strip()
	                	s = "3%s * 10r%s %s: %s < %s >" % (parser.author,parser.revision,parser.pathline,tempstr,"http://gentoo-sunrise.org/cgi-bin/trac.cgi/changeset/" + parser.revision)
	                	irc.queueMsg(ircmsgs.privmsg(ANNOUNCEINCHANNEL,s))
	                	os.remove(file) 	
        			time.sleep(2)
			time.sleep(5)
		irc.queueMsg(ircmsgs.privmsg(ANNOUNCEINCHANNEL,"SunriseCIA stopped"))

	def ParseActive(self):
    		if self.watchactive == 1 and self.t.isAlive():
	                return True
	        else:
    	    		self.watchactive == 0
	        	return False

Class = SunriseCIA

# vim:set shiftwidth=4 tabstop=4 expandtab textwidth=79:
