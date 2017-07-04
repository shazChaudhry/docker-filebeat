FROM debian

ARG FILEBEAT_VERSION=5.x

RUN set -x && \
  apt-get update && \
  apt-get install -y wget gnupg && \
  wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add - && \
  apt-get install -y apt-transport-https && \
  echo "deb https://artifacts.elastic.co/packages/${FILEBEAT_VERSION}/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-${FILEBEAT_VERSION}.list && \
  apt-get update && apt-get install -y filebeat

COPY config/filebeat.yml /etc/filebeat
RUN chmod go-w /etc/filebeat/filebeat.yml

ENTRYPOINT [ "/usr/share/filebeat/bin/filebeat" ]
CMD [ "-e", "-setup", "-path.config", "/etc/filebeat", "-path.data", "/var/lib/filebeat", "-path.logs", "/var/log/filebeat" ]
