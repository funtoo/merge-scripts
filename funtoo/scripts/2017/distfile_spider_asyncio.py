#!/usr/bin/python3

import random
import asyncio
import aiodns
import aioftp
import async_timeout
import aiohttp
import logging
from hashlib import sha512

from db_core import *
import time
from datetime import datetime, timedelta

resolver = aiohttp.AsyncResolver(nameservers=['8.8.8.8', '8.8.4.4'], timeout=3, tries=2)

thirdp = {}
with open('/var/git/meta-repo/kits/core-kit/profiles/thirdpartymirrors', 'r') as fd:
	for line in fd.readlines():
		ls = line.split()
		thirdp[ls[0]] = ls[1:]

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

async def ftp_fetch(host, path, port, login, password, outfile):
	client = aioftp.Client()
	await client.connect(host)
	await client.login("anonymous", "drobbins@funtoo.org")
	fd = open(outfile, 'wb')
	hash = sha512()
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

async def http_fetch(url, outfile):
	global resolver
	connector = aiohttp.TCPConnector(resolver=resolver,verify_ssl=False)
	async with aiohttp.ClientSession(connector=connector) as http_session:
		async with http_session.get(url) as response:
			if response.status != 200:
				return ("http_%s" % response.status, None)
			with open(outfile, 'wb') as fd:
				hash = sha512()
				while True:
					chunk = await response.content.read(chunk_size)
					if not chunk:
						break
					fd.write(chunk)
					hash.update(chunk)
	cur_digest = hash.hexdigest()
	return (None, cur_digest)

def distfile_fail(d, failtype=None):
	session = db.session
	d.last_failure_on = datetime.utcnow()
	d.failtype = failtype
	session.merge(d)
	session.commit()

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
	d1 = distfile.id[0]
	d2 = distfile.id[1]
	outdir = os.path.join("/home/mirror/fastpull", d1, d2)
	if not os.path.exists(outdir):
		os.makedirs(outdir)
	fastpull_outfile = os.path.join(outdir, distfile.id)
	if os.path.lexists(fastpull_outfile):
		os.unlink(fastpull_outfile)
	os.link(outfile, fastpull_outfile)

async def get_file(t_name,q):
	timeout = 60

	while True:
		last_fetch = datetime.utcnow()	
		# continually grab files....
		d = await q.get()
		uris = src_uri_process(d.src_uri, d.filename)
		outfile = os.path.join("/home/mirror/distfiles/", d.filename)
		mylist = list(next_uri(uris))
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
					sha = None
					with async_timeout.timeout(timeout):
						fail_mode, sha = await ftp_fetch(host, path, 21, "anonymous", "drobbins@funtoo.org", outfile)
				except Exception as e:
					fail_mode = str(e)
					if fail_mode == "Session is closed":
						raise e
			else:
				# handle http/https download --
				try:
					sha = None
					with async_timeout.timeout(timeout):
						fail_mode, sha = await http_fetch(real_uri, outfile)
				except Exception as e:
					fail_mode = str(e)
					if fail_mode == "Session is closed":
						raise e
			if sha == d.id:
				break

		# after we've iterated over all possible download locations, we do this once per distfile....

		if not fail_mode:
			if sha == d.id:
				# success! we can record our good work and break out of this loop...
				d.last_fetched_on = datetime.utcnow()
				session = db.session
				session.merge(d)
				session.commit()
				fastpull_index(outfile,d)
			else:
				fail_mode = "digest"

		if fail_mode:
			distfile_fail(d, fail_mode)
			# TODO: if we have failed with a bad digest, we need some follow-up process to query these so we can investigate...
			if fail_mode == "http_404":
				sys.stdout.write("4")
			elif fail_mode == "digest":
				sys.stdout.write("d")
			else:
				sys.stdout.write("x")
			sys.stdout.flush()
		else:
			sys.stdout.write(".")
			sys.stdout.flush()
	raise

queue_size = 50
query_size = 200
workr_size = 12 

q = asyncio.Queue(maxsize=queue_size)

async def qsize(q):
	while True:
		print("Queue size: %s" % q.qsize())
		await asyncio.sleep(5)

async def get_more_distfiles(q):
	global now
	time_cutoff = datetime.utcnow() - timedelta(hours=24)
	time_cutoff_hr = datetime.utcnow() - timedelta(hours=4)
	while True:
		print("MOR")
		# RIGHT NOW THIS WILL REPEATEDLY GRAB THE SAME STUFF
		session = db.session
		count = 0
		#query = db.session.query(Distfile).filter(Distfile.last_fetched_on == None).filter(or_(Distfile.last_attempted_on == None, Distfile.last_attempted_on < time_cutoff)).limit(query_size)
		query = db.session.query(Distfile)
		# avoid repeats for each run:
		query = query.filter(Distfile.last_attempted_on < now)
		query = query.filter(Distfile.last_fetched_on == None)
		#query = query.filter(Distfile.failtype != "digest")
		query = query.filter(Distfile.failtype != "http_404")
		#query = query.filter(Distfile.failtype.like("%SSL%"))
		#query = query.filter(Distfile.catpkg == "x11-misc/xearth")
		query = query.limit(query_size)
		query_list = list(query)
		if len(query_list) == 0:
			print("SLEEPING")
			await asyncio.sleep(5)
		else:
			for d in query_list:
				session = db.session
				if os.path.exists("/home/mirror/fastpull/%s/%s/%s" % ( d.id[0], d.id[1], d.id )):
					print("found in fastpull")
					d.last_fetched_on = datetime.utcnow()
					session.merge(d)
				d.last_attempted_on = datetime.utcnow()
				session.merge(d)
				session.commit()
				await q.put(d)

	await q.put(None)

logging.basicConfig(level=logging.ERROR)
logger = logging.getLogger("aioftp.client")
logger.setLevel(50)

chunk_size = 4096
db = AppDatabase(getConfig())
loop = asyncio.get_event_loop()
now = datetime.utcnow()

tasks = [
	asyncio.async(get_more_distfiles(q)),
	asyncio.async(qsize(q))
]
for x in range(0,workr_size):
	tasks.append(asyncio.async(get_file("task%s" % x, q)))

loop.run_until_complete(asyncio.gather(*tasks))


loop.close()

# vim: ts=4 sw=4 noet
