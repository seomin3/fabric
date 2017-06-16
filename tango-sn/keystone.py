import urllib3
urllib3.disable_warnings()
from keystoneauth1.identity import v3
from keystoneauth1 import session
from keystoneclient.v3 import client
import os

class keystoneclient(object):
    def __init__(self):
        pass

    def session(self):
        ops_sess = []
        ops_user = os.environ['OS_USERNAME']
        ops_pass = os.environ['OS_PASSWORD']
        ops_auth = os.environ['OS_AUTH_URL']
        ops_cert = os.environ['OS_CACERT']
        #ops_project = os.environ['OS_PROJECT_NAME']
        ops_project = ['DEV', 'STAG']
        ops_domain = os.environ['OS_USER_DOMAIN_NAME']
        ops_project_domain = os.environ['OS_PROJECT_DOMAIN_NAME']


        for tenant in ops_project:
            auth = v3.Password(
                auth_url=ops_auth,
                username=ops_user,
                password=ops_pass,
                project_name=tenant,
                user_domain_name=ops_domain,
                project_domain_name=ops_project_domain
            )
            ops_sess.append(session.Session(auth=auth, verify=''))
            print("keystone -> user: %s, tenant: %s" % (ops_user, tenant))

        return ops_sess[0], ops_sess[1]

if __name__ == "__main__":
    main()
