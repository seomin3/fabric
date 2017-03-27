#!/usr/bin/env python
'''
Created on 31 Jan 2015

@author: dh
'''
from utils import envLoader, deployerException
import socket
from components.glance import DepGlance
from components.basicConfig import DepBasicConfig

def deployController():
	startmsg()
	# check this node is controller
	hostname = socket.gethostbyname(socket.gethostname())
	env = envLoader.JunoEnvLoader().loadEnvJson(hostname, 'glance');
	if env['type'] != 'glance':
		raise deployerException.DeployerException("This node is not glance server")
	
	# deploy components
	ctrHostname = env['hacontroller']['ip']
	DepBasicConfig().start()
	DepGlance(env,ctrHostname).start()

def startmsg():
	print '###################################################'
	print '# starting to install openstack glance service'
	print '###################################################'
	
if __name__ == '__main__':
	deployController()
	
