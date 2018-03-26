#!/usr/bin/python3

import sys, os
from google.cloud import storage
import google.cloud.exceptions
from spider_common import *

google_client = storage.Client.from_service_account_json('goog_creds.json')

def google_upload(filename):
		disk_path = os.path.join(fastpull_out, filename)
		# should strip non-important directories:
		google_blob = google_client.blob(filename)

		try:
			google_blob.upload_from_file(disk_path)
		except google.cloud.exceptions.GoogleCloudError:
			return False
		else:
			return True

# vim: ts=4 sw=4 noet