# import inhouse method
import os, sys
sys.path.append('./fabric.method')
import env
import deploy, post, get
# import fabric api
from fabric.api import task, run, cd

@task
def testrun():
    run('hostname')
    run('df -h')
    run('ifconfig eth0 | grep inet')
    
@task
def get_etc():
    with cd('/opt'):
        run('tar --exclude=./pki --exclude=./selinux/targeted -cf - ./ | xz -9 -c - > /var/tmp/$(hostname)_etc.tar.xz')
