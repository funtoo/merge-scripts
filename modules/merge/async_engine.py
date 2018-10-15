#!/usr/bin/python3

import asyncio
from concurrent.futures import ThreadPoolExecutor
from collections import defaultdict
from queue import Queue, Empty

class AsyncEngine:
	
	queue_size = 60000
	
	def __init__(self, num_threads=40):
		self.task_q = Queue(maxsize=self.queue_size)
		self.num_threads = num_threads
		self.thread_exec = ThreadPoolExecutor(max_workers=self.num_threads)
		self.workers = []
		self.loop = asyncio.get_event_loop()
		self.keep_running = True
	
	def start_threads(self, enable_workers=True):
		if enable_workers is True:
			for x in range(0, self.num_threads):
				self.loop.run_in_executor(self.thread_exec, self._worker)
		print("Started %s workers." % self.num_threads)
	
	def add_worker(self, w):
		self.workers.append(self.thread_exec.submit(w))
			
	def enqueue(self, **kwargs):
		self.task_q.put(kwargs)
	
	def _worker(self):
		while self.keep_running is True or (self.keep_running is False and self.task_q.qsize() > 0 ):
			try:
				kwargs = defaultdict(lambda: None, self.task_q.get(timeout=3))
				self.worker_thread(**kwargs)
			except Empty:
				continue
				
	async def wait_for_workers_to_finish(self):
		self.keep_running = False
		await asyncio.gather(*self.workers)
		
	def exit_handler(self):
		"""something for atexit.register"""
		self.loop.run_until_complete(asyncio.gather(
			asyncio.ensure_future(self.wait_for_workers_to_finish())
		))
	
		
	def worker_thread(self, **kwargs):
		print("blarg")
	
	
# vim: ts=4 sw=4 noet
