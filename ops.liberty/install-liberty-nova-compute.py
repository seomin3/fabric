#!/usr/bin/env python
'''
Created on 22 Nov 2015

@author: dh
'''
from utils import envLoader, deployerException
import socket
from components.novaAgt import DepNovaAgt
from components.neutronAgtBridge import DepNeutronAgtBridge
from components.basicConfig import DepBasicConfig

def deployController():
    startmsg()
    # check this node is nova-compute node
    hostname = socket.gethostbyname(socket.gethostname())
    env = envLoader.JunoEnvLoader().loadEnvJson(hostname, 'nova-compute');
    
    # deploy components
    ctrHostname = env['hacontroller']['ip']
    
    DepBasicConfig().start()
    DepNovaAgt(env,ctrHostname, hostname).start()
    DepNeutronAgtBridge(env).start()

def startmsg():
    print '###################################################'
    print '# starting to install openstack nova-compute service'
    print '###################################################'
    
if __name__ == '__main__':
    deployController()
    