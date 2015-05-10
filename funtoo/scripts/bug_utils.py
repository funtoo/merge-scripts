#!/usr/bin/python3

import urllib
from urllib.request import urlopen
from urllib.request import Request
import http
import hashlib

import requests
import sys
import json
import base64

def gen_base64(username, password):
	d_b_encode = '%s:%s' % (username, password)
	dEncode = bytes(d_b_encode,"utf-8")
	bdEncode = base64.encodestring(dEncode).decode("utf-8")[:-1]
	return bdEncode

class JIRA(object):

	def __init__(self, url, user, password):
		self.url = url
		self.user = user
		self.password = password

	def getAuth(self):
		base64string = gen_base64(self.user, self.password)
		return	"Basic %s" % base64string

	def getAllIssues(self,params={}):
		url = self.url + '/search'
		r = requests.get(url, params=params)
		print(r.url)
		if r.status_code == requests.codes.ok:
			return r.json()
		return None

	def createIssue(self,project,title,description,issuetype="Bug",extrafields={}):
		url = self.url + '/issue/'
		headers = { "Content-type": "application/json", "Accept": "application/json", "Authorization": self.getAuth() }
		issue = { "fields" : { 
			'project' : { 'key' : project },
			'summary' : title,
			'description' : description,
			'issuetype' : { 'name' : issuetype }
			}
		}
		issue["fields"].update(extrafields)

		r = requests.post(url, data=json.dumps(issue), headers=headers)
		j = r.json()
		if 'key' in j:
			return j['key']
		print(r.text)
		return None

	def createSubTask(self,parentkey,project,title,description):
		return self.createIssue(project=project,title=title,description=description,issuetype="Sub-task",extrafields={'parent' : parentkey})
	def closeDuplicateIssue(self,orig_issue, dup_issue):
		url = self.url + '/issue/' + dup_issue['key'] + '/transitions'
		headers = { "Content-type": "application/json", "Accept": "application/json", "Authorization": self.getAuth() }
		data = { 'update' : 
			{ 'comment' : 
				[ 
					{ 'add' : { 'body' : 'Duplicate of %s' % orig_issue['key'] } } 
				] 
			} 
		}
		data['fields'] = { 'resolution' : { 'name' : 'Duplicate' } }
		data['transition'] = { 'id' :  831 }
		print(json.dumps(data))
		print(url)
		r = requests.post(url, data=json.dumps(data), headers=headers)
		print(r.text)
		if r.status_code == requests.codes.ok:
			return True
		else:
			return False

class GitHub(object):

	def __init__(self, user, password, org=None):
		self.url = 'https://api.github.com'
		self.user = user
		self.password = password
		self.org = org

	def getAuth(self):
		base64string = gen_base64(self.user, self.password)
		return	"Basic %s" % base64string
	
	def getOrgRepositories(self):
		url = self.url + '/orgs/%s/repos' % self.org
		r = requests.get(url)
		if r.status_code == requests.codes.ok:
			out = []
			for repo in r.json():
				out.append(repo['full_name'])
			return out
		return None

	def getShortRepositories(self):
		url = self.url + '/orgs/%s/repos' % self.org
		r = requests.get(url)
		if r.status_code == requests.codes.ok:
			out = []
			for repo in r.json():
				out.append(repo['name'])
			return out
		return None

	def commentOnIssue(self, issue_json, comment):
		url = issue_json['comments_url']
		data = { 'body' : comment }
		headers = { "Content-Type": "application/json", 'Authorization' : self.getAuth() }
		r = requests.post(url, headers=headers, data=json.dumps(data))
		j = r.json()
		if 'url' in j:
			return j['url']
		else:
			return None

	def closeIssue(self, issue_json):
		url = issue_json['url']
		data = { 'state' : 'closed' }
		headers = { "Content-Type": "application/json", 'Authorization' : self.getAuth() }
		r = requests.post(url, headers=headers, data=json.dumps(data))
		if r.status_code == requests.codes.ok:
			return r.json()
		return None

class GitHubRepository(GitHub):

	def __init__(self, repo, user, password, org):
		super().__init__(user, password, org)
		self.repo = repo
	
	def getAllPullRequests(self):
		url = self.url + '/repos/%s/pulls' % self.repo
		headers = { 'Authorization' : self.getAuth() }
		r = requests.get(url, headers=headers)
		if r.status_code == requests.codes.ok:
			return r.json()
		return None

	def getAllIssues(self):
		url = self.url + '/repos/%s/issues' % self.repo
		headers = { 'Authorization' : self.getAuth() }
		r = requests.get(url, headers=headers, params={'state' : 'all'})
		if r.status_code == requests.codes.ok:
			return r.json()
		return None

# vim: ts=4 sw=4 noet
