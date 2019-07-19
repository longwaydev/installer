#!/usr/bin/python

import json
import sys

def open_file(fname):
    json_file = open (fname, 'rb')
    data = json.loads(json_file.read())
    return data


open_file("log_location.json")
