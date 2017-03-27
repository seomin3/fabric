{
	"debug" : "false",
	"mysql" : {
		"ip" : "192.168.122.142"
	},
	"hacontroller" : {
		"ip" : "192.168.122.142"
	},
	"host_type" : {
		"keystone" : "192.168.122.142",
		"glance" : "192.168.122.108",
		"nova" : "192.168.122.108",
		"nova-compute" : "192.168.122.11",
		"neutron" : "192.168.122.108",
		"neutron-agent" : "192.168.122.108",
		"horizon" : "192.168.122.142",
		"cinder" : "192.168.122.108"
	},
	"config" : {
		"credentials" : {
			"database" : {
				"before" : "",
				"after" : "db_pass"
			},
			"mq" : {
				"before" : "mq_pass",
				"after" : "mq_pass"
			},
			"passwd" : {
				"admin" : "admin_pass",
				"glance" : "service_pass",
				"nova" : "service_pass",
				"neutron" : "service_pass",
				"cinder" : "service_pass",
				"swift" : "service_pass"
			},
			"secret" : {
				"admin" : "admin_token",
				"metadata" : "metadata_secret"
			}
		},
		"network" : {
			"ovs" : {
				"flat" : {
					"name" : "br-flat",
					"nics" : ["eth1"]
				},
				"vlan" : {
					"name" : "br-vlan",
					"nics" : ["eth2"]
				}
			}
		},
		"block" : {
			"lv" : "cinder-volume"
		}
	}
}
