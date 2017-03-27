'''
Created on 31 Jan 2015

@author: dh
'''
from utils import deployerSystemCall as dSys
import pexpect
import time

class DepMysql(object):
	
	dbpass = {}
	
	def __init__(self,env):
		self.dbpass['before'] = env['config']['credentials']['database']['before']
		self.dbpass['after'] = env['config']['credentials']['database']['after']
		
	def start(self):
		print "starting to install mysql"
		self.__packageInstall()
		self.__config()
		self.__initialSetup()
		
	def __packageInstall(self):
		mysqlPkgs = ['mariadb','mariadb-server','MySQL-python']
		dSys.DeployerBash().packageInstall(mysqlPkgs)
	
	def __config(self):
		conf = '\[mysqld\]\\n'
		conf += 'default-storage-engine=innodb\\n'
		conf += 'collation-server=utf8_general_ci\\n'
		conf += 'init-connect=\'SET NAMES utf8\'\\n'
		conf += 'character-set-server=utf8\\n\\n'
		conf += 'datadir'
		dSys.DeployerBash().configSed('\[mysqld\]\\ndatadir', conf, '/etc/my.cnf')
		
	def __initialSetup(self):
		dSys.DeployerBash().serviceControl('enable', 'mariadb.service')
		dSys.DeployerBash().serviceControl('restart', 'mariadb.service')

		child = pexpect.spawn('mysql_secure_installation')
		child.expect('.*current password for.*')
		child.sendline(self.dbpass['before'])
		child.expect('.*root password?.*')
		child.sendline('y')
		child.expect('.*New password.*')
		child.sendline(self.dbpass['after'])
		child.expect('.*Re-enter new password.*')
		child.sendline(self.dbpass['after'])
		child.expect('.*Remove anonymous users.*')
		child.sendline('n')
		child.expect('.*Disallow root login remotely.*')
		child.sendline('n')
		child.expect('.*Remove test database and access to it.*')
		child.sendline('n')
		child.expect('.*Reload privilege tables now.*')
		child.sendline('Y')
		
		print child.before
		
		dSys.DeployerBash().firewallSetup('3306')
		
		wTime = 10 
		print "Waiting for mysql_secure_installation to finish"
		time.sleep(wTime)
		
		
		