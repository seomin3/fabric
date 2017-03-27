This python project aims to install openstack on virtualbox or physical machines.

# How to use

1. set environment
	- edit environment file to be matched you environment

2. run Install~.py file on each node that has roles like controller, network, compute
	- user should be root (2-6)

3. find out everything is ok on controller node with status checking commands like below
	$nova-manage service list
	   
