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

import supybot.utils as utils
from supybot.commands import *
import supybot.plugins as plugins
import supybot.ircutils as ircutils
import supybot.callbacks as callbacks

import re
import commands
import commands, os, time
from pysqlite2 import dbapi2 as sqlite

BOTPATH="/path/to/botdir"

class UserException(Exception):
    def __init__(self,value):
        self.value = value
    def __str__(self):
        return repr(self.value)

class NoSuchUser(UserException):
    pass

class UserAlreadyExists(UserException):
    pass

class PasswordChangeForbidden(UserException):
    pass

class AccountLocked(UserException):
    pass

class SunriseAdminDB:
    def __init__(self):
        self.htpasswd2 = "/usr/sbin/htpasswd2"

        sunrisebotpath = "/path/to/bot/"
        datafile = "data/sunrise.db"

        sunrisedbfile = sunrisebotpath + datafile

        if not os.path.isfile(sunrisedbfile):
            needsinit = 1
        else:
            needsinit = None

        self.db = sqlite.connect(sunrisedbfile)
        self.cursor = self.db.cursor()
        if needsinit:
            print "DB Create!"
            cursor = self.cursor
            cursor.execute("""CREATE TABLE sunriseusers (
                              username VARCHAR(64) PRIMARY KEY,
                              password VARCHAR(90),
                              isdev TINYINT,
                              islocked TINYINT,
                              setupby VARCHAR(64),
                              setupdate INT,
                              description VARCHAR(255)
                              )""")
            cursor.execute("""CREATE TABLE passwordgrant (
                              sunriseuser VARCHAR(64),
                              ircuser VARCHAR(64),
                              timeout INT
                              )""")                            
            self.db.commit()

    def userExists(self,sunriseuser):
        self.cursor.execute("SELECT * FROM sunriseusers WHERE username='%s'"
                             % sunriseuser)
        if self.cursor.fetchall():
            return True
        else:
            return False

    def isLocked(self,sunriseuser):
        self.cursor.execute("""SELECT * FROM sunriseusers
                               WHERE username='%s' AND islocked=1"""
                               % sunriseuser)
        if self.cursor.fetchall():
            return True
        else:
            return False

    def isDev(self,sunriseuser):
        self.cursor.execute("""SELECT * FROM sunriseusers
                               WHERE username='%s' AND isdev=1"""
                               % sunriseuser)
        if self.cursor.fetchall():
            return True
        else:
            return False
         
    def permitPasswordChange(self,ircuser,sunriseuser):
        if not self.userExists(sunriseuser):
            raise NoSuchUser(sunriseuser)
        if self.isLocked(sunriseuser):
            raise AccountLocked(sunriseuser)

        self.cursor.execute("SELECT * FROM passwordgrant WHERE ircuser='%s'"
                             % sunriseuser)
        if self.cursor.fetchall():
            self.cursor.execute("""UPDATE passwordgrant
                                   SET sunriseuser='%s', timeout=%i
                                   WHERE ircuser='%s'""" %
                                   (sunriseuser,time.time()+600,ircuser))
        else:
            self.cursor.execute("""INSERT INTO passwordgrant
                                   (ircuser,sunriseuser,timeout)
                                   VALUES ('%s','%s',%i)""" %
                                   (ircuser,sunriseuser,time.time()+600))
        self.db.commit()
    
    def changePassword(self,ircuser,password):
        self.db.execute("""DELETE FROM passwordgrant WHERE timeout<%i""" % time.time())
        result = self.cursor.execute("""SELECT sunriseuser FROM passwordgrant
            WHERE ircuser='%s' AND timeout>%i""" % (ircuser,time.time()))
        row = result.fetchone()
        if not row:
            raise PasswordChangeForbidden(ircuser)
        sunriseuser = row[0] 
        if not self.userExists(sunriseuser):
            raise NoSuchUser(sunriseuser)
        if self.isLocked(sunriseuser):
            raise AccountLocked(sunriseuser)
        htpasswdout = commands.getoutput('%s -bn %s "%s"' %
                 (self.htpasswd2,sunriseuser,password))

        self.db.execute("""UPDATE sunriseusers SET password='%s' WHERE
                username='%s'""" % (htpasswdout.strip(),sunriseuser))
        self.db.execute("""DELETE FROM passwordgrant
                               WHERE ircuser='%s' OR timeout>%i""" %
                               (ircuser,time.time()))
        self.db.commit()

    def addUser(self,sunriseuser,setupuser):
        if self.userExists(sunriseuser):
            raise UserAlreadyExists(sunriseuser)
        self.db.execute("""INSERT INTO sunriseusers
        (username,password,isdev,islocked, setupby, setupdate)
        VALUES ('%s','%s:unsetyet',0,0,'%s',%s)""" %
        (sunriseuser,sunriseuser,setupuser,time.time()))
        self.db.commit()

    def delUser(self,sunriseuser):
        # Implemented but just lock out users for repo consistency!
        if self.userExists(sunriseuser):
            raise UserAlreadyExists(sunriseuser)
        self.db.execute("""DELETE FROM sunriseusers
                           WHERE username='%s'""" % (sunriseuser))
        self.db.execute("""DELETE FROM passwordgrant
                           WHERE sunriseuser='%s'""" % sunriseuser)
        self.db.commit()

    def becomeDev(self,sunriseuser):
        if not self.userExists(sunriseuser):
            raise NoSuchUser(sunriseuser)
        self.db.execute("""UPDATE sunriseusers SET isdev=1 WHERE
                username='%s'""" % sunriseuser)
        self.db.commit()

    def removeDev(self,sunriseuser):
        if not self.userExists(sunriseuser):
            raise NoSuchUser(sunriseuser)
        self.db.execute("""UPDATE sunriseusers SET isdev=0 WHERE
                username='%s'""" % sunriseuser)
        self.db.commit()

    def lockAccount(self,sunriseuser):
        if not self.userExists(sunriseuser):
            raise NoSuchUser(sunriseuser)
        self.db.execute("""UPDATE sunriseusers SET islocked=1 WHERE
                username='%s'""" % sunriseuser)
        self.db.commit()

    def unlockAccount(self,sunriseuser):
        if not self.userExists(sunriseuser):
            raise NoSuchUser(sunriseuser)
        self.db.execute("""UPDATE sunriseusers SET islocked=0 WHERE
                username='%s'""" % sunriseuser)
        self.db.commit()

    def htpasswdList(self):
        passwordlist = []
        for row in self.db.execute("""SELECT password FROM sunriseusers
                                      WHERE isLocked=0 ORDER BY username"""):
            passwordlist.append(row[0])
        return passwordlist

