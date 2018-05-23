#!/usr/bin/python3

import os
from google.cloud import storage
import google.cloud.exceptions

google_client = storage.Client.from_service_account_json('goog_creds.json')
bucket = google_client.get_bucket("fastpull-us")
def google_upload(filename):
	print("starting upload")
	disk_path = os.path.join(config.get_path("fastpull_out"), filename)
	print("disk path", disk_path)
	# should strip non-important directories:
	google_blob = bucket.blob(filename)
	print("filename", filename)
	try:
		google_blob.upload_from_filename(disk_path)
	except google.cloud.exceptions.GoogleCloudError:
		print("upload failed")
		return False
	else:
		print("upload succeeded")
		return True

# vim: ts=4 sw=4 noet
