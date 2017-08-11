#!/usr/bin/env python3

from db_core import *
import time
from datetime import timedelta
from tornado import httpclient, gen, ioloop
from tornado.queues import Queue
from hashlib import sha512

@gen.coroutine

def addDistfiles(db, q, delta=None):
	keep_going = True
	if delta:
		start_time = datetime.utcnow()
	while keep_going:
		if delta:
			if start_time + delta > datetime.utcnow():
				keep_going = False
				break
		session = db.session
		distfiles = session.query(Distfile).filter(Distfile.last_fetched_on == None).filter(or_(Distfile.last_attempted_on == None, Distfile.last_attempted_on < time_cutoff)).limit(100):
		if len(distfiles) == 0:
			keep_going = False
			break
		for distfile in distfiles:
			distfile.last_attempted_on = datetime.utcnow() 
			session.merge(distfile)
			session.commit()
			yield q.put(distfile)

class AsyncDistfileFetcher(object):

	def __init__(self,distfile):
		self.distfile = distfile

	@gen.coroutine
	def fetch(self):
		self.outfile = open(distfile.filename,"w")
		self.hash = sha512()

		client = tornado.client.AsyncHTTPClient()
		AsyncHTTPClient.configure(None, max_body_size=1000000000)
		request = tornado.httpclient.HTTPRequest(
			url=url, 
			streaming_callback=on_chunk
			connect_timeout = 10,
			request_timeout = 600
		)
		try:
			yield client.fetch(request,on_done)
		except Exception as e:
			distfile.last_failed_on = datetime.utcnow()

	def on_chunk(self, chunk):
		self.outfile.write(chunk)
		self.hash.update(chunk)
	
	def on_done(self, response):
		if self.outfile:
			self.outfile.close()
		# verify sha512
		cur_digest = self.hash.hexdigest()
		
		session = db.session

		if cur_digest != self.distfile.id:
			# digest fail - record failure
			distfile.last_failure_on = datetime.utcnow()
			distfile.failtype = "digest"
		else:
			distfile.last_fetched_on = datetime.utcnow()

		session.add(distfile)
		session.commit()

@gen.coroutine
def main():
	fetch_count = 0	

	q = Queue(maxsize=20)

	db = getMySQLDatabase()

	start = time.time()
	fetching, fetched = set(), set()

	@gen.coroutine
	def fetch_distfile():
		distfile = yield q.get()
		try:
			print('fetching %s' % distfile.filename)
			fetcher = AsyncDistfileFetcher(distfile)
			yield fetcher.fetch()
		finally:
			fetch_count += 1
			q.task_done()

	@gen.coroutine
	def worker():
		while True:
			yield fetch_distfile()
	
	yield addDistfiles(db, q, timedelta(hours=2))

	for _ in range(concurrency):
		worker()

	yield q.join()
	print('Done in %d seconds, fetched %s distfiles.' % ( time.time() - start, fetch_count))

if __name__ == '__main__':
	import logging
	logging.basicConfig()
	io_loop = ioloop.IOLoop.current()
	io_loop.run_sync(main)

# vim: ts=4 sw=4 noet
