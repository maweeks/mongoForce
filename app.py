from __future__ import print_function
import web
from collections import deque
import json
import os.path
import time

from bson import Binary, Code
from bson.json_util import dumps
import pymongo
from pymongo import MongoClient

def getNetTop():
    client = MongoClient('localhost', 27017)
    returnData=[]
    #Get data from MongoDB
    db = client.netTop
    dbRouters = db.routers.find({})
    dbNetworks = db.networks.find({})
    dbVMs = db.vms.find({})
    client.close()

    #Manipulate data for sending
    returnData = '[' + dumps(dbRouters) + ', ' + dumps(dbNetworks) + ', ' + dumps(dbVMs) + ']'
    return returnData

urls = ('/', 'vis')
render = web.template.render('html/')
app = web.application(urls, globals())
my_form = web.form.Form(
                web.form.Textbox('', class_='textfild', id='textfild'),
                )
 
class vis:
    def GET(self):
        form = my_form()
        return render.vis(form, "Wait for your data.")
         
    def POST(self):
        form = my_form()
        form.validates()
        s = form.value['textfield']
        o = form.value['off']
        string = getNetTop()
        return str(string)
 
if __name__ == '__main__':
    app.run()