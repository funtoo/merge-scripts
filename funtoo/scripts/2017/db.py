#!/usr/bin/python3

"""
This module is a fourth attempt at some clean design patterns for encapsulating
SQLAlchemy database objects, so that they can more easily be embedded in other
objects. This code takes advantage of the SQLAlchemy ORM but purposely DOES NOT
USE SQLAlchemy's declarative syntax.  This is intentional because I've come to
the conclusion (after using declarative for a long time) that it's a pain in
the butt, not well documented, and hides a lot of the power of SQLAlchemy, so
it's a liability to use it.

Instead of using a declarative_base, database objects are simply derived from
object,and contain a _mapTable() method.  This method creates the Table object
and maps this new table to the class. This method is called by the Database
object when it is initialized:

orm = Database([User])

Above, we create a new Database object (to hold metadata, engine and session
information,) and we pass it a list or tuple of all objects to include as part
of our Database. Above, when Database's __init__() method is called, it will ensure
that the User class' _mapTable() method is called, so that the User table is
associated with our Database, and that these tables are created in the underlying
metadata.

This design pattern is created to allow for the creation of a library of
different kinds of database-aware objects, such as our user object. Then, other
code can import this code, and create a database schema with one or more of
these objects very easily:

orm = Database([Class1, Class2, Class3])

Classes that should be part of the Database can be included, and those that we
don't want can be omitted.

We could also create two or more schemas:

user_db = Database([User])
user_db.associate(engine="sqlite:///users.db")

product_db = Database([Product, ProductID, ProductCategory])
product_db.associate(engine="sqlite:///products.db")

tmp_db = Database([TmpObj, TmpObj2])
tmp_db.associate(engine="sqlite:///:memory:")

Or two different types of User objects:

class OtherUser(User):
	pass

user_db = Database([User])
other_user_db = Database([OtherUser])

Since all the session, engine and metadata stuff is encapsulated inside the
Database instances, this makes it a lot easier to use multiple database engines
from the same source code. At least, it provides a framework to make this a lot
less confusing:

for u in userdb.session.Query(User).all():
	print u

"""

import logging, os
from sqlalchemy import *
from sqlalchemy.orm import *
from sqlalchemy.ext.orderinglist import ordering_list
from sqlalchemy import exc

logging.basicConfig(level=logging.INFO)

class DatabaseError(Exception):
	def __init__(self, value):
		self.value = value
	def __str__(self):
		return self.value

"""
dbobject is a handy object to use as a base class for your database-aware objects. However,
using it is optional. It is perfectly OK to subclass a standard python new-style object.
"""

class dbobject(object):

	schema = None

	def __init__(self,id=None):
		self.id = id
	
	@classmethod
	def _mapTable(cls,db):
		mapper(cls, cls.__table__, primary_key=[cls.__table__.c.id])

class Database(object):

	"""
		connlist has the format:

		[ [ "sql:///foo.db" , [ Obj1, Obj2, Obj3 ] ], [ "sql///bar.db" , [ Obj4, Obj5, Obj6 ] ] ]

	"""

	connlist = []
	initOnly = False
	table_args = {}
	engine_args = {}

	def __init__(self,connlist=None,twophase=False,initOnly=None,table_args=None,engine_args=None):
		if connlist != None:
			self.connlist = connlist
		if initOnly != None:
			self.initOnly = initOnly
		if table_args:
			self.table_args = table_args
		if engine_args:
			self.engine_args = engine_args
		self.twophase = twophase
		self._session = None
		self._autodict = {}
		self.metadata = MetaData()
		self.sessionmaker = None
		self.initEngine(twophase=twophase,phase=1)

	def autoName(self,name):
		if name not in self._autodict:
			self._autodict[name] = 0
		self._autodict[name] += 1
		logging.info("autoname %s" % (name % self._autodict[name]))
		return name % self._autodict[name]
	
	def IntegerPrimaryKey(self,name):
		return Column(name, Integer, Sequence(self.autoName("id_seq_%s"), optional=True), primary_key=True)

	def UniqueString(self,name,length=80,index=True, nullable=False):
		return Column(name, String(length), unique=True, index=index, nullable=nullable)

	def secondPhase(self):
		self.initEngine(twophase=True,phase=2)

	def initEngine(self,twophase=False,phase=None):
		englist = []
		binds = {}
		if (not self.twophase or (self.twophase and phase == 2)):
			if len(self.connlist) == 1:
				connstring, dbobjs = self.connlist[0]
				logging.info("PID %s associating with database '%s'" % (os.getpid(), connstring))
				# pool_recycle should fix this: http://www.sqlalchemy.org/docs/dialects/mysql.html#connection-timeouts
				engine = create_engine(connstring, **self.engine_args)
				englist = [ [ engine , dbobjs ] ]
				for dbobj in dbobjs:
					binds[dbobj] = engine
			else:
				# vertical partitioning
				for connstring, dbobjs in self.connlist:
					logging.info("PID %s associating with database '%s'" % (os.getpid(), connstring))
					engine = create_engine(connstring, **self.engine_args)
					for dbobj in dbobjs:
						binds[dbobj] = engine
					englist.append([engine, dbobjs])
		for eng, dbobjs in englist:
			for cls in dbobjs:
				cls._makeTable(self,eng)
				if self.twophase and phase == 1:
					logging.info("PID %s creating table for %s, bound to %s" % ( os.getpid(), cls.__name__, eng ))
					cls.__table__.create(bind=eng,checkfirst=True)
				elif self.twophase and phase == 2:
					cls._mapTable(self)
				else:
					logging.info("PID %s creating table for %s, bound to %s" % ( os.getpid(), cls.__name__, eng ))
					cls.__table__.create(bind=eng,checkfirst=True)
					cls._mapTable(self)
		if (not self.twophase or (self.twophase and phase == 2)):
			if len(self.connlist) == 1:
				self.sessionmaker = sessionmaker()
			else:
				self.sessionmaker = sessionmaker(twophase=twophase)
			self.sessionmaker.configure(binds=binds)

	@property
	def session(self):
		if self.sessionmaker == None:
			raise DatabaseError("Database not associated with engine")
		if self._session == None:
			self._session = scoped_session(self.sessionmaker)
		return self._session()

# vim: ts=4 sw=4 noet

