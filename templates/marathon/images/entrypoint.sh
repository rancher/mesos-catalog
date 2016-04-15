#!/bin/sh -ex

METADATA_HOST=rancher-metadata.rancher.internal
METADATA_VERSION=2015-12-19
METADATA=$METADATA_HOST/$METADATA_VERSION

ZK_SERVICE=${ZK_SERVICE:-"mesos/zk"}
ZK_MESOS_CHROOT=${ZK_MESOS_CHROOT:-"mesos"}
ZK_MARATHON_CHROOT=${ZK_MARATHON_CHROOT:-"marathon"}

IFS='/' read -ra ZK <<< "$ZK_SERVICE"
containers=$(curl -s $METADATA/stacks/${ZK[0]}/services/${ZK[1]}/containers)
if [ "$containers" == "Not found" ]; then
  echo "A zookeeper ensemble is required, but '$ZK_SERVICE' stack/service was not found."
  sleep 1
  exit 1
fi
for container in $(curl -s $METADATA/stacks/${ZK[0]}/services/${ZK[1]}/containers); do
  IFS='=' read -ra c <<< "$container"
  ip=$(curl -s $METADATA/stacks/${ZK[0]}/services/${ZK[1]}/containers/${c[1]}/primary_ip)
  if [ "$ZK_STR" == "" ]; then
    ZK_STR=zk://$ip:2181
  else
    ZK_STR=$ZK_STR,$ip:2181
  fi
done
export MARATHON_MASTER=${ZK_STR}/${ZK_MESOS_CHROOT}
export MARATHON_ZK=${ZK_STR}/${ZK_MARATHON_CHROOT}

export MARATHON_HOSTNAME=$(curl -s $METADATA/self/container/primary_ip)
export MARATHON_HTTP_ADDRESS=$(curl -s $METADATA/self/container/primary_ip)
# export MARATHON_HTTPS_ADDRESS=

PRINCIPAL=${PRINCIPAL:-root}

if [ -n "$SECRET" ]; then
    export MARATHON_MESOS_AUTHENTICATION_PRINCIPAL=${MARATHON_MESOS_AUTHENTICATION_PRINCIPAL:-$PRINCIPAL}
    touch /tmp/secret
    chmod 600 /tmp/secret
    echo -n "$SECRET" > /tmp/secret
    export MARATHON_MESOS_AUTHENTICATION_SECRET_FILE=/tmp/secret
fi

marathon "$@"
