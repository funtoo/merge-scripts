#!/usr/bin/python3

from zmq_msg_core import MultiPartMessage
import logging

fastpull_out = "/home/mirror/fastpull"

class SpiderMessage(MultiPartMessage):

	header = b"SPDR"

	def __init__(self, message, filename=""):
		self.message = message
		self.filename = filename

	@property
	def msg(self):
		return [ self.header, self.message.encode("utf-8"), self.filename.encode("utf-8") ]

	def log(self):
		logging.info("Sending SpiderMessage: %s." % self.message)

	@classmethod
	def from_msg(cls, msg):
		"Construct a SpiderMessage from a pyzmq message"
		if len(msg) != 3 or msg[0] != cls.header:
			#invalid
			return None
		return cls(msg[1].decode("utf-8"), msg[2].decode["utf-8"])