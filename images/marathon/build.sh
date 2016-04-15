#!/bin/bash

docker build -t llparse/marathon:0.11.0-centos-7 .
docker push llparse/marathon:0.11.0-centos-7
