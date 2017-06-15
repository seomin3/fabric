#!/usr/bin/env python2
from parser import parser
from keystone import keystoneclient
from nova import novaclient
from neutron import neutronclient

def argparsers():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--project_id")
    parser.add_argument("--create_network", action="store_true")
    parser.add_argument("--delete_network", action="store_true")
    parser.add_argument("--attach_interface", action="store_true")
    parser.add_argument("--detach_interface", action="store_true")
    args = parser.parse_args()
    return args

def main():
    args = argparsers()

    #csv_file = "C:\media\Dropbox\workspace\TANGO Staging EPG_R3.csv"
    server_file = 'servers.csv'
    epg_file = 'epg.csv'

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

    # create network of tango
    if args.create_network:
        for item in epg_list:
            net_id = neutron.create_network(net_tenant=item[1], net_name=item[2])
            neutron.create_subnet(
                net_id=net_id, net_tenant=item[1],
                net_name=item[2], sub_cidr=item[0],
                sub_dhcp_start=item[3], sub_dhcp_end=item[4],
                sub_gw=item[5]
            )
        print("neutron -> %s" % neutron.get_network())

    # with debug
    if args.delete_network:
        for item in epg_list:
            net_name, net_id = neutron.get_id(
                net_tenant=item[1], net_name=item[2]
            )
            if net_id: neutron.delete_network(net_id)

    # connect to nova
    nova = novaclient(session)
    nova.get_instance()

    for item in server_list:
        server_id = nova.get_id(item[1])
        if server_id:
            nova.get_interface(server_id=server_id)
        else:
            continue

        # attach interface of tango
        if args.attach_interface:
            net_name, net_id = neutron.get_id(item[0], item[2])
            if server_id and not net_id:
                print("* invalid, data: %s server_id: %s, net_id: %s" %
                    (item, server_id, net_id)
                )

            # 90 network
            nova.attach_interface(
                server_id=server_id, net_id=str(net_id), ip_address=item[3]
            )

            # external network
            ext_ip = (item[idx] for idx in range(4, 8) if item[idx] != '')
            for server_extip in ext_ip:
                ext_name, extnet_id = neutron.get_extnet_id(server_extip=server_extip)
                resp = nova.attach_interface(
                    server_id=server_id, net_id=extnet_id, ip_address=server_extip
                )
                if resp == False: break

        # with debug
        if args.detach_interface:
            nova.detach_interface(server_id)

if __name__ == '__main__':
	main()
