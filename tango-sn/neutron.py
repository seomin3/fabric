import urllib3
urllib3.disable_warnings()
from neutronclient.v2_0 import client
import os

class neutronclient(object):
    session = ''
    client = ''
    net_list = []

    def __init__(self, session):
        self.session = session
        self.client = client.Client(session=self.session)

    def client(self):
        self.client = client.Client(session=self.session)

    def get_network(self):
        for item in self.client.list_networks()['networks']:
            self.net_list.append({
                str(item['name']): str(item['id'])
            })
        return self.net_list

if __name__ == "__main__":
    main()
