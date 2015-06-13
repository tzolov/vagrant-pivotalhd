#!/bin/bash

cp /vagrant/blueprints/$1.json .
curl --user admin:admin -H 'X-Requested-By:ambari' -X POST http://ambari.localdomain:8080/api/v1/blueprints/$1 -d @$1.json

cp /vagrant/blueprints/$1-hostmapping.json .
curl --user admin:admin -H 'X-Requested-By:ambari' -X POST http://ambari.localdomain:8080/api/v1/clusters/phd30cluster1 -d @$1-hostmapping.json
