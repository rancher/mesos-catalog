FROM centos:7

RUN \
  rpm -i http://repos.mesosphere.io/el/7/noarch/RPMS/mesosphere-el-repo-7-1.noarch.rpm && \
  yum -y install marathon-0.11.0 mesos-0.24.1

# Ubuntu path
# RUN locale-gen en_US.UTF-8
# RUN apt-key adv --keyserver keyserver.ubuntu.com --recv E56151BF && \
# echo deb http://repos.mesosphere.io/ubuntu trusty main > /etc/apt/sources.list.d/mesosphere.list && \
# apt-get update && \
# apt-get -y install marathon=0.11.0-1.0.425.ubuntu1404 mesos=0.24.1-0.2.35.ubuntu1404

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
