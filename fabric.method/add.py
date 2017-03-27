import os
from fabric.api import task, run, sudo

@task
def user():
    RET = False
    USER_NAME = 'user'
    USER_PASS = 'pass!!'
    USER_ID = '1501'
    file = sudo('cat /etc/sudoers', quiet = True)
    for i in file.split('\n'):
        if '%s   ALL=(ALL) ALL' % USER_NAME in i: RET = True
    #sudo('userdel -r %s' % (USER_NAME), warn_only=True)
    sudo('groupadd -g %s %s' % (USER_ID, USER_NAME))
    sudo('useradd -m -u %s -g %s %s' % (USER_ID, USER_NAME, USER_NAME))
    if RET == False: sudo('echo "%s   ALL=(ALL) ALL" >> /etc/sudoers' % USER_NAME)
    sudo('echo "%s:%s" | chpasswd' % (USER_NAME,USER_PASS))

    """
    Thanks to
    https://gist.github.com/btompkins/814870
    """
