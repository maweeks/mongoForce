import pymongo
from pymongo import MongoClient

#Get number of router, network and vms
invalidValue = True;
while invalidValue:
	try:
		invalidValue = False
		numberOfRouters = int(raw_input("How many routers: "))
	except ValueError:
		invalidValue = True
		print "Please use a positive integer..."
		continue

invalidValue = True;
while invalidValue:
	try:
		invalidValue = False
		numberOfNetworksPerRouter = int(raw_input("How many networkds per router: "))
	except ValueError:
		invalidValue = True
		print "Please use a positive integer..."
		continue

invalidValue = True;
while invalidValue:
	try:
		invalidValue = False
		numberOfVMsPerNetwork = int(raw_input("How many vms per network: "))
	except ValueError:
		invalidValue = True
		print "Please use a positive integer..."
		continue

print numberOfRouters
print numberOfNetworksPerRouter
print numberOfVMsPerNetwork

client = MongoClient('localhost', 27017)

#Select db
db = client.netTop

#Clear all collections in the netTop database
routerCollection = db.routers
routerCollection.remove()
networkCollection = db.networks
networkCollection.remove()
vmsCollection = db.vms
vmsCollection.remove()

#Insert new data into netTop database
for x in range(0, numberOfRouters):
	routerCollection.insert( { "name": ("router" + str(x)), "status": "active" } )
	for y in range(0, numberOfNetworksPerRouter):
		networkCollection.insert( { "cidr": ("13.157." + str((x*numberOfNetworksPerRouter)+y+20) + ".0/24"), "name": ("network" + str((numberOfRouters*numberOfNetworksPerRouter)-1)), "router": ("router" + str(x)), "status": "active" })
		for z in range(0, numberOfVMsPerNetwork):
			vmsCollection.insert({"createdOn" : "2014-02-28", "floatingIP" : "172.24.4.218", "imageName" : "cirros-0.3.1-x86_64-uec", "ipAddress" : {("network" + str((x*numberOfNetworksPerRouter)+y)) : ("86.146." + str((x*numberOfNetworksPerRouter)+y+10) + '.' + str(z+5)) }, "name": ("vm" + str((((x*numberOfNetworksPerRouter)+y)*numberOfVMsPerNetwork)+z)) , "status" : "active"})

print("Router: ")
for result_object in db.routers.find({}):
    print result_object
    result_object['_id']

print("Network: ")
for result_object in db.networks.find({}):
    print result_object
    result_object['_id']

print("VMS: ")
for result_object in db.vms.find({}):
    print result_object
    result_object['_id']

client.close()
