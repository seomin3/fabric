from fabric.api import task, env
from fabric.colors import magenta, blue

env.hosts = ['glance']
env.user = 'root'
env.password = 'cloud000'
env.timeout = 30
env.command_timeout = 1200
env.warn_only = False
env.colorize_errors = True

'''
try:
    file = open('hosts.txt', 'r')
    for data in file:
        line = data.strip('\n')
        if line.find('#') != 0: env.hosts.append(line)
    file.close()
except IOError as ioerr: print 'no such hosts.txt file: ' + str(ioerr)

nonhost = ''
for i in nonhost.split():
    try: env.hosts.remove(i)
    except ValueError: pass
'''

#@task
def get():
    print("Executing on %s as %s" % (magenta(env.host), blue(env.user)))
