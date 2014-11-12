# import inhouse method
import os, sys
sys.path.append('./fabric.method')
# import inhouse method
import env
import add, deploy, env, get, post, set, install
# import fabric api
from fabric.api import task, run, cd

@task
def trun():
    run('df -h')
