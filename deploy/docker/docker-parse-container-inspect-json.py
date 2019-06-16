#!/usr/bin/python
#
# Python script to get select details from a docker container inspect JSON
#
import json
import sys
import argparse

parser = argparse.ArgumentParser(description='Get artifacts from a Jenkins job.')
parser.add_argument('--get-node-id', dest='getNodeId', required=False, action='store_true', default=False,
                   help='Get the docker node id from json element Config/Labels/com.docker.swarm.node.id')
parser.add_argument('--get-container-id', dest='getContainerId', required=False, action='store_true', default=False,
                   help='Get the docker node id from json element Status/ContainerStatus/ContainerID')

args = parser.parse_args()

jsonObj = json.load(sys.stdin)

if(len(jsonObj) == 0):
	print "ERROR : Invalid JSON"
else:
	if(args.getNodeId):
		value = json.dumps(jsonObj[0]["Config"]["Labels"]["com.docker.swarm.node.id"])
		# Remove any enclosing quotes
		value = value.strip("\"")
		print (value)

	if(args.getContainerId):
		value = json.dumps(jsonObj[0]["Status"]["ContainerStatus"]["ContainerID"])
		# Remove any enclosing quotes
		value = value.strip("\"")
		print (value)
