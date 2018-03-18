#!/usr/bin/python3

from db_config import get_app_config
from contextlib import contextmanager
from sqlalchemy import create_engine, ForeignKey, Integer, Boolean, Column, String, ForeignKey, BigInteger, DateTime, Text, Numeric
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

app_config = get_app_config()

class Database(object):

	# Abstract database class with contextmanager pattern.

	@property
	@contextmanager
	def session(self):
		session = self.sessionmaker()
		try:
			yield session
			session.commit()
		except:
			session.rollback()
			raise
		finally:
			session.close()

class FastPullDatabase(Database):

	Base = declarative_base()

	def __init__(self):
		self.engine = create_engine(app_config["main"]["connection"], pool_recycle=900)

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
			rand_id = Column('rand_id', String(128), index=True)       # fastpull_id
			filename = Column('filename', String(255), primary_key=True)                # filename on disk

			# the id/filename is a composite key, because a SHA512 may exist under potentially multiple filenames, and we
			# want to be aware of these situations.

			size = Column('size', BigInteger)
			catpkg = Column('catpkg', String(255), index=True)                          # catpkg
			kit = Column('kit', String(40), index=True)                                 # source kit
			src_uri = Column('src_uri', Text)                                           # src_uris -- filename may be different as Portage can rename -- stored in order of appearance, one per line
			mirror = Column('mirror', Boolean, default=True)
			last_updated_on = Column('last_updated_on', DateTime)                       # set to a datetime to know the last time we updated/recorded this entry from source ebuilds
			last_attempted_on = Column('last_attempted_on', DateTime)                   # set to a datetime the last time we tried to fetch the file
			last_fetched_on = Column('last_fetched_on', DateTime)                       # set to a datetime the last time we successfully fetched the file
			last_failure_on = Column('last_failure_on', DateTime)                       # last failure
			failtype = Column('failtype', Text)                                         # 'digest', '404'
			priority = Column('priority', Integer, default=0)

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
		self.MissingManifestFailure = MissingManifestFailure

		self.Base.metadata.create_all(self.engine)
		self.sessionmaker = sessionmaker(bind=self.engine)

if __name__ == "__main__":

	db = FastPullDatabase()
	with db.session as session:
		for x in session.query(db.Distfile):
			print(x.filename)

# vim: ts=4 sw=4 noet
