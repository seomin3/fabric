'''
Created on 1 Feb 2015

@author: dh
'''
import subprocess

class DeployerBash(object):
	evr = {};
	
	def __init__(self,evr={}):
		self.evr = evr
	
	def runBash(self,cmd):
		print 'start to run bash: ', cmd
		argEnv = None
		if self.evr:
			argEnv = self.evr
		proc = subprocess.Popen(cmd,env=argEnv,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
		(stdout, stderr) = proc.communicate()
		if stderr:
			print '----------------- [stderr]: ----------------- \n', stderr
		else:
			print '----------------- [stdout]: ----------------- \n', stdout 
	
	def runSh(self,cmd):
		print 'start to run shell: ', cmd
		p = subprocess.Popen(cmd,env=self.evr,stdout=subprocess.PIPE,shell=True)
		rs = p.communicate()[0]
		print 'shell result: ', rs 
		return rs
		
	def packageInstall(self,packagesArray):
		#TODO: find a way to use yum api directly
		if(len(packagesArray) < 1 ):
			raise ValueError('No package names are provided.') 
		yumArgs = ['yum','install', '-y']
		yumArgs += packagesArray
		self.runBash(yumArgs);
	
	def configSet(self,configArray,fileDir):
		#TODO: find a way to change from spawning process to crudini lib 
		crudiniArgs = ['crudini','--set', fileDir]
		crudiniArgs += configArray
		self.runBash(crudiniArgs)
	
	def serviceControl(self,action,name):
		serviceArgs = ['systemctl',action,name]
		self.runBash(serviceArgs)
		self.runBash(['systemctl','status',name])
		
	def configSed(self,beforeStr,afterStr,filePath,option=':a;N;$!ba;'):
		sedArgs = ['sed','-i',option+'s/'+beforeStr+'/' + afterStr + '/g',filePath]
		self.runBash(sedArgs)
			
	def firewallSetup(self,port):
		portArr = []
		if(type(port) is str):
			portArr.append(port)
		else:
			portArr += port
		for p in portArr:
			fwArgs = ['firewall-cmd','--zone=public','--add-port='+p+'/tcp','--permanent']
			self.runBash(fwArgs)
		fwArgs = ['firewall-cmd','--reload']
		self.runBash(fwArgs)
		
	def rabbitmqCtl(self,args):
		rbArgs = ['rabbitmqctl']
		rbArgs += args
		self.runBash(rbArgs)
	
	def createOpstDb(self,compType,dbpass,dbhost):
		crtSql = "CREATE DATABASE "+compType+";"
		crtSql += "GRANT ALL PRIVILEGES ON "+compType+".* TO '"+compType+"'@'localhost' IDENTIFIED BY '"+dbpass+"';"
		crtSql += "GRANT ALL PRIVILEGES ON "+compType+".* TO '"+compType+"'@'%' IDENTIFIED BY '"+dbpass+"';"
		crtSql += "FLUSH PRIVILEGES;"
		dbSql = ['mysql','-uroot','-p'+dbpass, '-h'+dbhost, '-e', crtSql]
		self.runBash(dbSql)
	
	def chownSetup(self,owner,target):
		choCmm = ['chown','-R',owner+':'+owner,target]
		self.runBash(choCmm)
	
	def syncOpstDb(self,compType):
		dbSyncCmm = ''
		if compType == 'neutron':
			dbSyncCmm = 'neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade liberty'
		elif compType == 'nova':
			dbSyncCmm = compType+'-manage db sync' # no under bar: db sync
		else:
			dbSyncCmm = compType+'-manage db_sync' # has under bar: db_sync
		shArgs = ['su','-s','/bin/sh','-c',dbSyncCmm,compType]
		self.runBash(shArgs)
	
	def keystoneTenantCR(self,name,desc):
		#keystone tenant-create --name admin --description "Admin Tenant"
		#openstack project create --domain default --description "Admin Project" admin
		tcrCmm = ['openstack','project create','--domain','default','--description',desc,name]
		self.runBash(tcrCmm)
		
	def keystoneUserCR(self,name,passwd,email):
		#keystone user-create --name admin --pass admin_pass --email admin@mail.con
		ucrCmm = ['openstack','user create','--domain','default','--password',passwd,'--email',email,name]
		self.runBash(ucrCmm)
	
	def keystoneRoleCR(self,name):
		#keystone role-create --name admin
		rcrCmm = ['openstack','role create',name]
		self.runBash(rcrCmm)
	
	def keystoneUserRoleAdd(self,user,tenant,role):
		#keystone user-role-add --user admin --tenant admin --role admin
		urAddCmm = ['openstack','role add','--user',user,'--project',tenant,role]
		self.runBash(urAddCmm)
	
	def keystoneServCR(self,compName,compType,desc):
		#keystone service-create --name keystone --type identity --description "OpenStack Identity"
		srcrCmm = ['openstack','service create','--name',compName,'--description',desc,compType]
		self.runBash(srcrCmm)
	
	def getServiceId(self,compType):
		getServiceCmm = "openstack service list | awk '/ "+compType+" / {print $2}'"
		return self.runSh(getServiceCmm)
	
	def endpointCreate(self,service,hostname,port,apipath):
		endpcrCmm = ['openstack','endpoint create',service,'public','http://'+hostname+':'+port[0]+'/'+apipath]
		self.runBash(endpcrCmm)
		endpcrCmm = ['openstack','endpoint create',service,'internal','http://'+hostname+':'+port[1]+'/'+apipath]
		self.runBash(endpcrCmm)
		endpcrCmm = ['openstack','endpoint create',service,'admin','http://'+hostname+':'+port[2]+'/'+apipath]
		self.runBash(endpcrCmm)

	def configAddIfNot(self,schText,fileDir,addText):
		appendCmm = 'grep -irn "' + schText + '" ' + fileDir + ' || ' + 'echo "' + addText + '" >> ' + fileDir 
		self.runSh(appendCmm)
	
	def sysctlShow(self):
		sysCmm = ['sysctl', '-p']
		self.runBash(sysCmm)
	
	def ovsCntBr(self,cmmType,brName):
		ovsBrCmm = ['ovs-vsctl','--may-exist',cmmType,brName]
		self.runBash(ovsBrCmm)
		
	def ovsCntPort(self,cmmType,brName,portname): 	
		ovsPtCmm = ['ovs-vsctl','--may-exist',cmmType,brName,portname]
		self.runBash(ovsPtCmm)
	
	def pkill(self,processName):
		pkillCmm = ['pkill',processName]
		self.runBash(pkillCmm)
