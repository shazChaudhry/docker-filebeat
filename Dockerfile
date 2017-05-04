FROM debian

RUN set -x && \
  apt-get update && \
  apt-get install -y wget && \
  wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add - && \
  apt-get install -y apt-transport-https && \
  echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-5.x.list && \
  apt-get update && apt-get install -y filebeat

COPY config/filebeat.yml /etc/filebeat
RUN chmod go-w /etc/filebeat/filebeat.yml

ENTRYPOINT [ "/usr/share/filebeat/bin/filebeat" ]
CMD [ "-e", "-setup", "-path.config", "/etc/filebeat", "-path.data", "/var/lib/filebeat", "-path.logs", "/var/log/filebeat" ]
