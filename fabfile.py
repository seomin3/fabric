# import inhouse method
import os, sys
sys.path.append('./fabric.method')
# import inhouse method
import env
import add, deploy, env, get, post, set
# import fabric api
from fabric.api import task, run, cd

@task
def testrun():
    run('hostname')
    run('df -h')
    run('ifconfig eth0 | grep inet')
