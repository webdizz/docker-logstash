Description:

- Logstash for docker, with redis shipper buffer, ready to run and collect all your base.

Versions:

- Elasticsearch latest (v1.0.1) / with head, paramedic plugin
- Redis latest
- Logstash latest (v1.4)
- Persistent storage optional
- Build on phusion/baseimage \0/

Usage:

- docker run --rm -v /tmp/elasticsearch:/var/lib/elasticsearch -p 2222:22 -p 9200:9200 -p 9300:9300 -p 9292:9292 -p 514:514 -p 514:514/udp cdrocker/logstash /sbin/my_init &
- ssh <dockerhost:2222> root:yoleaux

docker run --rm -e ROOT_PASS="v68y0n82" -p 9222:22 -p 9200:9200 -p 9300:9300 -p 9292:9292 -p 514:514 -p 514:514/udp webdizz/logstash-java8

docker run --name="logstash" -d -v /vagrant:/data -e ROOT_PASS="v68y0n82" -p 9222:22 -p 9200:9200 -p 9300:9300 -p 9292:9292 -p 514:514 -p 514:514/udp webdizz/logstash-java8