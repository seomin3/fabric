import urllib3
urllib3.disable_warnings()
from neutronclient.v2_0 import client
from netaddr import IPNetwork as ipaddr
import os
import re
import struct
import socket
import traceback
from log import logassist

class neutronclient(object):
    session = client = ''
    client = ''
    net_list = {}
    net_prefix = net_suffix = ''
    log = logassist()

    def __init__(self, session):
        self.net_prefix = 'TG.'
        self.net_suffix = '.EPG.VM.'
        self.session = session
        self.client = client.Client(session=self.session)

    def _ip2int(self, addr):
        return struct.unpack("!I", socket.inet_aton(str(addr)))[0]

    def _int2ip(self, addr):
        return socket.inet_ntoa(struct.pack("!I", addr))

    def client(self):
        self.client = client.Client(session=self.session)

    def get_network(self):
        self.net_list = {}
        for item in self.client.list_networks()['networks']:
            self.net_list.update({
                str(item['name']): str(item['id'])
            })
        return self.net_list

    def get_id(self, net_tenant, net_name):
        try:
            net_name = "%s%s%s%s" % (
                self.net_prefix, net_tenant, self.net_suffix, net_name
            )
            networks = self.client.list_networks(name=net_name)
            net_id = networks['networks'][0]['id']
            return net_name, net_id
        except IndexError:
            return net_name, False

    def get_extnet_id(self, server_extip):
        server_extip_octet = server_extip.split('.')[0]
        if server_extip_octet == '60':
            return self.get_id('STAG', '60EXT')
        elif server_extip_octet == '150':
            return self.get_id('STAG', '150EXT')
        elif server_extip_octet == '70':
            return self.get_id('STAG', '70EXT')
        elif server_extip_octet == '220':
            return self.get_id('STAG', '220EXT')

    def create_network(self, net_tenant, net_name):
        net_name, net_id = self.get_id(net_tenant=net_tenant, net_name=net_name)
        if net_name not in self.net_list.keys():
            body = { "network": {
                "name": net_name, "provider:network_type": "vxlan",
                "provider:physical_network": "physnet1"
            }}
            #body = { "network": {
            #    "name": net_name, "provider:network_type": "vxlan"
            #}}
            try:
                resp = self.client.create_network(body=body)
                net_id = resp['network'].get('id')
                print("[%s] create, net: %s" %
                    (self.log.get_currenttime(), net_id))
                return net_id
            except:
                print("[%s] REQ: %s" % (self.log.get_currenttime(), body))
                traceback.print_exc()

    def delete_network(self, net_id):
        try:
            self.client.delete_network(net_id)
            print("[%s] del, net: %s" %
                (self.log.get_currenttime(), net_id))
        except:
            traceback.print_exc()
        self.get_network()

    def create_subnet(self, net_id, net_tenant, net_name, sub_cidr,
                    sub_dhcp_start, sub_dhcp_end, sub_gw):
        net_name = "%s%s%s%s" % (
            self.net_prefix, net_tenant, self.net_suffix, net_name
        )
        sub_name = net_name
        sub_netstr = re.match(r"^\d{1,3}\.\d{1,3}\.\d{1,3}\.", sub_cidr).group()
        sub_dhcp = [{
            'start': sub_netstr + sub_dhcp_start,
            'end': sub_netstr + sub_dhcp_end
        }]
        if sub_gw != '':
            sub_gw = sub_netstr + sub_gw
        else:
            sub_network = ipaddr(sub_cidr).network
            sub_gw = self._ip2int(sub_network) + 1
            sub_gw = self._int2ip(sub_gw)
        body = { "subnet": {
            "name": net_name, "network_id": net_id, "cidr": sub_cidr,
            "enable_dhcp": True, "allocation_pools": sub_dhcp,
            "gateway_ip": sub_gw, "ip_version": 4
        }}
        try:
            resp = self.client.create_subnet(body=body)
            sub_id = resp['subnet'].get('id')
            print("[%s] create, sub: %s" % (self.log.get_currenttime(), sub_id))
            return sub_id
        except:
            print("[%s] REQ: %s" % (self.log.get_currenttime(), body))
            traceback.print_exc()

if __name__ == "__main__":
    main()
