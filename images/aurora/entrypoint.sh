#!/bin/bash -ex
###############################################################################
METADATA_HOST=rancher-metadata.rancher.internal
METADATA_VERSION=2015-12-19
METADATA=$METADATA_HOST/$METADATA_VERSION
function metadata { echo $(curl -s $METADATA/$1); }
###############################################################################

# network hack
cp /etc/hosts /etc/hosts.tmp
umount /etc/hosts
sed -i "s/.*$(hostname)/$(metadata self/container/primary_ip)\t$(hostname)/g" /etc/hosts.tmp
cp /etc/hosts.tmp /etc/hosts

ZK_SERVICE=${ZK_SERVICE:-"mesos/zk"}
MESOS_SERVICE=${MESOS_SERVICE:="mesos/mesos"}

function zk_service {
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

function zk_hosts {
  ZK_STRING=
  for container in $(zk_service containers); do
    ip=$(zk_container_primary_ip $container)
    if [ "$ZK_STRING" == "" ]; then
      ZK_STRING=$ip:2181
    else
      ZK_STRING=$ZK_STRING,$ip:2181
    fi
  done
  echo ${ZK_STRING}
}

function mesos_stack {
  IFS='/' read -ra X <<< "$MESOS_SERVICE"
  echo ${X[0]}
}

function zk_string {
  echo zk://$(zk_hosts)/$(mesos_stack)
}

# thermos-observer
#exec /aurora/dist/thermos_observer.pex \
#  --port=1338 \
#  --log_to_disk=NONE \
#  --log_to_stderr=google:INFO \
#  >/tmp/thermos_observer-console.log 2>&1 &

# aurora-scheduler
#GLOG_v=0
#LIBPROCESS_PORT=8083
#LIBPROCESS_IP=$ZK_HOST
DIST_DIR=/aurora/dist

# export these so they appear in /vars
export AURORA_CLUSTER_NAME=${AURORA_CLUSTER_NAME:-$(metadata self/stack/name)}
export AURORA_HOSTNAME=${AURORA_HOSTNAME:-$(metadata self/host/agent_ip)}
export AURORA_HTTP_PORT=${AURORA_HTTP_PORT:-8080}
export AURORA_NATIVE_LOG_QUORUM_SIZE=${AURORA_NATIVE_LOG_QUORUM_SIZE:-1}
export AURORA_ZK_ENDPOINTS=${AURORA_ZK_ENDPOINTS:-$(zk_hosts)}
export AURORA_MESOS_MASTER_ADDRESS=${AURORA_MESOS_MASTER_ADDRESS:-$(zk_string)}
export AURORA_SERVERSET_PATH=${AURORA_SERVERSET_PATH:-'/aurora/scheduler'}
export AURORA_NATIVE_LOG_ZK_GROUP_PATH=${AURORA_NATIVE_LOG_ZK_GROUP_PATH:-'/aurora/replicated-log'}
export AURORA_NATIVE_LOG_FILE_PATH=${AURORA_NATIVE_LOG_FILE_PATH:-'/var/db/aurora'}
export AURORA_BACKUP_DIR=${AURORA_BACKUP_DIR:-'/var/lib/aurora/backups'}
export AURORA_THERMOS_EXECUTOR_PATH=${AURORA_THERMOS_EXECUTOR_PATH:-"$DIST_DIR/thermos_executor.pex"}
export AURORA_ALLOWED_CONTAINER_TYPES=${AURORA_ALLOWED_CONTAINER_TYPES:-'MESOS,DOCKER'}
export AURORA_GLOBAL_CONTAINER_MOUNTS=${AURORA_GLOBAL_CONTAINER_MOUNTS:-'/opt:/opt:rw'}
export AURORA_USE_BETA_DB_TASK_STORE=${AURORA_USE_BETA_DB_TASK_STORE:-true}
export AURORA_ENABLE_H2_CONSOLE=${AURORA_ENABLE_H2_CONSOLE:-true}
export AURORA_RECEIVE_REVOCABLE_RESOURCES=${AURORA_RECEIVE_REVOCABLE_RESOURCES:-true}

# Initialize replicated log
mesos-log initialize --path="$AURORA_NATIVE_LOG_FILE_PATH"

CMD="$DIST_DIR/install/aurora-scheduler/bin/aurora-scheduler"

# Parse environment variables
for k in `set | grep ^AURORA_ | cut -d= -f1`; do
    eval v=\$$k
    CMD="$CMD -`echo $k | cut -d_ -f2- | tr '[:upper:]' '[:lower:]'`=$v"
done

exec $CMD -thermos_executor_flags="--announcer-enable --announcer-ensemble $(zk_hosts)"
