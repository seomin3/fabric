import urllib3
urllib3.disable_warnings()
from novaclient import client
import os

class novaclient(object):
    session = ''
    client = ''
    vm_list = ''

    def __init__(self, session):
        self.session = session
        self.client = client.Client('2.1', session=self.session)

    def get_instance(self, server):
        if self.vm_list == '': vm_list = self.client.servers.list()
        for item in vm_list:
            if item.name == server: return item.id

    def get_interface(self, server):
        port_list = []
        for item in self.client.servers.interface_list(server):
            port_list.append({
                'id': server,
                'port_id': item.port_id,
                'ip': item.fixed_ips[0]['ip_address']
            })
        return port_list

    def attach_interface(self, server_id, net_id, ip_address):
        resp = self.client.servers.interface_attach(net_id=net_id, fixed_ip=ip_address)
        print(resp)

if __name__ == "__main__":
    main()
