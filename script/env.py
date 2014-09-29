from fabric.api import  env

env.hosts = ['nova01']
env.user = 'root'
env.timeout = 30
env.command_timeout = 1200
env.warn_only = False
env.colorize_errors = True
