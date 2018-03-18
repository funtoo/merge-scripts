#!/usr/bin/python3

import os, sys
import random
import asyncio
import aioftp
import async_timeout
import aiohttp
import logging
from hashlib import sha256, sha512
import socket

from db_core import *
from datetime import datetime, timedelta

resolver = aiohttp.AsyncResolver(nameservers=['8.8.8.8', '8.8.4.4'], timeout=3, tries=2)

thirdp = {}
with open('/var/git/meta-repo/kits/core-kit/profiles/thirdpartymirrors', 'r') as fd:
	for line in fd.readlines():
		ls = line.split()
		thirdp[ls[0]] = ls[1:]

# TODO: only try to download one filename of the same name at a time.

def src_uri_process(uri_text, fn):

	# converts \n delimited text of all SRC_URIs for file from ebuild into a list containing:
	# [ mirror_path, [ mirrors ] -- where mirrors[0] + "/" + mirror_path is a valid dl path
	#
	# or string, where string is just a single download path.

	global thirdp
	uris_to_process = uri_text.split("\n")
	uris_to_process = [ "http://distfiles.gentoo.org/distfiles/" + fn ] + uris_to_process
	out_uris = []
	for uri in uris_to_process:
		if len(uri) == 0:
			continue
		if uri.startswith("mirror://"):
			uri = uri[9:]
			mirror_name = uri.split("/")[0]
			mirror_path = "/".join(uri.split("/")[1:])
			if mirror_name not in thirdp:
				print("!!! Error: no third-party mirror defined for %s" % mirror_name)
				continue
			out_uris.append([mirror_path, thirdp[mirror_name]])
		else:
			out_uris.append(uri)
	return out_uris

def get_sha512(fn):
		with open(fn, "rb") as data:
			my_hash = sha512(data=data.read())
			return hash.hexdigest()

async def ftp_fetch(host, path, outfile, digest_func):
	client = aioftp.Client()
	await client.connect(host)
	await client.login("anonymous", "drobbins@funtoo.org")
	fd = open(outfile, 'wb')
	hash = digest_func()
	if not await client.exists(path):
		return ("ftp_missing", None)
	stream = await client.download_stream(path)
	async for block in stream.iter_by_block(chunk_size):
		fd.write(block)
		hash.update(block)
	await stream.finish()
	cur_digest = hash.hexdigest()
	await client.quit()
	fd.close()
	return (None, cur_digest)

async def http_fetch(url, outfile, digest_func):
	global resolver
	connector = aiohttp.TCPConnector(family=socket.AF_INET,resolver=resolver,verify_ssl=False)
	async with aiohttp.ClientSession(connector=connector) as http_session:
		async with http_session.get(url) as response:
			if response.status != 200:
				return ("http_%s" % response.status, None)
			with open(outfile, 'wb') as fd:
				hash = digest_func()
				while True:
					chunk = await response.content.read(chunk_size)
					if not chunk:
						break
					fd.write(chunk)
					hash.update(chunk)
	cur_digest = hash.hexdigest()
	return (None, cur_digest)


def next_uri(uri_expand):
	for src_uri in uri_expand:
		if type(src_uri) == list:
			for uri in src_uri[1]:
				real_uri = uri
				if not real_uri.endswith("/"):
					real_uri += "/"
				real_uri += src_uri[0]
				yield real_uri
		else:
			yield src_uri

def fastpull_index(outfile,distfile):
	# add to fastpull.
	d1 = distfile.rand_id[0]
	d2 = distfile.rand_id[1]
	outdir = os.path.join("/home/mirror/fastpull", d1, d2)
	if not os.path.exists(outdir):
		os.makedirs(outdir)
	fastpull_outfile = os.path.join(outdir, distfile.rand_id)
	if os.path.lexists(fastpull_outfile):
		os.unlink(fastpull_outfile)
	os.link(outfile, fastpull_outfile)

