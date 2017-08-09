#!/usr/bin/python3

from db import *
from db_config import *
import os
import hashlib
import random, string
import csv
import binascii
import sys

class Distfile(dbobject):

	# Distfile records are used for SRC_URI and mirror-related tracking tasks. They record the last time
	# a particular filename was seen.

	@classmethod
	def _makeTable(cls,db,engine):
		cls.db = db
		cls.__table__ = Table('distfiles', db.metadata,
			Column('id', String(128), primary_key=True), # sha512 in ASCII
			Column('filename', String(255), primary_key=True), # filename on disk

			# the id/filename is a composite key, because a SHA512 may exist under potentially multiple filenames, and we
			# want to be aware of these situations.

			Column('size', Integer),
			Column('catpkg', String(255), index=True), # catpkg
			Column('kit', String(40), index=True), # source kit
			Column('src_uri', Text), # src_uris -- filename may be different as Portage can rename -- stored in order of appearance, one per line
			Column('updated_on', DateTime), # set to a datetime to know the last time we saw this file
			**db.table_args
		)

def AppDatabase(config,serverMode=False):
	db = Database(
		twophase=serverMode,
		connlist=[[ config["main"]["connection"], [ Distfile ]]],
		table_args = { 'mysql_engine':'InnoDB','mysql_charset':'utf8' },
		engine_args = { 'pool_recycle' : 3600 },
	)
	return db

db = AppDatabase(getConfig())

# vim: ts=4 sw=4 noet
