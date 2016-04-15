#!/bin/bash -ex

MASTER_PORT=${MASTER_PORT:-"5050"}
ZK_SESSION_TIMEOUT=${ZK_SESSION_TIMEOUT:-"10secs"}
PRINCIPAL=${PRINCIPAL:-root}

METADATA_HOST=rancher-metadata.rancher.internal
METADATA_VERSION=2015-12-19
METADATA=$METADATA_HOST/$METADATA_VERSION

function metadata {
  echo $(curl -s $METADATA/$1)
}

function zk_service {
  ZK_SERVICE=${ZK_SERVICE:-"mesos/zk"}
  IFS='/' read -ra ZK <<< "$ZK_SERVICE"
  echo $(metadata stacks/${ZK[0]}/services/${ZK[1]}/$1)
}

if [ "$(zk_service containers)" == "Not found" ]; then
  echo "A zookeeper ensemble is required, but '$ZK_SERVICE' was not found."
  sleep 1 && exit 1
fi

function zk_container_primary_ip {
  IFS='=' read -ra c <<< "$1"
  echo $(zk_service containers/${c[1]}/primary_ip)  
}

function zk_string {
  ZK_CHROOT=${ZK_CHROOT:-"/$(metadata self/stack/name)"}
  ZK_STRING=
  for container in $(zk_service containers); do
    ip=$(zk_container_primary_ip $container)
    if [ "$ZK_STRING" == "" ]; then
      ZK_STRING=zk://$ip:2181
    else
      ZK_STRING=$ZK_STRING,$ip:2181
    fi
  done
  echo ${ZK_STRING}/${ZK_CHROOT}
}

export MESOS_ZK=$(zk_string)
export MESOS_IP=$(metadata self/container/primary_ip)
export MESOS_HOSTNAME=$(metadata self/host/agent_ip)

if [ -n "$SECRET" ]; then
    export MESOS_AUTHENTICATE=true
    export MESOS_AUTHENTICATE_SLAVES=true
    touch /tmp/credential
    chmod 600 /tmp/credential
    echo -n "$PRINCIPAL $SECRET" > /tmp/credential
    export MESOS_CREDENTIAL=/tmp/credential
fi

/usr/sbin/mesos-master \
  --zk_session_timeout=${ZK_SESSION_TIMEOUT} \
  --port=${MASTER_PORT} \
  "$@"
