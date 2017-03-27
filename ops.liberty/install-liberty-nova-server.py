#!/usr/bin/env python
'''
Created on 31 Jan 2015

@author: dh
'''
from utils import envLoader, deployerException
import socket
from components.novaCnt import DepNova
from components.basicConfig import DepBasicConfig

def deployController():
	startmsg()
	# check this node is controller
	hostname = socket.gethostbyname(socket.gethostname())
	env = envLoader.JunoEnvLoader().loadEnvJson(hostname, 'nova');
	if env['type'] != 'nova':
		raise deployerException.DeployerException("This node is not nova server")
	
	# deploy components
	ctrHostname = env['hacontroller']['ip']
	DepBasicConfig().start()
	DepNova(env,ctrHostname).start()

def startmsg():
	print '###################################################'
	print '# starting to install openstack nova service'
	print '###################################################'
	
if __name__ == '__main__':
	deployController()
	
