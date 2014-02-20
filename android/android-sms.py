"""Send jokes to your loved ones"""


__author__ = 'Hemanth H.M <hemanth.hm@gmail.com>'
__copyright__ = 'Copyright (c) 2010, h3manth.com.'
__license__ = 'Apache License, Version 2.0'

import urllib2
import json
import android

""" URL to fetch a random joke """
JOKES_URL = 'http://api.icndb.com/jokes/random'

""" List of number to which the joke must be messaged """
FRIENDS = ["9620301938","9980633788"]

def getJoke():
    """Returns a Joke ;)"""
    return json.loads(urllib2.urlopen(JOKES_URL).read())['value']['joke'].encode('ascii','ignore')


def sendJoke():
    """ Sends the fetched joke to all your friends listed! """
    joke = getJoke()
    
    print "here"
    
    print joke
    """ Give birth to droid """
    droid = android.Android()
    
    for friend in FRIENDS:
        """droid.smsSend(friend,"Random joke : " + joke)"""
        droid.makeToast(joke)
        
sendJoke()

