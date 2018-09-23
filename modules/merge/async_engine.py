#!/usr/bin/python3

import asyncio
from concurrent.futures import ThreadPoolExecutor
from collections import defaultdict


class AsyncEngine:
	
	queue_size = 60000
	
	def __init__(self, num_threads=40):
		self.task_q = asyncio.Queue(maxsize=self.queue_size)
		self.num_threads = num_threads
		self.thread_exec = ThreadPoolExecutor(max_workers=self.num_threads)
		self.tasks = []
		self.loop = asyncio.get_event_loop()
	
	def start(self, enable_workers=True):
		if enable_workers is True:
			for x in range(0, self.num_threads):
				self.tasks.append(self.thread_exec.submit(self._worker,x))
		# run forever
		self.loop.run_until_complete(asyncio.gather(*self.tasks))
		self.loop.close()
	
	def add_worker(self, w):
		self.tasks.append(self.thread_exec.submit(w))
			
	def enqueue(self, **kwargs):
		asyncio.ensure_future(self.task_q.put(kwargs), loop=self.loop)
	
	async def _worker(self, worker_num):
		print("Worker number %s." % worker_num)
		
		while True:
			kwargs = defaultdict(lambda: None, await self.task_q.get())
			await self.worker_thread(**kwargs)
			
	async def worker_thread(self, **kwargs):
		print("blarg")
	
	
# vim: ts=4 sw=4 noet

if __name__ == "__main__":
	a = AsyncEngine()
	for x in range(1,100):
		a.enqueue(foo="bar")
	print("Started!")
	a.start()