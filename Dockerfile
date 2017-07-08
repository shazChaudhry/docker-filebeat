FROM docker.elastic.co/beats/filebeat:5.5.0

COPY config/filebeat.yml /usr/share/filebeat
USER root
RUN chmod go-w /usr/share/filebeat/filebeat.yml
USER filebeat
