[![Build Status on Travis](https://travis-ci.org/shazChaudhry/docker-filebeat.svg?branch=master "CI build on Travis")](https://travis-ci.org/shazChaudhry/docker-filebeat)
[![Docker Repository on Quay](https://quay.io/repository/shazchaudhry/docker-filebeat/status "Docker Repository on Quay")](https://quay.io/repository/shazchaudhry/docker-filebeat)

**User story:**<br>
As a member of DevOps team I want to send Jenkins build logs to Elastic stack so that Ops team can diagnose production issues
by analysing all available logs in a central logging system.

**Note:**
* For the purpose of testing filebeat, Docker Swarm enabled [Vagrant](https://github.com/shazChaudhry/infra) environment was created and then [Elastic Stack](https://github.com/shazChaudhry/logging) was installed
* The filebeat image has been tested on Docker 17.06.0-ce

**Assumptions:**
* Jenkins build logs are to be sent to Elasticsearch. However, no logs are written to the host file system where Jenkins is running

**Requirements:**
* Elasticsearch, _(Logstash optional)_ and Kibana are up and running
* Elasticsearch port 9200 is open for filebeat to send logs to
* Both Jenkins and Filebeat are running on the same host

**Lightweight log data shipper for local files:**<br>
If required, edit filebeat configuration as appropriate for your system. However, filebeat behaviour is controlled with environment values in docker run command below. Should you need additional parameters configured then configurations are located at _config/filebeat.yml_.

Start a jenkins container, create some jobs and run some builds. This will create build logs that filebeat will read and then forward them to Elasticsearch:
```
docker run -d --rm --name jenkins --publish 8080:8080 jenkinsci/jenkins
```
_**NOTE:** for this Jenkins containder nothing is mounted from the host file system_

Build filebeat image ensurinig that config/filebeat.yml is configured as appropriate for your system or as requirements:
```
docker build \
  --rm --no-cache \
  --tag shazchaudhry/docker-filebeat .
```
Start filebeat container that will forward Jenkins build logs to Elastic search. In order to persist filebeat state,
mount a hsot directory. Otherwise, following a container crash / restart, filebeat might start reading & forwarding logs
that have already been processed:
```
docker run -d --rm \
  --name filebeat \
  --volume filebeat_data:/usr/share/filebeat/data \
  --volumes-from jenkins:ro \
  --env HOST=node1 \
  --env PORT=9200 \
  --env PROTOCOL=http \
  --env USERNAME=elastic \
  --env PASSWORD=changeme \
shazchaudhry/docker-filebeat
```

If not already available in Kibana, create an index called "filebeat-*" to view Jenkins' build logs.

**Issue:**<br>
If jenkins container is stopped, removed and run again, filebeat will not be able to read jenkins' log files. This is
due to the fact that jenkins container ID would have changed and filebeat would have lost the visibility of log files
inside jenkins' volume.

**Solution**<br>
filebeat has a dependency on jenkins being up and running. So, if jenkins goes down, filebeat has to go down at the same
time and both these services have to be brought up agin; jenkins first and filebeat second
1. Copy all files from the systemd directory in this repo and place them in `/etc/systemd/system` dirctory on the host
file system
2. Stop and remove both jenkins and filebeat containers if they are running
3. Run the following commands: <br>
 `sudo systemctl daemon-reload`<br>
 `sudo systemctl start jenkins.service`<br>
 `sudo systemctl start filebeat.service`<br>
 `docker container ps -a` to check if filebeat and jenkins are up and running. <br>
  `docker container exec -it filebeat ls -latr /var/jenkins_home` to see if jenkins volume is visible from within filebeat's container

**Test**
- Create and run a job in jenkins
- Create an index called `filebeat-*` in Kibana and check the logs in discovery tab


**Filebeat overview, docs and FAQ:**
- https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-overview.html
- https://www.elastic.co/guide/en/beats/filebeat/current/faq.html
