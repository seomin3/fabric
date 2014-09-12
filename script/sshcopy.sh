#!/bin/bash

function def_set_ssh() {
/usr/bin/expect << _EOF_
	set timeout -1
	spawn sudo ssh-copy-id -o StrictHostKeyChecking=no -i $SSH_PUB_KEY $REMOTE_HOST_USER@$REMOTE_HOST
	expect -nocase "password" 
	send -- "$REMOTE_PASS\r"
	expect eof
_EOF_
}

function dep_print_error() {
	echo "Usage: $(basename $0) REMOTE_HOST_NAME REMOTE_HOST_PASSWORD"
	exit 1
}

[ ! $(rpm -qa | grep expect) ] && echo 'installing expect' && sudo yum -y -q install expect

# check remote host
if [ -n "$1" ]
then
	REMOTE_HOST=$1
else
	dep_print_error
fi
[ $(ping -c1 -w1 $REMOTE_HOST > /dev/null) ] && echo "connecting to remote server failed " && exit 1

# check remote password
if [ -n "$2" ]
then
	REMOTE_PASS=$2
else
	dep_print_error
fi

# deploy ssh key for root
SSH_PUB_KEY='/root/.ssh/id_rsa.pub'
REMOTE_HOST_USER='root'
def_set_ssh

# create account to remote server
sudo ssh -o StrictHostKeyChecking=no $REMOTE_HOST_USER@$REMOTE_HOST "useradd -m sysop"
sudo ssh -o StrictHostKeyChecking=no $REMOTE_HOST_USER@$REMOTE_HOST "echo $REMOTE_PASS | passwd sysop --stdin"

# deploy ssh key for sysop
SSH_PUB_KEY='/home/sysop/.ssh/id_rsa.pub'
REMOTE_HOST_USER='sysop'
def_set_ssh
REMOTE_HOST_USER='root'
def_set_ssh