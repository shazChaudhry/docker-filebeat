FROM prima/filebeat:5.3.0
COPY ./config /
RUN chmod go-w /filebeat.yml
