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
		with self.application.db.get_session() as session:
			result = session.query(self.application.db.Distfile).filter(self.application.db.Distfile.filename == fn).first()
			if not result:
				self.set_status(404)
			else:
				url = self.redirect_url % ( result.id[0], result.id[1], result.id )
				self.redirect(url, permanent=False)

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
application.db = FastPullDatabase()
http_server = HTTPServer(application, xheaders=True)
http_server.bind(8080, "127.0.0.1")
http_server.start()

# start ioloop
IOLoop.instance().start()

# vim: ts=4 sw=4 noet
