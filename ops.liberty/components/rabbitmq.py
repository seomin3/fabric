'''
Created on 3 Feb 2015

@author: dh
'''
from utils import deployerSystemCall as dSys
class DepRabbitmq(object):

	mqpass = {}
	
	def __init__(self,env):
		self.mqpass['before'] = env['config']['credentials']['mq']['before']
		self.mqpass['after'] = env['config']['credentials']['mq']['after']
		
	def start(self):
		print "starting to install rabbitmq"
		self.__packageInstall()
		self.__config()
		self.__initialSetup()
		
	def __packageInstall(self):
		mysqlPkgs = ['rabbitmq-server']
		dSys.DeployerBash().packageInstall(mysqlPkgs)
	
	def __config(self):
		pass

	def __initialSetup(self):
		cmd = ['echo','"[rabbitmq_management]."','>','/etc/rabbitmq/enabled_plugins']
		dSys.DeployerBash().runBash(cmd)
		dSys.DeployerBash().serviceControl('enable', 'rabbitmq-server.service')
		dSys.DeployerBash().serviceControl('restart', 'rabbitmq-server.service')
		cmd = ['curl','http://localhost:15672/cli/rabbitmqadmin','-o','/root/rabbitmqadmin.py']
		dSys.DeployerBash().runBash(cmd)	
		cmd = ['chmod','700','/root/rabbitmqadmin.py']
		dSys.DeployerBash().runBash(cmd)
		dSys.DeployerBash().configSed('password = guest','password = mq_pass','/root/rabbitmqadmin.py')
		dSys.DeployerBash().configSed('"password"        : "guest"','"password"        : "mq_pass"','/root/rabbitmqadmin.py')
		
		rbArgs = ['change_password','guest',self.mqpass['after']]
		dSys.DeployerBash().rabbitmqCtl(rbArgs)
		
		dSys.DeployerBash().firewallSetup('5672')
		