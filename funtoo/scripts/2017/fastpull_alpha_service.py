#!/usr/bin/python3
import os
import json
from tornado.httpserver import HTTPServer
import tornado.web
import tornado.gen
from tornado.ioloop import IOLoop
from db_core import *

class RedirectHandler(tornado.web.RequestHandler):

	redirect_url = "https://storage.googleapis.com/fastpull-us/%s/%s/%s"

	def get(self,fn):
		session = self.session
		result = session.query(Distfile).filter(Distfile.filename == fn).first()
		if not result:
			self.set_status(404)
		else:
			url = redirect_url % ( result.id[0], result.id[1], result.id )
			self.redirect(url, permanent=False)

	@property
	def session(self):
		return self.application.db.session

	@property
	def sub_session(self):
		return self.application.sub_db.session
   
   
   # Remove the session when we are done...

	def finish(self,chunk=None):
		tornado.web.RequestHandler.finish(self,chunk)
		self.session.close_all()

settings = {
	"xsrf_cookies": False,
	"cache_json" : False,
}

class Application(tornado.web.Application):

	name = "fastpull alpha service"
	handlers = [
		("/alpha/(.*)", RedirectHandler),
	]

	def __init__(self):
		tornado.web.Application.__init__(self, self.handlers, **settings)

application = Application()
application.db = AppDatabase(getConfig(), serverMode=False)
http_server = HTTPServer(application, xheaders=True)
http_server.bind(8080, "127.0.0.1")
http_server.start()

# start ioloop
IOLoop.instance().start()



# vim: ts=4 sw=4 noet
