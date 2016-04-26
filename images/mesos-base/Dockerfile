FROM ubuntu:14.04

RUN \
  apt-key adv --keyserver keyserver.ubuntu.com --recv 86F44E2A && \
  echo deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu trusty main > /etc/apt/sources.list.d/openjdk-r.list && \
  apt-get update && \
  apt-get -y install openjdk-8-jdk-headless && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN \
  apt-key adv --keyserver keyserver.ubuntu.com --recv E56151BF && \
  echo deb http://repos.mesosphere.io/ubuntu trusty main > /etc/apt/sources.list.d/mesosphere.list && \
  apt-get update && \
  apt-get -y install mesos=0.28.1-2.0.20.ubuntu1404 curl && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
