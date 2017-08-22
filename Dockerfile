FROM docker.elastic.co/beats/filebeat:5.5.1

COPY config/filebeat.yml /usr/share/filebeat
USER root
RUN chown filebeat /usr/share/filebeat/filebeat.yml && chmod go-w /usr/share/filebeat/filebeat.yml
USER filebeat
