#!/usr/bin/env python3

from db_core import *
import time
from datetime import datetime, timedelta
import tornado
from tornado import httpclient, gen, ioloop
from tornado.queues import Queue
from hashlib import sha512
import socket
import string
import random

@gen.coroutine

def addDistfiles(db, q):
	keep_going = True
	time_cutoff = datetime.utcnow() - timedelta(hours=24)
	session = db.session
	distfiles = session.query(Distfile).filter(Distfile.last_fetched_on == None).filter(or_(Distfile.last_attempted_on == None, Distfile.last_attempted_on < time_cutoff)).limit(2000)
	distfiles = list(distfiles)
	print("Got %s distfiles" % len(distfiles))
	for distfile in distfiles:
		distfile.last_attempted_on = datetime.utcnow() 
		session.merge(distfile)
		session.commit()
		yield q.put(distfile)

class AsyncDistfileFetcher(object):

	def __init__(self,db,distfile):
		self.db = db
		self.outfile = None
		self.distfile = distfile
		self.hash = sha512()
		self.char = random.choice(string.ascii_lowercase)

	@gen.coroutine
	def fetch(self):
		urls = self.distfile.src_uri.split("\n")
		pos = 0
		while(pos < len(urls) and not urls[pos].startswith("http")):
			pos += 1
		if pos == len(urls):
			print("NO valid url")
			return
		url = urls[pos]

		print(url)
		client = tornado.httpclient.AsyncHTTPClient()
		tornado.httpclient.AsyncHTTPClient.configure(None, max_body_size=1000000000)
		request = tornado.httpclient.HTTPRequest(
			url=url, 
			streaming_callback=self.on_chunk,
			connect_timeout = 10,
			request_timeout = 600
		)
		try:
			print("Fetching %s" % self.distfile.filename)
			yield client.fetch(request,self.on_done)
		except tornado.httpclient.HTTPError as e:
			self.distfile.last_failure_on = datetime.utcnow()
			self.distfile.failtype = "http_%s" % e.code

			session = self.db.session
			session.merge(self.distfile)
			session.commit()

		except ValueError:
			print("Couldn't grab from %s" % url)
		except socket.gaierror:
			print("Gaierror on %s" % url)
		except Exception as e:
			raise

	def on_chunk(self, chunk):
		if not self.outfile:
			print("Opening %s for writing" % self.distfile.filename) 
			self.outfile = open("distfiles/" + self.distfile.filename,"wb")
		sys.stdout.write(self.char)
		sys.stdout.flush()
		self.outfile.write(chunk)
		self.hash.update(chunk)
	
	def on_done(self, response):
		print("DONE", response)
		if self.outfile:
			self.outfile.close()
		# verify sha512
		cur_digest = self.hash.hexdigest()
		
		session = self.db.session

		if cur_digest != self.distfile.id:
			# digest fail - record failure
			self.distfile.last_failure_on = datetime.utcnow()
			self.distfile.failtype = "digest"
		else:
			self.distfile.last_fetched_on = datetime.utcnow()

		session.merge(self.distfile)
		session.commit()

@gen.coroutine
def main():
	fetch_count = 0	

	q = Queue(maxsize=200)

	db = AppDatabase(getConfig())

	start = time.time()

	@gen.coroutine
	def fetch_distfile(db):
		distfile = yield q.get()
		print("got", distfile.filename)
		try:
			print('fetching %s' % distfile.filename)
			fetcher = AsyncDistfileFetcher(db,distfile)
			yield fetcher.fetch()
		finally:
			q.task_done()

	@gen.coroutine
	def worker():
		while True:
			yield fetch_distfile(db)
	
	yield addDistfiles(db, q)

	for _ in range(8):
		worker()

	while True:
		yield q.join()
		yield addDistfiles(db, q)

	print('Done in %d seconds, fetched %s distfiles.' % ( time.time() - start, fetch_count))

if __name__ == '__main__':
	import logging
	logging.basicConfig()
	io_loop = ioloop.IOLoop.current()
	io_loop.run_sync(main)

# vim: ts=4 sw=4 noet
