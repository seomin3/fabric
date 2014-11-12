import os
from fabric.api import task, env
from fabric.colors import magenta, blue

'''
# Variables
'''
# Set env.hosts
hosttype = 'file'
hostfile = 'hostfile.swift'
env.hosts = ['']
# Set fabric env
env.user = 'sysop'
env.password = 'pass!!'
env.timeout = 30
env.command_timeout = 1200
env.warn_only = False
env.colorize_errors = True

'''
# Main
'''
if hosttype == 'file':
    env.hosts = []
    try:
        file = open('./docs/%s' % hostfile, 'r')
        for data in file:
            line = data.strip('\n')
            if line.find('#') != 0: env.hosts.append(line)
        file.close()
    except IOError as ioerr: print 'IOError: ' + str(ioerr)

    # remove fault server
    for i in env.hosts:
        try:
            response = os.system("ping -c1 -w1 %s > /dev/null" % i)
            if response != 0:
                print "remove - %s" % i
                env.hosts.remove(i)
        except ValueError: print 'ValueError: ' + str(valueerr)
'''
hostlist = 'dcos-glance-storage'
for i in hostlist.split():
    try: env.hosts.remove(i)
    except ValueError: pass
'''
def get():
    print("Executing on %s as %s" % (magenta(env.host), blue(env.user)))
