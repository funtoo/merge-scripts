#!/usr/bin/python3

import os
from tornado.httpserver import HTTPServer
import tornado.web
import tornado.gen
from tornado.ioloop import IOLoop
from db_core import *
from tornado.log import enable_pretty_logging
enable_pretty_logging()
import sqlalchemy.exc

class RedirectHandler(tornado.web.RequestHandler):

	redirect_url = "https://storage.googleapis.com/fastpull-us/%s/%s/%s"

	def get(self,fn):
		fn = os.path.basename(fn)
		success = False
		for attempt in range(0,3):
			try:
				with self.application.db.get_session() as session:
					result = session.query(self.application.db.Distfile).filter(self.application.db.Distfile.filename == fn).first()
					if not result:
						if not fn.endswith("/") and len(fn):
							miss = session.query(self.application.db.MissingRequestedFile).filter(self.application.db.MissingRequestedFile.filename == fn).first()
							if miss is None:
								miss = self.application.db.MissingRequestedFile()
								miss.filename = fn
							miss.last_failure_on = datetime.utcnow()
							miss.failcount += 1
							session.add(miss)
							session.commit()
					else:
						rand_id = result.rand_id
						success = True
						session.close()
						break
			except sqlalchemy.exc.OperationalError:
				pass
			except sqlalchemy.exc.SQLAlchemyError:
				pass
		if success:
			url = self.redirect_url % ( rand_id[0], rand_id[1], rand_id )
			self.redirect(url, permanent=False)
		else:
			self.set_status(404)

settings = {
	"xsrf_cookies": False,
	"cache_json" : False,
}

class Application(tornado.web.Application):

	name = "fastpull alpha service"
	handlers = [
		(r"/distfiles/distfiles/(.*)", RedirectHandler),
		(r"/distfiles/(.*)", RedirectHandler),
		(r"/(.*)", RedirectHandler),
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
