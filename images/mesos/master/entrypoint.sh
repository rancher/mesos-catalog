#!/bin/bash -ex

METADATA_HOST=rancher-metadata.rancher.internal
METADATA_VERSION=2015-12-19
METADATA=$METADATA_HOST/$METADATA_VERSION

ZK_SERVICE=${ZK_SERVICE:-"mesos/zk"}
ZK_CHROOT=${ZK_CHROOT:-"mesos"}
ZK_SESSION_TIMEOUT=${ZK_SESSION_TIMEOUT:-"10secs"}

# Resolve MESOS_ZK from metadata
IFS='/' read -ra ZK <<< "$ZK_SERVICE"
containers=$(curl -s $METADATA/stacks/${ZK[0]}/services/${ZK[1]}/containers)
if [ "$containers" == "Not found" ]; then
  echo "A zookeeper ensemble is required, but '$MESOS_ZK' stack/service was not found."
  sleep 1
  exit 1
fi
for container in $(curl -s $METADATA/stacks/${ZK[0]}/services/${ZK[1]}/containers); do
  IFS='=' read -ra c <<< "$container"
  ip=$(curl -s $METADATA/stacks/${ZK[0]}/services/${ZK[1]}/containers/${c[1]}/primary_ip)
  if [ "$MESOS_ZK" == "" ]; then
    MESOS_ZK=zk://$ip:2181
  else
    MESOS_ZK=$MESOS_ZK,$ip:2181
  fi
done
export MESOS_ZK=${MESOS_ZK}/${ZK_CHROOT}
export MESOS_IP=$(curl -s $METADATA/self/container/primary_ip)
export MESOS_HOSTNAME=$(curl -s $METADATA/self/host/agent_ip)

PRINCIPAL=${PRINCIPAL:-root}

if [ -n "$SECRET" ]; then
    export MESOS_AUTHENTICATE=true
    export MESOS_AUTHENTICATE_SLAVES=true
    touch /tmp/credential
    chmod 600 /tmp/credential
    echo -n "$PRINCIPAL $SECRET" > /tmp/credential
    export MESOS_CREDENTIAL=/tmp/credential
fi

sleep 1
/usr/sbin/mesos-master \
  --zk_session_timeout=${ZK_SESSION_TIMEOUT} \
  "$@"
