'''
Created on 1 Feb 2015

@author: dh
'''
import json
import os
import re

class JunoEnvLoader(object):
	'''
	classdocs
	'''
	hostType = [
		'rabbitmq',
		'keystone',
		'glance',
		'nova',
		'nova-compute',
		'neutron',
		'neutron-agent',
		'horizon'
	]

	def __init__(self):
		'''
		Constructor
		'''
		pass
	
	def __locadFile(self):
		pDir = os.path.dirname(__file__)
		fileDir = pDir + "/../environments.js"
		f = open(fileDir)
		js = json.load(f)
		f.close()
		if js['debug'] == 'true':
			print "\nloaded json: ", js
		return js
	
	def loadEnvJson(self,hostname, os_module):
		env = self.__locadFile()
		nodeType = ''
		print 'hostname: %s, module: %s' % (hostname, os_module) 
		try:
			if hostname == env['host_type'][os_module]:
				nodeType = os_module
			if nodeType not in self.hostType:
				raise ValueError('host_type is wrong')
			if nodeType == '':
				raise ValueError('cannot find hostname on environments.js')
		except:
			raise ValueError("Wrong json structure")
		else:
			print "found this node on environments.js, nodetype is : " + nodeType
			env['type'] = nodeType
			if env['debug'] == 'true':
				print "\nfinal enviroments.js", env
		return env
		
# 	def setHostsFile(self,hostname):
# 		f = open('/etc/hosts','wb+')
# 		s = f.read()
# 		r = re.findall('\s*'+hostname+'\s*',s)
# 		if not r:
# 			r 
		
