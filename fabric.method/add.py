import os
from fabric.api import task, run

@task
def user():
    RET = False
    file = run('cat /etc/sudoers', quiet = True)
    for i in file.split('\n'):
        if 'sysop   ALL=(ALL) NOPASSWD: ALL' in i: RET = True
    run('userdel -r sysop; groupdel sysop', warn_only=True)
    run('groupadd -g 1300 sysop')
    run('useradd -m -u 1300 -g sysop -c kjahyeon@sptek.com sysop')
    if RET == False: run('echo "sysop   ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers')
    run('echo "sysop:b4r7q890!" | chpasswd')
    """
    Thanks to
    https://gist.github.com/btompkins/814870
    """