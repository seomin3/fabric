#!/usr/bin/env python
'''
Created on 31 Jan 2015

@author: dh
'''
from utils import envLoader, deployerException
import socket
from components.rabbitmq import DepRabbitmq
from components.keystone import DepKeystone
from components.basicConfig import DepBasicConfig

def deployController():
	startmsg()
	# check this node is controller
	hostname = socket.gethostbyname(socket.gethostname())
	env = envLoader.JunoEnvLoader().loadEnvJson(hostname, 'keystone');
	if env['type'] != 'keystone':
		raise deployerException.DeployerException("This node is not controller")
	
	# deploy components
	ctrHostname = env['hacontroller']['ip']
	DepBasicConfig().start()
	DepRabbitmq(env).start()
	DepKeystone(env,ctrHostname).start()

def startmsg():
	print '###################################################'
	print '# starting to install openstack keystone service'
	print '###################################################'
	
if __name__ == '__main__':
	deployController()
	
