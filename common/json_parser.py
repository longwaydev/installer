#!/usr/bin/python

import json
import sys

def open_file(fname):
    json_file = open (fname, 'rb')
    data = json.loads(json_file.read())
    return data

def get_url(fname,i):
    data = open_file(fname)
    counter = 0
    items = dict()
    items["items"] = []
    for p in data["items"]:

        for pp in p['body']['items']:
            if counter == i:
                return p['url'].replace('v8','v19').replace(' ','%20')
            counter = counter + 1
            if counter > i:
                return 'None'

def get_item(fname,i):
    data = open_file(fname)
    counter = 0
    items = dict()
    items["items"] = []
    for p in data["items"]:
        for pp in p['body']['items']:
            if counter == i:
                items["items"].append(pp)
                return json.dumps(items)
            counter = counter + 1
            if counter > i:
                return 'None'

def get_value(fname,i):
    data = open_file(fname)
    counter = 0
    for p in data["items"]:
        for pp in p['body']['items']:
            if counter == i:
                return pp['value']
            counter = counter + 1
            if counter > i:
                return 'None'

def get_value_by_key(fname,key):
    data = open_file(fname)
    for p in data["items"]:
        if p['name'] == key:
                return p['value']

def get_key(fname,i):
    data = open_file(fname)
    counter = 0
    items = dict()
    items["items"] = []
    for p in data["items"]:
        for pp in p['body']['items']:
            if counter == i:
                return pp['name']
            counter = counter + 1
            if counter > i:
                return 'None'

def parse_value(jsonstr, key):
    data = json.loads(jsonstr)
    for item in data['items']:
        if item['name'] == key:
            return item['value']

def get_hostId(jsonstr):
    data = json.loads(jsonstr)
    for item in data['items']:
        return item['hostId']

def get_service_stage(fname, product, version):
    data = open_file(fname)
    for p in data["items"]:
        if p["product"] == product and p["version"] == version:
            # possible stages: AVAILABLE_REMOTELY, DISTRIBUTING
            return p["stage"] + ';' + p["version"]


def get_spark2_stage(fname, version):
    return get_service_stage(fname,"SPARK2", version)

def get_splice_stage(fname, version):
    return get_service_stage(fname,"SPLICEMACHINE", version)

def check_url(fname):
    data = open_file(fname)
    urlset = set()
    for p in data["items"]:
        urlset.add(p['url'])
    print urlset

#check_url('hdfs.json')
