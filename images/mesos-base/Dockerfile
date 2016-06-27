FROM alpine:3.3

ADD ./libmesos-0.28.1.so /usr/lib/libmesos-0.28.1.so
RUN \
  cd /usr/lib && \
  ln -fs libmesos-0.28.1.so libmesos.so

RUN \
  apk add -U curl openjdk8-jre bash cyrus-sasl-dev cyrus-sasl-crammd5 subversion-dev fts-dev libstdc++