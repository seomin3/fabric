from fabric.api import task, env
from fabric.colors import magenta, blue

env.hosts = ['glance']
env.user = 'root'
env.password = 'cloud000'
env.timeout = 30
env.command_timeout = 1200
env.warn_only = False
env.colorize_errors = True

#@task
def get():
    print("Executing on %s as %s" % (magenta(env.host), blue(env.user)))
