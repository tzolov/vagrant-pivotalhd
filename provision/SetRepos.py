__author__ = 'root'

import sys
import socket
import json

from requests.auth import HTTPBasicAuth
import requests


def getRepos():
    print "getRepo" 
    stack_name = sys.argv[1]
    stack_version = sys.argv[2]
    print stack_name + stack_version
    
    # look through repo files and then submit via REST
    hostName = socket.getfqdn()
    headers = {"X-Requested-By": "Heffalump"}
    auth = HTTPBasicAuth('admin', 'admin')
    url = "http://" + hostName + ":8080/api/v1/stacks/" + stack_name + "/versions/" + stack_version + "/operating_systems/redhat6/repositories/"
    print url
    repos = json.loads(requests.get(url, auth=auth).text)["items"]
    for repo in repos:
        url = str(repo["href"])
        repoID = str(repo["Repositories"]["repo_id"])
        if repoID.startswith("PHD") or  repoID.startswith("PADS"):
            if repoID == "PHD-3.0":
                repoID = "PHD-3.0.1.0"
            print url
            payload = "{\"Repositories\": {\"base_url\": \"http://" + hostName + "/" + repoID + "/\" , \"verify_base_url\" :false}}"
            print payload
            test = requests.put(url, auth=auth, headers=headers, data=payload)
            print test
if __name__ == '__main__':
    print "PHD3 Repo Setup"
    getRepos()
