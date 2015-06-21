__author__ = 'root'

import socket
import json

from requests.auth import HTTPBasicAuth
import requests


def getRepos():
    print "getRepo"
    # look through repo files and then submit via REST
    hostName = socket.getfqdn()
    headers = {"X-Requested-By": "Heffalump"}
    auth = HTTPBasicAuth('admin', 'admin')
    url = "http://" + hostName + ":8080/api/v1/stacks/PHD/versions/3.0/operating_systems/redhat6/repositories/"
    print url
    repos = json.loads(requests.get(url, auth=auth).text)["items"]
    for repo in repos:
        url = str(repo["href"])
        repoID = str(repo["Repositories"]["repo_id"])
        if repoID != "Spring-XD-1.2":
            if repoID == "PHD-3.0":
                repoID = "PHD-3.0.0.0"
            payload = "{\"Repositories\": {\"base_url\": \"http://" + hostName + "/" + repoID + "/\" , \"verify_base_url\" :false}}"
            print payload
            test = requests.put(url, auth=auth, headers=headers, data=payload)
            print test
if __name__ == '__main__':
    print "PHD3 Repo Setup"
    getRepos()
