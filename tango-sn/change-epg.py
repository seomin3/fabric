#!/usr/bin/env python2
from parser import parser
from keystone import keystoneclient
from nova import novaclient
from neutron import neutronclient

def argparsers():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--project_id")
    args = parser.parse_args()
    return args

def main():
    args = argparsers()

    #csv_file = "C:\media\Dropbox\workspace\TANGO Staging EPG_R3.csv"
    server_file = '/home/sysop/Dropbox/workspace/servers.csv'
    epg_file = '/home/sysop/Dropbox/workspace/epg.csv'

    # read from csv
    csv = parser(csv=server_file, parser_type='server')
    server_list = csv.read()
    csv = parser(csv=epg_file, parser_type='epg')
    epg_list = csv.read()

    # connect to keystone
    keystone = keystoneclient()
    session = keystone.session()

    # connect to neutron
    neutron = neutronclient(session)
    net_list = neutron.get_network()

    # connect to nova
    nova = novaclient(session)
    server_id = nova.get_instance('PTSVPL')
    port_list = nova.get_interface(server_id)

if __name__ == '__main__':
	main()
