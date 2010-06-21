import xml.sax 
from xml.sax import saxutils
from xml.sax import make_parser
# import time
# from pprint import pprint

class CommitParserHandler(saxutils.DefaultHandler):
	def __init__(self):
		self.inRevision = 0
		self.inAuthor = 0
		self.inLog = 0
		self.inFile = 0
		self.filelist = []
		self.author = ""
		self.revision = ""
		self.logmessage = ""
		
	def startElement(self, name, attrs):
		if name == "revision":
			self.buffer = ""
			self.inRevision = 1
		if name == "author":
			self.buffer = ""
			self.inAuthor = 1
		if name == "log":
			self.buffer = ""
			self.inLog = 1
		if name == "file":
			self.buffer = ""
			self.inFile = 1
		
	def characters(self, data):
		if self.inRevision == 1 or self.inAuthor == 1 or self.inLog == 1 or self.inFile == 1:
			self.buffer += data

	def endElement(self, name):	
		if name == "revision":
			self.inRevision = 0
			self.revision = self.buffer
		if name == "author":
			self.inAuthor = 0
			self.author = self.buffer
		if name == "log":
			self.inLog = 0
			self.logmessage = self.buffer
		if name == "file":
			self.inFile = 0
			self.filelist.append(self.buffer)

class CommitParser:
	def __init__(self):
		self.filename = ""
		self.author = ""
		self.revision = ""
		self.pathline = ""
		self.logmessage = ""
		self.filecount = 0
		self.dircount = 0
		self.filelist = []
		self.path = ""
	
	def parse(self):
		parser = make_parser( )
		handler = CommitParserHandler( )
		parser.setContentHandler(handler)
		parser.parse(self.filename)

		# Let's find out what dirs were touched
		filelist = handler.filelist
		finished = 0
		path = ""
		multidir = 0
		while finished == 0:
			ok = 1
			i = 0
			subdirlinecount = 0
			subdirslashpos = 0
			maxi = len(filelist)
			if (i+1) == maxi:
				ok = 0
			while i < maxi and ok == 1:
				search = filelist[i].find("/")
				if search == -1:
					#okay, we have a fil in the "top" dir let's stop it
					ok = 0
					break
				if search > -1:
					# we have a subdir in here, so count ;)
					subdirlinecount += 1
				i += 1
			
			if ok == 1 and multidir == 0:
				if subdirlinecount == maxi:
					#okay all dirs still have a slash
					# everything in the same dir?
					subdirlinecount = 0
					lastdir = ""
					# count dirs
					filelist.sort()
					for dir in filelist:
						if dir.find("/") > -1:
							if dir[:dir.find("/")+1] != lastdir:
								subdirlinecount += 1
								lastdir = dir[:dir.find("/")+1]
    
					if subdirlinecount == 1:
						# okay, all lines have the same slashpos.
						# strip everything up to it
						i = 0
						path += filelist[0][:search+1]
						while i < maxi:
							filelist[i] = filelist[i][search+1:]
							i += 1
						filelist.sort()
						for line in filelist:
							if line == "":
								filelist.remove("")
					else:
						#no we seem to have the topdir now..
						dircount = subdirlinecount
						multidir = 1
			else:
				finished=1
				filecount = 0
				dircount = 0
				lastdir = ""
				# count dirs
				filelist.sort()
				for dir in filelist:
					if dir.find("/") > -1:
						if dir[:dir.find("/")+1] != lastdir:
							dircount += 1
							lastdir = dir[:dir.find("/")+1]
						
				filecount = maxi
		self.author = handler.author
		self.revision = handler.revision
		self.logmessage = handler.logmessage
		self.dircount = dircount
		self.filecount = filecount
		self.filelist = filelist
		self.path = path	
	def generate_pathline(self):
		self.pathline = ""
		if self.filecount == 1 and self.dircount == 0:
			self.pathline = self.path + filelist[0]
		if (self.filecount > 1 or self.filecount < 4) and self.dircount == 0:
			self.pathline = self.path + " ("
			for file in self.filelist:
				self.pathline += file + " "
			self.pathline = self.pathline[:-1] + ")"
		if self.filecount >= 1 and self.dircount >= 1 and self.filecount+self.dircount < 4:
			self.pathline = self.path + " ("
			for file in self.filelist:
				self.pathline += file + " "
			self.pathline = self.pathline[:-1] + ")"
		if self.filecount >= 1 and self.dircount >= 1 and self.filecount+self.dircount >= 4:
			self.pathline = self.path + " ("
			if self.filecount == 1:
				self.pathline += "1 file"
			if self.filecount > 1:
				self.pathline += "%i files" % self.filecount
			if self.dircount == 1:
				self.pathline += " in 2 dirs"
			if self.dircount > 1:
				self.pathline += " in %i dirs" % (self.dircount)
			self.pathline += ")"
	
	def doit(self):
		self.parse()
		self.generate_pathline()
