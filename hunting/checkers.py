import requests
import json
import socket


def check_virustotal(exe_hash,api_key):
    """ checks the hash in virustotal and returns the results"""
    url = "https://www.virustotal.com/vtapi/v2/file/report"
    parameters = {"resource":exe_hash, "apikey":api_key}
    vt_res=requests.get(url, params=parameters)
    if vt_res.status_code in [200,201]:
            return json.loads(vt_res.text)
    else:
            print vt_res.status_code, vt_res.text
            return False

def check_cymru(exe_hash):
    """ checks the hash against the team cymru registry using DNS"""

    url=exe_hash+'.malware.hash.cymru.com'
    try:
        cres=socket.gethostbyname(url)
        if cres=='127.0.0.2':
                    return True
    except socket.gaierror:
        return False
    except:
        print "something went wrong whilst trying to check with Team Cymru"
        raise
        return False