# docker-elk

Elasticsearch: 1.7.2
Logstash: 1.5.4
Kibana: 4.1.2

## run elk

	docker run -d —name elk -p 5601:5601 -p 9200:9200 -p 9300:9300 -p 5000:5000/udp robruth/elk
