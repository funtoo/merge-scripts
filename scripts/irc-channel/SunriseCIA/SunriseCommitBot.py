#!/usr/bin/python
import socket
import string
import random
from os import system
import os
import time
import sys
import SunriseCIA
from SunriseCIA import CommitParser

#
# Configuration
#

# irc serverdetails
HOST="irc.freenode.net"
PORT=6667

# Our Nick and stuff
NICK="SunriseCIA"
IDENT="Sunrise"
REALNAME="Sunrise Commit Announcer"

# what channels should the bot sit in
CHANNELS=["#gentoo-sunrise"]

# dir to check for commit-announce files
DIRCHECK="/var/www/sunrise.gentooexperimental.org/commitwatch"

# don't connect to irc, announce on stdout
offline=0

# delete file after announce
delete=1


#########################################
     #                             #
##   # NO CHANGES ARE NEEDED BELOW #   ##
     #                             #
#########################################

readbuffer=" "

if offline == 0:
	def msg(to,msg):
		s.send("PRIVMSG %s :%s\r\n" % (to, msg))
	
	def cmd(cmd,arg):
		s.send("%s %s\r\n" % (cmd,arg))
	s=socket.socket( )
	s.connect((HOST, PORT))
	cmd("NICK",NICK)
	s.send("USER %s %s bla :%s\r\n" % (IDENT,HOST,REALNAME))
	for chan in CHANNELS:
		cmd("JOIN",chan)

else:
	def msg(to,msg):
		print "MSG: %s :%s" % (to.strip(), msg.strip())
	
	def cmd(cmd,arg):
		print "CMD: %s %s" % (cmd.strip(),arg.strip())

while 1:
	if offline == 0:
		s.setblocking(0)
		try:
			readbuffer=readbuffer+s.recv(1024)
			temp=string.split(readbuffer, "\n")
			readbuffer=temp.pop( )
			for line in temp:
				line=string.rstrip(line)
				line=string.split(line)
				if(line[0]=="PING"):
					s.send("PONG %s\r\n" % line[1])
		except:
			pass
	    
	for root, dirs, files in os.walk(DIRCHECK):
		for name in files:
			# Call the parser!!!
			parser = SunriseCIA.CommitParser( )
			parser.filename = os.path.join(root,name)
			parser.doit()
			firstline = "3%s * 10r%s %s" % (parser.author,parser.revision,parser.pathline)
			if offline == 0:
				print "%s * r%s %s" % (parser.author,parser.revision,parser.pathline)
			parser.logmessage = parser.logmessage[parser.logmessage.find(":")+1:].lstrip()
    			for chan in CHANNELS:
    				msg(chan,firstline)
				msg(chan,parser.logmessage.strip())
				msg(chan,"< %s >" % ("http://gentoo-sunrise.org/cgi-bin/trac.cgi/changeset/" + parser.revision))
			if delete != 0:
				os.remove(os.path.join(root,name))
			inhalt=""
	time.sleep(5)
