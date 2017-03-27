'''
Created on 1 Feb 2015

@author: dh
'''

class DeployerException(Exception):
	'''
	classdocs
	'''


	def __init__(self, messsage,errors):
		'''
		Constructor
		'''
		super(ValueError,self).__init(messsage)
		self.errors = errors