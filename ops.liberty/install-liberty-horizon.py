#!/usr/bin/env python
'''
Created on 31 Jan 2015

@author: dh
'''
from utils import envLoader, deployerException
import socket
from components.dashboard import DepDashboard
from components.basicConfig import DepBasicConfig

def deployController():
	startmsg()
	# check this node is controller
	hostname = socket.gethostbyname(socket.gethostname())
	env = envLoader.JunoEnvLoader().loadEnvJson(hostname, 'horizon');

	# deploy components
	ctrHostname = env['hacontroller']['ip']
	DepBasicConfig().start()
	DepDashboard(env,ctrHostname).start()

def startmsg():
	print '###################################################'
	print '# starting to install openstack controller Node'
	print '###################################################'
	

if __name__ == '__main__':
	deployController()
	