async def get_file(db, task_num, q):
	timeout = 60

	while True:

		# continually grab files....
		d_id = await q.get()

		with db.get_session() as session:

			# This will attach to our current session
			d = session.query(db.QueuedDistfile).filter(db.QueuedDistfile.id == d_id).first()
			if d is None:
				# no longer exists
				continue

			if d.digest_type == "sha256":
				digest_func = sha256
			elif d.digest_type == "sha512":
				digest_func = sha512

			if d.src_uri is None:
				print("Error: for file %s, SRC_URI is None; skipping." % d.filename)
				try:
					session.delete(d)
					session.commit()
				except sqlalchemy.exc.InvalidRequestError:
					# already deleted by someone else
					pass
				# move to next file...
				continue

			uris = src_uri_process(d.src_uri, d.filename)
			outfile = os.path.join("/home/mirror/distfiles/", d.filename)
			mylist = list(next_uri(uris))
			fail_mode = None

			# if we have a sha512, then we can to a pre-download check to see if the file has been grabbed before.
			if d.digest_type == "sha512":
				existing = session.query(db.Distfile).filter(db.Distfile.id == d.digest).first()
				if existing:
					print("%s already downloaded; skipping." % d.filename)
					session.delete(d)
					session.commit()
					# move to next file....
					continue

			for real_uri in mylist:
				# iterate through each potential URI for downloading a particular distfile. We'll keep trying until
				# we find one that works.

				# fail_mode will effectively store the last reason why our download failed. We reset it each iteration,
				# which is what we want. If fail_mode is set to something after our big loop exits, we know we have
				# truly failed downloading this distfile.

				fail_mode = None

				if real_uri.startswith("ftp://"):
					# handle ftp download --
					host_parts = real_uri[6:]
					host = host_parts.split("/")[0]
					path = "/".join(host_parts.split("/")[1:])
					try:
						digest = None
						with async_timeout.timeout(timeout):
							fail_mode, digest = await ftp_fetch(host, path, outfile, digest_func)
					except Exception as e:
						fail_mode = str(e)
						if fail_mode == "Session is closed":
							raise e
				else:
					# handle http/https download --
					try:
						digest = None
						with async_timeout.timeout(timeout):
							fail_mode, digest = await http_fetch(real_uri, outfile, digest_func)
					except Exception as e:
						fail_mode = str(e)
						if fail_mode == "Session is closed":
							raise e

				if digest == d.digest:
					# success! we can record our fine ketchup:

					if d.digest_type == "sha512":
						my_id = d.digest
					else:
						my_id = get_sha512(outfile)

					existing = session.query(db.Distfile).filter(db.Distfile.id == my_id).first()

					if existing is not None:
						print("Downloaded %s, but already exists in our db. Skipping." % d.filename)
						session.delete(d)
						session.commit()
						os.unlink(outfile)
						# done; process next distfile
						break

					d_final = db.Distfile()

					d_final.id = my_id
					d_final.rand_id = ''.join(random.choice('abcdef0123456789') for _ in range(128))
					d_final.filename = d.filename
					d_final.digest_type = d.digest_type
					if d.digest_type != "sha512":
						d_final.alt_digest = d.digest
					d_final.size = d.size
					d_final.catpkg = d.catpkg
					d_final.kit = d.kit
					d_final.src_uri = d.src_uri
					d_final.mirror = d.mirror
					d_final.last_fetched_on = datetime.utcnow()

					session.add(d_final)
					session.delete(d)
					session.commit()

					fastpull_index(outfile,d)
					os.unlink(outfile)
					# done; process next distfile
					break
				else:
					fail_mode = "digest"

			if fail_mode:
				# If we tried all SRC_URIs, and still failed, we will end up here, with fail_mode set to something.
				d.last_failure_on = d.last_attempted_on = datetime.utcnow()
				d.failtype = fail_mode
				d.failcount += 1
				session.merge(d)
				session.commit()
				if fail_mode == "http_404":
					sys.stdout.write("4")
				elif fail_mode == "digest":
					sys.stdout.write("d")
				else:
					sys.stdout.write("x")
				sys.stdout.flush()
			else:
				# we end up here if we are successful. Do successful output.
				sys.stdout.write(".")
				sys.stdout.flush()

queue_size = 50
query_size = 200
workr_size = 12 

q = asyncio.Queue(maxsize=queue_size)

async def qsize(q):
	while True:
		print("Queue size: %s" % q.qsize())
		await asyncio.sleep(5)

async def get_more_distfiles(db, q):
	global now
	time_cutoff = datetime.utcnow() - timedelta(hours=24)
	time_cutoff_hr = datetime.utcnow() - timedelta(hours=4)
	while True:
		print("MOR")
		# RIGHT NOW THIS WILL REPEATEDLY GRAB THE SAME STUFF
		count = 0
		with db.get_session() as session:
			results = session.query(db.QueuedDistfile).filter(db.QueuedDistfile.last_attempted_on == None)
			results = results.limit(query_size)
			if results.count() == 0:
				print("SLEEPING")
				await asyncio.sleep(5)
			else:
				for d in results:
					await q.put(d.id)

logging.basicConfig(level=logging.ERROR)
logger = logging.getLogger("aioftp.client")
logger.setLevel(50)

chunk_size = 4096
db = FastPullDatabase()
loop = asyncio.get_event_loop()
now = datetime.utcnow()


tasks = [
	asyncio.async(get_more_distfiles(db, q)),
	asyncio.async(qsize(q))
]

for x in range(0,workr_size):
	tasks.append(asyncio.async(get_file(db, x, q)))

loop.run_until_complete(asyncio.gather(*tasks))
loop.close()

# vim: ts=4 sw=4 noet
