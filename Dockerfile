FROM docker.elastic.co/beats/filebeat:6.0.0

COPY config/filebeat.yml /usr/share/filebeat
USER root
RUN chown filebeat /usr/share/filebeat/filebeat.yml && chmod go-w /usr/share/filebeat/filebeat.yml
USER filebeat
