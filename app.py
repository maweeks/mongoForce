from __future__ import print_function
import web
from collections import deque
#from kafka.client import *
import json
import os.path
import time

import pymongo
from pymongo import MongoClient

# create a consumer and get the latest values on the given topic.
# Currently limited to getting the latest value (no history)
#def get_vals(topic, offset):
    #off = int(offset)
    #consumer = KafkaClient('10.0.120.137', 9092)
    #if off == 0:
       	#req = OffsetRequest(topic, 0, -1, 1)
    	#offie = consumer.get_offsets(req)[0]
        #print("offie " + str(offie))
        #text = 'nonsense'
        #print("Queue is empty on " + topic + ". Currently at " +  str(off))
    #else:
        #req = FetchRequest(topic, 0, off, 1024*1024)
        #(messages, req) = consumer.get_message_set(req)
        #print(req[2])
        #offie = req[2]
        #print(offie)
        #text = ''
        #if len(messages)>0:
            #for m in messages:
                #text = text + m.payload
        #else:
            #text = 'nonsense'
    #final = str(offie) + '\t' + text
        #print(final)
    #return final
    #return off

def getNetTop():
	client = MongoClient('localhost', 27017)
	db = client.netTop

	routerData = []
	for result_object in db.routers.find({}):
		#print result_object
		routerData.append(result_object)
		result_object['_id']

	networkData = []
	for result_object in db.networks.find({}):
		#print result_object
		networkData.append(result_object)
		result_object['_id']

	vmData = []
	for result_object in db.vms.find({}):
		#print result_object
		vmData.append(result_object)
		result_object['_id']
	client.close()
	dataNetTop = [routerData,networkData,vmData]
	return dataNetTop






 
urls = ('/', 'vis')
render = web.template.render('html/')
app = web.application(urls, globals())
my_form = web.form.Form(
                web.form.Textbox('', class_='textfild', id='textfild'),
                )
 
class vis:#orwell:
    def GET(self):
        form = my_form()
        return render.vis(form, "Please wait up to 30 seconds for the data stream to collect its first values.")
         
    def POST(self):
        form = my_form()
        form.validates()
        #print(form.value)
        s = form.value['textfield']
        o = form.value['off']
        #print(o)
        string = getNetTop() #get_vals(str(s), str(o))
        #print(string)
        return str(string)
 
if __name__ == '__main__':
    app.run()
