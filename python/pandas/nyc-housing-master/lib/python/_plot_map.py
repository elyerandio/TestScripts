import pygmaps
import webbrowser
import urllib
import json
import pandas as pd


def mapquest_url(address):
    params = {
        'inFormat': 'kvp',
        'outFormat': 'json',
        'key': '',
        'callback': 'renderOptions',
        'location': address
    }
    url = 'http://www.mapquestapi.com/geocoding/v1/address?%s' % urllib.urlencode(params)
    return urllib.urlopen(url)


def parse_response(response):
    """
    Fetch latitude and longitude from mapquest (Get's the first one only).
    """
    resp = response.read()[14:-2]
    parsed = json.loads(resp)
    if len(parsed['results'][0]['locations']) >= 1:
        return parsed['results'][0]['locations'][0]['latLng']
    else:
        return {'lat': None,
                'lng': None}


def get_addr(x):
    """
    Get the address
    """
    address = x + ', New York, NY'
    print address
    ad = mapquest_url(address)
    ll = parse_response(ad)
    return str(ll['lat']) + ',' + str(ll['lng'])


def get_lat(x):
    return x.split(',')[0]


def get_lng(x):
    return x.split(',')[1]

if __name__=='__init__':

    df = pd.DataFrame()
    df_sample = df.ix[:, :5]
    df_sample['lat_lng'] = df_sample['address'].apply(get_addr)
    df_sample['lat'] = df_sample['lat_lng'].apply(get_lat)
    df_sample['lng'] = df_sample['lat_lng'].apply(get_lng)

    lats = df_sample['lat']
    lngs = df_sample['lng']

    mymap = pygmaps.maps(40.7142, -74.0064, 14)
    for i in range(0, len(lats)):
        mymap.addpoint(float(lats[i]), float(lngs[i]), "#0000FF")

    mymap.draw('./nyc_housing.html')
    url = './nyc_housing..html'



    mymap.addpoint(37.427, -122.145, "#0000FF")
    mymap.addpoint(37.429, -122.145, "#0000FF")
    mymap.draw('./mymap.draw.html')
    url = './mymap.draw.html'
    webbrowser.open_new_tab(url)
