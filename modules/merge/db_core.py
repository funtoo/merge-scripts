#!/usr/bin/python3

import sys
from merge.config import Configuration
from contextlib import contextmanager
from sqlalchemy import create_engine, Integer, Boolean, Column, String, BigInteger, DateTime, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, scoped_session
from datetime import datetime
from sqlalchemy.schema import MetaData

app_config = Configuration()

class Database(object):

	# Abstract database class with contextmanager pattern.

	@contextmanager
	def get_session(self):
		session = scoped_session(sessionmaker(bind=self.engine))
		try:
			yield session
			session.commit()
		except:
			session.rollback()
			raise
		finally:
			session.close()

class FastPullDatabase(Database):

	MetaData = MetaData()
	
	def __init__(self):
		
		self.Base = declarative_base(self.MetaData)
		
		class Distfile(self.Base):

			# A distfile represents a single file for download. A distfile has a filename, which is its local filename
			# after it is downloaded, as well as one or more SRC_URIs, which define where the file can be downloaded
			# from -- and may reference a filename different from the 'filename' field (in the case of '->' used within
			# the SRC_URI). In addition, the 'id' field is an ASCII SHA512 checksum from the manifest, and catpkg and
			# kit record the catpkg and kit that reference this file, respectively.

			# Note that with the current data model, it is possible that multiple catpkgs and/or kits may reference
			# the same file, and they will overwrite each other's entries in the distfile database. So Distfile should
			# be used as a complete list of distfiles, but not as a complete mapping of catpkg -> distfile.

			# Distfile records are used for SRC_URI and mirror-related tracking tasks. They record the last time
			# a particular filename was seen in the 'updated_on field' and the 'mirror' field indicates whether the
			# file should be mirrored (inverse of RESTRICT="mirror")

			__tablename__ = "distfiles"


			id = Column('id', String(128), primary_key=True)                            # sha512 in ASCII
			rand_id = Column('rand_id', String(128), index=True)                        # fastpull_id
			filename = Column('filename', String(255), primary_key=True)                # filename on disk

			# the id/filename is a composite key, because a SHA512 may exist under potentially multiple filenames, and we
			# want to be aware of these situations.

			digest_type = Column('digest_type', String(20))
			alt_digest = Column('alt_digest', Text)
			size = Column('size', BigInteger)
			catpkg = Column('catpkg', String(255), index=True)                          # catpkg
			kit = Column('kit', String(40), index=True)                                 # source kit
			src_uri = Column('src_uri', Text)                                           # src_uris -- filename may be different as Portage can rename -- stored in order of appearance, one per line
			mirror = Column('mirror', Boolean, default=True)
			last_fetched_on = Column('last_fetched_on', DateTime)                       # set to a datetime the last time we successfully fetched the file                    # last failure

			# deprecated fields:

			last_attempted_on = Column('last_attempted_on', DateTime)
			last_failure_on = Column('last_failure_on', DateTime)
			failtype = Column('failtype', Text)
			priority = Column('priority', Integer, default=0)


		class QueuedDistfile(self.Base):

			__tablename__ = 'queued_distfiles'

			id = Column(Integer, primary_key=True)
			filename = Column('filename', String(255), index=True)                # filename on disk
			catpkg = Column('catpkg', String(255), index=True)                    # catpkg
			kit = Column('kit', String(40), index=True)                           # source kit
			branch = Column('branch', String(40), index=True)                     # source kit
			src_uri	= Column('src_uri', Text)                                           # src_uris -- filename may be different as Portage can rename -- stored in order of appearance, one per line
			size = Column('size', BigInteger)
			mirror = Column('mirror', Boolean, default=True)
			digest_type = Column('digest_type', String(20))
			digest = Column('digest', Text)
			added_on = Column('added_on', DateTime, default=datetime.utcnow)
			priority = Column('priority', Integer, default=0)
			last_attempted_on = Column('last_attempted_on', DateTime)
			last_failure_on = Column('last_failure_on', DateTime)
			failcount = Column(Integer, default=0)
			failtype = Column('failtype', Text)

		class MissingRequestedFile(self.Base):

			__tablename__ = "missing_requested_files"

			id = Column(Integer, primary_key=True)
			filename = Column(String(255), index=True)
			failcount = Column(Integer, default=0)
			last_failure_on = Column(DateTime, default=None)

		class MissingManifestFailure(self.Base):

			__tablename__ = 'manifest_failures'

			filename = Column('filename', String(255), primary_key=True)                # filename on disk
			catpkg = Column('catpkg', String(255), primary_key=True)                    # catpkg
			kit = Column('kit', String(40), primary_key=True)                           # source kit
			branch = Column('branch', String(40), primary_key=True)                     # source kit
			src_uri	= Column('src_uri', Text)                                           # src_uris -- filename may be different as Portage can rename -- stored in order of appearance, one per line
			failtype = Column('failtype', String(8))                                    # 'missing'
			fail_on = Column('fail_on', DateTime)                                       #last failure

		self.Distfile = Distfile
		self.QueuedDistfile = QueuedDistfile
		self.MissingManifestFailure = MissingManifestFailure
		self.MissingRequestedFile = MissingRequestedFile
		
		self.engine = create_engine(app_config.db_connection("fastpull"), strategy='threadlocal', pool_size=40, max_overflow=80)
		self.Base.metadata.create_all(self.engine)

if __name__ == "__main__":

	# This migration code is designed to migrate old Distfile() records to the new QueuedDistfile() records:

	if len(sys.argv) > 1 and sys.argv[1] == "migrate":
		db = FastPullDatabase()
		print("migrating...")
		with db.get_session() as session:
			for d in session.query(db.Distfile).filter(db.Distfile.last_fetched_on == None):
				qd = db.QueuedDistfile()
				qd.filename = d.filename
				qd.catpkg = d.catpkg
				qd.kit = d.kit
				qd.src_uri = d.src_uri
				qd.size = d.size
				qd.mirror = d.mirror
				qd.digest_type = "sha512"
				qd.added_on = datetime.utcnow()
				qd.priority = d.priority
				qd.last_attempted_on = d.last_attempted_on
				qd.last_failure_on = d.last_failure_on
				qd.failcount = 1
				qd.failtype = d.failtype
				session.add(qd)
				session.delete(d)
				session.commit()
				sys.stdout.write(">")
				sys.stdout.flush()
		print()
	elif len(sys.argv) > 1 and sys.argv[1] == "fixup":
		# this code should detect and fixup things that need to be re-fetched.
		db = FastPullDatabase()
		print("fixing up old random ids...")
		with db.get_session() as session:
			for d in session.query(db.Distfile):
				try:
					myval = int(d.rand_id, 16)
				except ValueError:
					# not hexadecimal... need to re-fetch, etc.
					print(d.filename)
					qd = db.QueuedDistfile()
					qd.filename = d.filename
					qd.catpkg = d.catpkg
					qd.kit = d.kit
					qd.src_uri = d.src_uri
					qd.size = d.size
					qd.mirror = d.mirror
					qd.digest_type = "sha512"
					qd.added_on = datetime.utcnow()
					qd.priority = d.priority
					qd.last_attempted_on = None
					qd.last_failure_on = None
					qd.failcount = 0
					qd.failtype = None
					session.add(qd)
					session.delete(d)
					sys.stdout.write(">")
					sys.stdout.flush()
			session.commit()
	
	else:
		db = FastPullDatabase()
		with db.get_session() as session:
			for x in session.query(db.QueuedDistfile).filter(db.QueuedDistfile.last_attempted_on == None):
				print(x.filename)

# vim: ts=4 sw=4 noet
