import urllib3
urllib3.disable_warnings()
from novaclient import client
import os
import traceback
import time
from log import logassist

class novaclient(object):
    session = client = ''
    server_list = {}
    server_port_list = []
    server_ip_list = []
    log = logassist()

    def __init__(self, session):
        self.session = session
        self.client = client.Client('2.1', session=self.session)
        server_list =  {}
        server_port_list = []
        server_ip_list = []

    def get_instance(self):
        for item in self.client.servers.list():
            self.server_list.update({
                str(item.name): str(item.id)
            })
        print("nova -> instance, %s\n" % self.server_list)

    def get_id(self, server):
        if server in self.server_list.keys():
            return self.server_list.get(server)
        else:
            return False

    def get_interface(self, server_id):
        for item in self.client.servers.interface_list(server_id):
            self.server_port_list.append([{server_id: item.port_id}])
            self.server_ip_list.append([{
                item.fixed_ips[0]['ip_address']: item.port_id
            }])

    def attach_interface(self, server_id, net_id, ip_address):
        if server_id == False: return False
        try:
            if ip_address not in self.server_ip_list:
                resp = self.client.servers.interface_attach(
                    server=server_id, net_id=net_id, fixed_ip=ip_address,
                    port_id=False
                )
                print("[%s] attach, server_id: %s, net_id: %s, ip: %s" %
                    (self.log.get_currenttime(), server_id, net_id, ip_address))
                return resp
        except:
            print("[%s] failed attach, server_id: %s, net_id: %s, ip: %s" %
                (self.log.get_currenttime(), server_id, net_id, ip_address))
            traceback.print_exc()
            return False

    def detach_interface(self, server_id):
        if server_id == False: return False
        for item in self.server_port_list:
            port_id = item[0].get(server_id)
            if port_id:
                resp = self.client.servers.interface_detach(
                    server=server_id, port_id=port_id
                )
                print("[%s] detach, server_id: %s, port_id: %s" %
                    (self.log.get_currenttime(), server_id, port_id))

if __name__ == "__main__":
    main()
