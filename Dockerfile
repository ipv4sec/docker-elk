FROM ubuntu:latest

# Environment variables
ENV ES_VERSION 1.7.2
ENV ES_URL https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-$ES_VERSION.tar.gz
ENV LS_VERSION 1.5.4
ENV LS_URL https://download.elastic.co/logstash/logstash/logstash-$LS_VERSION.tar.gz
ENV KB_VERSION 4.1.2

# Install prerequisites
RUN apt-get update && \
     apt-get install -y software-properties-common python-software-properties curl supervisor tar

# Install Java 8
RUN  sudo add-apt-repository -y ppa:webupd8team/java && \
     sudo apt-get update && \
     echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo debconf-set-selections && \
     sudo apt-get install -y oracle-java8-installer

# Cleaup apt
RUN apt-get clean && \
     rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Elasticsearch
RUN curl -s -L -o - $ES_URL | tar -xz -C /opt \
    && ln -s /opt/elasticsearch-$ES_VERSION /opt/elasticsearch \
    && mkdir /opt/elasticsearch/{data,logs,plugins}
RUN echo cluster.routing.allocation.disk.watermark.low: 1gb >> /opt/elasticsearch/config/elasticsearch.yml
RUN echo cluster.routing.allocation.disk.watermark.high: 500mb >> /opt/elasticsearch/config/elasticsearch.yml 
RUN useradd -U -d /opt/elasticsearch -M -s /usr/bin/bash elasticsearch && \
    chown -R elasticsearch:elasticsearch /opt/elasticsearch-$ES_VERSION

# Install Logstash
RUN curl -s -L -o - $LS_URL | tar -xz -C /opt \
    && ln -s /opt/logstash-$LS_VERSION /opt/logstash
RUN mkdir -p /etc/logstash/conf.d && \
    mkdir -p /var/log/logstash
RUN useradd -U -d /opt/logstash -M -s /usr/bin/bash logstash && \
    chown -R logstash:logstash /opt/logstash-$LS_VERSION /etc/logstash /var/log/logstash
RUN mkdir -p /etc/logstash/conf.d/
ADD logstash/logstash.conf /etc/logstash/conf.d/

# Install Kibana
RUN mkdir -p /opt/kibana
RUN curl -s https://download.elasticsearch.org/kibana/kibana/kibana-$KB_VERSION-linux-x64.tar.gz \
    | tar -C /opt/kibana --strip-components=1 -xzf -
RUN useradd -U -d /opt/kibana -M -s /usr/bin/bash kibana && \
    chown -R kibana:kibana /opt/kibana

# Install ES plugins
RUN /opt/elasticsearch/bin/plugin -i elasticsearch/marvel/latest
RUN /opt/elasticsearch/bin/plugin -i mobz/elasticsearch-head
RUN /opt/elasticsearch/bin/plugin -i royrusso/elasticsearch-HQ

# Expose ports
EXPOSE "5601/tcp" "9200/tcp" "9300/tcp" "5000/udp"

# Supervisord config
ADD supervisor/elk.conf /etc/supervisor/conf.d/

# Run Supervisord
CMD ["/usr/bin/supervisord"]
