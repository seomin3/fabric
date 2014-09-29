from fabric.api import task, put, cd, run

def go(basename):
    put('/opt/git/openstack/sandbox/*', '/opt/')
    with cd('/opt'):
        run('pwd')
        run('chmod 744 *sh')
        run(basename)
@task
def hypervisor():
    go('./install_hypervisor.sh')

@task    
def horizon():
    go('./install_horizon.sh')

@task    
def glance():
    go('./install_glance.sh')

@task    
def keystone():
    go('./install_keystone.sh')

@task
def testrun():
    run('df -h')