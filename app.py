from __future__ import print_function
import web
from collections import deque
import json
import os.path
import time

import pymongo
from pymongo import MongoClient

def getNetTop():
    client = MongoClient('localhost', 27017)
    db = client.netTop
    client.close()
    return "dataNetTop"

urls = ('/', 'vis')
render = web.template.render('html/')
app = web.application(urls, globals())
my_form = web.form.Form(
                web.form.Textbox('', class_='textfild', id='textfild'),
                )
 
class vis:
    def GET(self):
        form = my_form()
        return render.vis(form, "Please wait up to 30 seconds for the data stream to collect its first values.")
         
    def POST(self):
        form = my_form()
        form.validates()
        s = form.value['textfield']
        o = form.value['off']
        string = getNetTop()
        return str(string)
 
if __name__ == '__main__':
    app.run()