#!/usr/bin/python3

def google_upload_server():
	with open("out.foo","w") as foo:
		foo.write("HELLO")
	log = logging.getLogger('google_upload_server')
	log.info("Why hello there!")
	print("starting...")
	sys.stdout.flush()
	sys.stderr.flush()
	ctx = Context.instance()
	zmq_server = ctx.socket(zmq.ROUTER)
	zmq_server.bind("tcp://127.0.0.1:5556")
	print("Connecting to google storage...")
	google_client = storage.Client.from_service_account_json('goog_creds.json')
	print("Connection complete.")
	# google_upload_server will "pull" requests by sending "ready" messages to the spider.
	# A "ready" message means "we are ready to download the next file". The upload server
	# may get an actual "upload" message much later, when one is available to upload. Once
	# it completes, the upload server sends another "ready" message.

	while True:
		# tell client: we are ready for next file to upload.
		print("Sending ready message...")
		ready_msg = SpiderMessage("ready")
		ready_msg.send(zmq_server)

		# Now just wait for a message from the client... we can only upload a file at
		# a time so safe to wait here....
		msg = yield zmq_server.recv_multipart()
		msg = SpiderMessage.from_msg(msg)

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


