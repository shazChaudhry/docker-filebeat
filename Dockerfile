FROM prima/filebeat
COPY ./config /
RUN chmod go-w /filebeat.yml
