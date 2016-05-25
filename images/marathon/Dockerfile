FROM rancher/mesos-base:latest

ARG RELEASE=1.1.1
RUN \
  curl -L http://downloads.mesosphere.com/marathon/v$RELEASE/marathon-$RELEASE.tgz | tar xzf - && \
  mv marathon-$RELEASE/target/scala-2.11/marathon-assembly-$RELEASE.jar /marathon.jar && \
  rm -rf marathon-$RELEASE

ENV RELEASE ${RELEASE:-1.1.1}

ADD entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
