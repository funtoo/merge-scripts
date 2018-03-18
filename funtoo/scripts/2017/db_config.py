#!/usr/bin/python3

import os
import configparser

def get_app_config():
	config = configparser.ConfigParser()
	config.read(os.path.expanduser("~/.merge"))
	return config

# vim: ts=4 sw=4 noet