Class = SunriseAdminDB

class SunriseAdmin(callbacks.Plugin):
    """Add the help for "@plugin help SunriseAdmin" here
    This should describe *how* to use this plugin."""

    def __init__(self, irc):
        self.__parent = super(SunriseAdmin,self)
        self.__parent.__init__(irc)
        self.sundb = SunriseAdminDB()
                                            
    def sradduser(self,irc,msg,args,ircuser,sunriseuser):
        """<ircnick> <sunriseuser>

        adds a new user sunriseuser to htpasswd and lets ircnick set a password for it
        """
        sundb = self.sundb
        try:
            sundb.addUser(sunriseuser,irc.msg.nick)
        except UserAlreadyExists:
            irc.reply("User already exists")
        sundb.permitPasswordChange(ircuser,sunriseuser) 
        irc.reply("added %s to sunrise and %s has 10 minutes to set a password now with '/msg SunriseBot srsetpassword myshinypassword'" % (sunriseuser,ircuser) )
                                    
    sradduser = wrap(sradduser,
                     [('checkCapability','#gentoo-sunrise,op'),'somethingWithoutSpaces','somethingWithoutSpaces'])

    def srgrantnewpw(self,irc,msg,args,ircuser,sunriseuser):
        """<ircnick> <sunriseuser>

        grants the ircuser permission to once set a password for the sunrise username
        """
        sundb = self.sundb
        if not sundb.userExists(sunriseuser):
            irc.reply("That user doesn't exist, Typo maybe??")
        else:
            sundb.permitPasswordChange(ircuser,sunriseuser) 
            irc.reply("%s has 10 minutes to set a password now with '/msg SunriseBot srsetpassword myshinypassword'" 
                       % ircuser )
                                    
    srgrantnewpw = wrap(srgrantnewpw,
                     [('checkCapability','#gentoo-sunrise,op'),'somethingWithoutSpaces','somethingWithoutSpaces'])
                     
    def srsetpassword(self,irc,msg,args,newpass):
        if len(newpass) < 4:
            irc.reply("Pick a longer password")
        elif len(newpass) > 20:
            irc.reply("You want to remember that many letters? ;)")
        elif not re.compile("^[a-zA-Z0-9]*$").match(newpass):
            irc.reply("Only a-z, A-Z and 0-9 chars allowed")
        else:
            try:
                self.sundb.changePassword(irc.msg.nick,newpass)
                commands.getoutput(BOTPATH + "/plugins/SunriseAdmin/passwordexport.py")
                irc.reply("Successfully set your new password.")
            except PasswordChangeForbidden:
                irc.reply("You're not allowed to change your password currently."
                          " Ask an op in #gentoo-sunrise to grant it to you.")

    srsetpassword = wrap(srsetpassword,['somethingWithoutSpaces'])

    def srlock(self,irc,msg,args,sunriseuser):
        sundb = self.sundb
        if not sundb.userExists(sunriseuser):
            irc.reply("That user doesn't exist, Typo maybe??")
        else:
            if sundb.isLocked(sunriseuser):
                irc.reply("This account is locked already")
            else:
                self.sundb.lockAccount(sunriseuser)
                commands.getoutput(BOTPATH + "/plugins/SunriseAdmin/passwordexport.py")
                irc.reply("Commitaccount is locked now")

    srlock = wrap(srlock,[('checkCapability','#gentoo-sunrise,op'),'somethingWithoutSpaces'])

    def srlockcheck(self,irc,msg,args,sunriseuser):
        sundb = self.sundb
        if not sundb.userExists(sunriseuser):
            irc.reply("That user doesn't exist, Typo maybe??")
        else:
            if not sundb.isLocked(sunriseuser):
                irc.reply("This account is not locked")
            else:
                irc.reply("This account is locked")

    srlockcheck = wrap(srlockcheck,['somethingWithoutSpaces'])

    def srunlock(self,irc,msg,args,sunriseuser):
        sundb = self.sundb
        if not sundb.userExists(sunriseuser):
            irc.reply("That user doesn't exist, Typo maybe??")
        else:
            if not sundb.isLocked(sunriseuser):
                irc.reply("This account is not locked")
            else:
                self.sundb.unlockAccount(sunriseuser)
                commands.getoutput(BOTPATH + "/plugins/SunriseAdmin/passwordexport.py")
                irc.reply("Commitaccount is unlocked now")

    srunlock = wrap(srunlock,[('checkCapability','#gentoo-sunrise,op'),'somethingWithoutSpaces'])

    def srregendb(self,irc,msg,args):
        commands.getoutput(BOTPATH + "/plugins/SunriseAdmin/passwordexport.py")

    srregendb = wrap(srregendb)

Class = SunriseAdmin


# vim:set shiftwidth=4 tabstop=4 expandtab textwidth=79:
