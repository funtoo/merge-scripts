#!/usr/bin/python3

import sys, os
from google.cloud import storage
import google.cloud.exceptions
from spider_common import *
import zmq
from zmq import Context

def google_upload_server():
	print("starting...")
	ctx = Context.instance()
	zmq_server = ctx.socket(zmq.ROUTER)
	zmq_server.bind("tcp://127.0.0.1:5556")
	google_client = storage.Client.from_service_account_json('goog_creds.json')
	print("got here")
	while True:
		print("sending ready message")
		ready_msg = SpiderMessage("ready")
		ready_msg.send(zmq_server)
		print("ready msg sent...")
		print("waiting for message")
		msg = zmq_server.recv_multipart()
		identity = msg[0]
		msg = msg[1:]
		msg = SpiderMessage.from_msg(msg)
		print("got message")
		if msg.message == "quit":
			print("Google upload server process exiting.")
			sys.exit(0)

		# if we didn't get a quit message, it's an upload message....
		print("Starting Google upload for %s..." % msg.filename)

		# add prefix to path to specify file for upload ("/home/mirror/distfiles"):
		disk_path = os.path.join(fastpull_out, msg.filename)

		# should strip non-important directories:
		google_blob = google_client.blob(msg.filename)

		try:
			google_blob.upload_from_file(disk_path)
		except google.cloud.exceptions.GoogleCloudError:
			# Tell client -- we failed to download this file
			fail_msg = SpiderMessage("fail", msg.filename)
			fail_msg.send(zmq_server)
		else:
			# Tell client -- we downloaded this file successfully
			good_msg = SpiderMessage("good", msg.filename)
			good_msg.send(zmq_server)

		print("Upload complete for %s." % msg.filename)



# vim: ts=4 sw=4 noet


google_upload_server()
