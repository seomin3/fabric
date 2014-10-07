from fabric.api import task, run, put
# import inhouse code
import post

@task
def repo():
    post.set_yum(arch = 'cent', reposerver = '203.239.182.189:8888')