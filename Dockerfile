# Use phusion/baseimage as base image. To make your builds
# reproducible, make sure you lock down to a specific version, not
# to `latest`! See
# https://github.com/phusion/baseimage-docker/blob/master/Changelog.md
# for a list of version numbers.
FROM phusion/baseimage:0.9.9

MAINTAINER cODAR "me@codar.nl"

# Set correct environment variables.
ENV	HOME /root
ENV	LANG en_US.UTF-8
ENV	LC_ALL en_US.UTF-8
ENV	DEBIAN_FRONTEND	noninteractive

# Versions
ENV     ELASTICSEARCH_VERSION 1.1.1
ENV     LOGSTASH_VERSION 1.4.1
ENV     ELASTICSEARCH_URL https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-${ELASTICSEARCH_VERSION}.deb
ENV     LOGSTASH_URL https://download.elasticsearch.org/logstash/logstash/logstash-${LOGSTASH_VERSION}.tar.gz

# set sane locale
RUN	locale-gen en_US.UTF-8

# Use baseimage-docker's init system.

# Regenerate SSH host keys. baseimage-docker does not contain any, so you
# have to do that yourself. You may also comment out this instruction; the
# init system will auto-generate one during boot.
# RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

# prep apt-get
RUN	sed 's/main$/main universe/' -i /etc/apt/sources.list
RUN	echo "root:123456" | chpasswd

#RUN	DEBIAN_FRONTEND=noninteractive \
RUN apt-get -y update \
	&& apt-get -y install software-properties-common python-software-properties \
	&& add-apt-repository -y ppa:chris-lea/redis-server \
	&& apt-get -y update \
	&& apt-get -y upgrade \
	&& apt-get -y install redis-server wget mc tcpdump

RUN add-apt-repository ppa:webupd8team/java
RUN apt-get update
RUN apt-get -y upgrade

RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections
RUN apt-get -y install oracle-java8-installer
RUN apt-get clean
RUN update-alternatives --display java 
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle

# elasticsearch
RUN	cd /tmp \
	&& wget $ELASTICSEARCH_URL \
	&& dpkg -i /tmp/elasticsearch-${ELASTICSEARCH_VERSION}.deb \
	&& /usr/share/elasticsearch/bin/plugin -install karmi/elasticsearch-paramedic \
	&& /usr/share/elasticsearch/bin/plugin -install mobz/elasticsearch-head \
	&& echo "cluster.name: logstash" >> /etc/elasticsearch/elasticsearch.yml

# logstash
RUN	cd /tmp \
	&& wget https://download.elasticsearch.org/logstash/logstash/logstash-${LOGSTASH_VERSION}.tar.gz \
	&& mkdir /apps \
	&& cd /apps \
	&& tar zxf /tmp/logstash-${LOGSTASH_VERSION}.tar.gz \
	&& ln -s logstash-${LOGSTASH_VERSION} logstash \
	&& mkdir /etc/logstash

# services
RUN mkdir /etc/service/redis-server \
	&& mkdir /etc/service/logstash-web \
	&& mkdir -p /opt/services/

# services run files
ADD	redis-server.sh /etc/service/redis-server/run
ADD	elasticsearch.sh /opt/services/elasticsearch.sh
ADD	logstash-shipper.sh /opt/services/logstash-shipper.sh
ADD	logstash-indexer.sh /opt/services/logstash-indexer.sh
ADD	logstash-web.sh /etc/service/logstash-web/run

# config
ADD	shipper.conf /etc/logstash/shipper.conf
ADD	indexer.conf /etc/logstash/indexer.conf

# Supervisor
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install supervisor openssh-server pwgen

#SSH support
RUN mkdir -p /var/run/sshd && sed -i "s/UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config && sed -i "s/UsePAM.*/UsePAM no/g" /etc/ssh/sshd_config && sed -i "s/PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config
ADD /supervisor/supervisord-sshd.conf /etc/supervisor/conf.d/supervisord-sshd.conf
ADD /supervisor/supervisord-elasticsearch.conf /etc/supervisor/conf.d/supervisord-elasticsearch.conf
ADD /supervisor/supervisord-logstash-indexer.conf /etc/supervisor/conf.d/supervisord-logstash-indexer.conf
ADD /supervisor/supervisord-logstash-shipper.conf /etc/supervisor/conf.d/supervisord-logstash-shipper.conf
ADD set_root_pw.sh /set_root_pw.sh
ADD run.sh /run.sh
RUN chmod +x /*.sh

EXPOSE 22
EXPOSE 9200
EXPOSE 9300
EXPOSE 9292
EXPOSE 514

CMD ["/run.sh"]

# Clean up APT when done.
RUN	apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

